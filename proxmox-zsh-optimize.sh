#!/usr/bin/env bash
set -euo pipefail

#################################################################
# GLOBAL VARIABLES & COLOR DEFINITIONS
#################################################################
LOGFILE="/var/log/zfs_optimize.log"
DATE_FMT='+%Y-%m-%d %H:%M:%S'

# ANSI color codes
ORANGE="\e[1;38;5;208m"   # Bold orange for headings (256-color)
BLUE="\e[34m"             # Blue for banner
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Status symbols: use the exact ASCII characters you requested:
CHECK="✅"
CROSS="❌"
# We'll display ephemeral as not optimized (red X)
EPH="N/A"

# Arrays
declare -A DS_TYPE       # VM or LXC (keyed by VMID)
declare -A DS_NAME       # Human-readable name (keyed by VMID)
declare -A DS_DATASETS   # Comma-separated list of datasets for each VMID
declare -A DS_STATUS     # Overall status for each VMID

#################################################################
# HELPER FUNCTIONS
#################################################################

get_zfs_prop() {
  local ds="$1" prop="$2"
  zfs get -H -o value "$prop" "$ds" 2>/dev/null || echo "unknown"
}

parse_id_from_dataset() {
  local ds="$1"
  local id
  # Match subvol-<ID>-disk- or vm-<ID>-disk-
  id=$(echo "$ds" | sed -n 's/.*subvol-\([0-9]\+\)-disk-.*/\1/p; s/.*vm-\([0-9]\+\)-disk-.*/\1/p')
  [[ -z "$id" ]] && echo "unknown" || echo "$id"
}

detect_type() {
  local ds="$1"
  if [[ "$ds" == *subvol* ]]; then
    echo "LXC"
  elif [[ "$ds" == *vm-* ]]; then
    echo "VM"
  else
    echo "unknown"
  fi
}

get_config_name() {
  local vmid="$1" vtype="$2" foundName=""
  if [[ "$vtype" == "VM" ]]; then
    local conf="/etc/pve/qemu-server/${vmid}.conf"
    if [[ -f "$conf" ]]; then
      foundName="$(grep -E '^name:\s*' "$conf" | head -n1 | awk -F': ' '{print $2}' | xargs || true)"
    fi
  elif [[ "$vtype" == "LXC" ]]; then
    local conf="/etc/pve/lxc/${vmid}.conf"
    if [[ -f "$conf" ]]; then
      foundName="$(grep -E '^hostname:\s*' "$conf" | head -n1 | awk -F': ' '{print $2}' | xargs || true)"
    fi
  fi
  [[ -z "$foundName" ]] && foundName="(no-name-found)"
  echo "$foundName"
}

is_ephemeral() {
  local ds="$1"
  [[ "$ds" =~ (cloudinit|efidisk|tpm|tpmstate) ]] && echo "true" || echo "false"
}

check_dataset_optim() {
  local ds="$1" ctype="$2"
  # If the dataset is ephemeral, return red X
  if [[ "$(is_ephemeral "$ds")" == "true" ]]; then
    echo "$EPH"
    return
  fi

  local comp sync atime
  comp="$(get_zfs_prop "$ds" compression)"
  sync="$(get_zfs_prop "$ds" sync)"
  atime="$(get_zfs_prop "$ds" atime)"

  # For both VM and LXC, compression should be zstd
  [[ "$comp" != "zstd" ]] && { echo "$CROSS"; return; }

  # For LXC, atime=off and sync=disabled are required
  if [[ "$ctype" == "LXC" ]]; then
    [[ "$atime" != "off" || "$sync" != "disabled" ]] && { echo "$CROSS"; return; }
  fi

  echo "$CHECK"
}

#################################################################
# BUILD ARRAYS & DETERMINE STATUS
#################################################################

rebuild_arrays() {
  DS_TYPE=(); DS_NAME=(); DS_DATASETS=(); DS_STATUS=()

  local -a allDatasets
  mapfile -t allDatasets < <(zfs list -o name -H -t filesystem,volume | grep -E 'subvol|vm-')

  for ds in "${allDatasets[@]}"; do
    local vid
    vid="$(parse_id_from_dataset "$ds")"
    [[ "$vid" == "unknown" ]] && continue

    if [[ -z "${DS_TYPE[$vid]+x}" ]]; then
      DS_TYPE["$vid"]="$(detect_type "$ds")"
      DS_NAME["$vid"]="$(get_config_name "$vid" "${DS_TYPE[$vid]}")"
      DS_DATASETS["$vid"]="$ds"
    else
      DS_DATASETS["$vid"]+=",${ds}"
    fi
  done

  for vid in "${!DS_TYPE[@]}"; do
    local ctype="${DS_TYPE[$vid]}"
    IFS=',' read -ra dsArr <<< "${DS_DATASETS[$vid]}"
    local finalStatus="$CHECK"
    local allEph=true
    for d in "${dsArr[@]}"; do
      local st
      st="$(check_dataset_optim "$d" "$ctype")"
      if [[ "$st" == "$CROSS" ]]; then
        finalStatus="$CROSS"
        allEph=false
        break
      fi
      if [[ "$st" != "$EPH" ]]; then
        allEph=false
      fi
    done
    [[ "$allEph" == "true" ]] && finalStatus="$EPH"
    DS_STATUS["$vid"]="$finalStatus"
  done
}

#################################################################
# PRINT THE TABLE (NO SCROLLING/PAGING, CLEAR SCREEN FIRST)
#################################################################

print_list() {
  clear

  # Top banner in blue (80 characters wide)
  echo -e "${BLUE}##<--################################################################################${RESET}"
  echo -e "${BLUE}##              ----[ ZFS Optimization Tool (All Datasets) ]-----                  ##${RESET}"
  echo -e "${BLUE}################################################################################-->##${RESET}"
  echo

  # Header row in bold orange: columns for index (3 char), name (20 char), datasets (50 char), status (5 char)
  printf "%b%-3s  %-20s  %-50s  %5s%b\n" "$ORANGE" "Idx" "Name" "Datasets" "Stat" "$RESET"
  printf "%b%-3s  %-20s  %-50s  %5s%b\n" "$ORANGE" "---" "--------------------" "--------------------------------------------------" "-----" "$RESET"
  echo

  # Build a sorted list of VMIDs (numeric sort)
  local -a sortedVids
  for v in "${!DS_TYPE[@]}"; do
    sortedVids+=( "$v" )
  done
  IFS=$'\n' sortedVids=($(sort -n <<<"${sortedVids[*]}"))
  unset IFS

  local idx=1
  local rowDivider="--------------------------------------------------------------------------------"
  for vid in "${sortedVids[@]}"; do
    local nm="${DS_NAME[$vid]}"
    local ds="${DS_DATASETS[$vid]}"
    local st="${DS_STATUS[$vid]}"

    # Trim values if too long
    local shortName shortDS
    shortName="$(echo "$nm" | cut -c1-20)"
    shortDS="$(echo "$ds" | cut -c1-50)"
    (( ${#ds} > 50 )) && shortDS+="..."

    # Print each row with the index in bold orange
    printf "%b%-3s%b  %-20s  %-50s  %5s\n" "$ORANGE" "$idx" "$RESET" "$shortName" "$shortDS" "$st"
    echo "$rowDivider"
    ((idx++))
  done

  echo
  echo "Type 'all' to optimize all, comma-separated indices to pick multiple,"
  echo "'quit' to exit, or a single index to optimize individually."
  echo
}

#################################################################
# APPLY RECOMMENDED OPTIMIZATIONS
#################################################################

apply_recommended() {
  local ds="$1" ctype="$2"
  local now
  now="$(date "$DATE_FMT")"

  if [[ "$(is_ephemeral "$ds")" == "true" ]]; then
    echo "- $ds is ephemeral, skipping."
    echo "[$now] $ds => ephemeral, skipping changes" >> "$LOGFILE"
    return
  fi

  local stat
  stat="$(check_dataset_optim "$ds" "$ctype")"
  if [[ "$stat" == "$CHECK" ]]; then
    echo "- $ds is already optimized."
    echo "[$now] $ds => Already optimized" >> "$LOGFILE"
    return
  fi

  local curComp curSync curAtime
  curComp="$(get_zfs_prop "$ds" compression)"
  curSync="$(get_zfs_prop "$ds" sync)"
  curAtime="$(get_zfs_prop "$ds" atime)"

  echo
  echo "Applying optimizations to: $ds"
  echo "[$now] $ds => Updating properties" >> "$LOGFILE"

  if [[ "$curComp" != "zstd" ]]; then
    zfs set compression=zstd "$ds"
    echo "  - compression=zstd (was $curComp)" | tee -a "$LOGFILE"
  fi

  if [[ "$ctype" == "LXC" ]]; then
    if [[ "$curAtime" != "off" ]]; then
      zfs set atime=off "$ds" 2>/dev/null || \
        echo "  - Could not set atime=off (likely a zvol)" | tee -a "$LOGFILE"
    fi
    if [[ "$curSync" != "disabled" ]]; then
      zfs set sync=disabled "$ds"
      echo "  - sync=disabled (was $curSync)" | tee -a "$LOGFILE"
    fi
  else
    echo "  - VM detected: skipping sync=disabled and atime=off" | tee -a "$LOGFILE"
  fi
}

#################################################################
# MAIN LOOP
#################################################################

while true; do
  rebuild_arrays
  print_list
  read -rp "Your choice: " CHOICE
  case "$CHOICE" in
    quit|q)
      echo "Exiting..."
      exit 0
      ;;
    all)
      for vid in "${!DS_TYPE[@]}"; do
        IFS=',' read -ra dsArr <<< "${DS_DATASETS[$vid]}"
        for d in "${dsArr[@]}"; do
          apply_recommended "$d" "${DS_TYPE[$vid]}"
        done
      done
      ;;
    *)
      IFS=',' read -ra picks <<< "$CHOICE"

      # Build sorted VMIDs (without using "local" at top-level)
      sortedVids=()
      for v in "${!DS_TYPE[@]}"; do
        sortedVids+=( "$v" )
      done
      IFS=$'\n' sortedVids=($(sort -n <<<"${sortedVids[*]}"))
      unset IFS

      validVids=()
      for p in "${picks[@]}"; do
        if [[ "$p" =~ ^[0-9]+$ ]]; then
          max="${#sortedVids[@]}"
          if (( p >= 1 && p <= max )); then
            chosenVid="${sortedVids[$((p-1))]}"
            validVids+=( "$chosenVid" )
          fi
        fi
      done

      [[ ${#validVids[@]} -eq 0 ]] && continue

      for vid in "${validVids[@]}"; do
        IFS=',' read -ra dsArr <<< "${DS_DATASETS[$vid]}"
        for d in "${dsArr[@]}"; do
          apply_recommended "$d" "${DS_TYPE[$vid]}"
        done
      done
      ;;
  esac
done
