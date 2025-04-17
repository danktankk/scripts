#!/bin/bash
 
#--DEFINE VARIABLES--#
 
# Containers to backup and their appdata paths
list=(
    
    crowdsec                 /mnt/cache/appdata/crowdsec
    Docker-WebUI             /mnt/cache/appdata/Docker-WebUI
    code-server              /mnt/cache/appdata/code-server
    booksonic-air            /mnt/cache/appdata/booksonic-air
    autobrr                  /mnt/cache/appdata/autobrr
    authelia2                /mnt/cache/appdata/Authelia2
    authelia                 /mnt/cache/appdata/Authelia
    Mealie                   /mnt/cache/appdata/mealie
    cross-seed               /mnt/cache/appdata/cross-seed    
    deemix                   /mnt/cache/appdata/deemix
    prowlarr                 /mnt/cache/appdata/prowlarr
    Tailscale                /mnt/cache/appdata/tailscale   
    heimdall                 /mnt/cache/appdata/heimdall 
    xbackbone                /mnt/cache/appdata/xbackbone
    speedtest-tracker        /mnt/cache/appdata/speedtest-tracker
    Unraid-API               /mnt/cache/appdata/Unraid-API
    scrutiny                 /mnt/cache/appdata/scrutiny
    ApacheGuacamole          /mnt/cache/appdata/ApacheGuacamole  
    swag                     /mnt/cache/appdata/swag
    syncthing                /mnt/cache/appdata/syncthing
    qbittorrent-vpn          /mnt/cache/appdata/qbittorrent-vpn
    qbitmanage               /mnt/cache/appdata/qbitmanage
    binhex-krusader          /mnt/cache/appdata/binhex-krusader
    nextcloud                /mnt/cache_aux/appdata_aux/nextcloud
    nextcloud                /mnt/cache/appdata/nextcloud
    booksonic-air            /mnt/cache/appdata/booksonic-air
    mariadb                  /mnt/cache/appdata/mariadb
    telegraf                 /mnt/cache/appdata/telegraf
    cloudflare-ddns          /mnt/cache/appdata/cloudflare-ddns
    cloudflared              /mnt/cache/appdata/cloudflared
    filebrowser              /mnt/cache/appdata/filebrowser
    grafana                  /mnt/cache/appdata/grafana
    bitwardenrs              /mnt/cache/appdata/bitwarden
    tautulli                 /mnt/cache/appdata/tautulli
    notifiarr                /mnt/cache/appdata/notifiarr
    radarr                   /mnt/cache/appdata/radarr
    radarr-4k                /mnt/cache/appdata/radarr-4k
    radarr-3d                /mnt/cache/appdata/radarr-3d
    sonarr                   /mnt/cache/appdata/sonarr
    sonarr-4k                /mnt/cache/appdata/sonarr-4k
    lidarr                   /mnt/cache/appdata/lidarr
    bazarr                   /mnt/cache/appdata/bazarr
    jackett                  /mnt/cache/appdata/jackett
    unpackerr                /mnt/cache/appdata/unpackerr
    petio                    /mnt/cache/appdata/petio
    proxmox backup server    /mnt/cache/appdata/pbs
 #   rdesktop                 /mnt/cache/appdata/rdesktop
    Unraid-API               /mnt/cache/appdata/Unraid-API
 #   trackarr                 /mnt/cache/appdata/trackarr
 #   organizrv2               /mnt/cache/appdata/organizrv2
 #   ombi                     /mnt/cache/appdata/ombi
 #   UniFi-Poller             /mnt/cache/appdata/UniFi-Poller
 #   HDDTemp                  /mnt/cache/appdata/HDDTemp
 #   cadvisor                 /mnt/cache/appdata/cadvisor
 #   netdata                  /mnt/cache/appdata/netdata
 #   DiskSpeed                /mnt/cache/appdata/DiskSpeed
 #   HandBrake                /mnt/cache/appdata/HandBrake
    prometheus               /mnt/cache/appdata/prometheus
 #   Influxdb                 /mnt/cache/appdata/influxdb
 #   unifi-video              /mnt/cache/appdata/unifi-video
 #   monocle-gateway          /mnt/cache/appdata/monocle
 #   Varken                   /mnt/cache/appdata/Varken
 #   plex                     /mnt/plex_appdata/plex
 #   Overseerr                /mnt/cache/appdata/overseerr
 #   OnlyOfficeDocumentServer /mnt/cache/appdata/onlyofficeds
)
 
# Set Backup Directory
backupDirectory='/mnt/disks/Backup_Disk_1/Backup/Daily/Appdata/Individual/'
 
# Set Number of Days to Keep Backups
days=30
 
#--START SCRIPT--#
/usr/local/emhttp/plugins/dynamix/scripts/notify -s "AppData Backup" -d "Backup of all individual appdata containers starting."
 
now="$(date +"%Y-%m-%d"@%H.%M)"
 
mkdir ""$backupDirectory""$now""
 
for (( i = 0; i < ${#list[@]}; i += 2 ))
do
    name=${list[i]} path=${list[i+1]}
 
    cRunning="$(docker ps -a --format '{{.Names}}' -f status=running)"
 
    if echo $cRunning | grep -iqF $name; then
    echo "Stopping $name"
        docker stop -t 60 "$name"
        cd ""$backupDirectory""$now""
        tar cWfC "./$name.tar" "$(dirname "$path")" "$(basename "$path")"
    echo "Starting $name"
        docker start "$name"
    else
        cd ""$backupDirectory""$now""
        tar cWfC "./$name.tar" "$(dirname "$path")" "$(basename "$path")"
    echo "$name was stopped before backup, ignoring startup"
    fi
 
done
 
#Cleanup Old Backups
find "$backupDirectory"* -type d -mtime +"$days" -exec rm -rf {} +
 
#Stop Notification
/usr/local/emhttp/plugins/dynamix/scripts/notify -s "AppData Backup" -d "Backup of selected appdata containers complete."
