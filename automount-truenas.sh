#!/bin/bash

# Set the log file path
log_file="/home/dankk/scripts/scripts.log"

# Redirect all output to the log file
exec > >(tee -a "$log_file") 2>&1

# Function to log and flush output
log_and_flush() {
    echo "$1"
    sync
}

# Set variables for the iSCSI target and mount point
target="/dev/disk/by-id/scsi-36589cfc0000005c4396bf256e82d0db3-part1"
mount_point="/media/dankk/truenas-iscsi"

# Create the mount point directory if it doesn't exist
if [ ! -d "$mount_point" ]; then
    sudo mkdir "$mount_point"
fi

# Login to iSCSI target with timeout
if timeout 20 sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:truenas-iscsi --portal 192.168.160.50 --login; then
    log_and_flush "iSCSI target login successful"
else
    log_and_flush "iSCSI target login failed"
    exit 1
fi

# Mount the iSCSI target to the mount point
sudo mount -t ext4 "$target" "$mount_point"

# Verify that the mount was successful
if [ $? -eq 0 ]; then
    log_and_flush "iSCSI target mounted successfully to $mount_point"
else
    log_and_flush "Failed to mount iSCSI target"
fi

# NFS Share
nfs_truenas_ip="192.168.160.50"
nfs_share="/mnt/zpool/deddspace-nas"
nfs_mount_point="/media/dankk/truenas-nfs"
nfs_options="rw,noatime,rsize=131072,wsize=131072,hard,intr,timeo=150,retrans=3"

# SMB Share
smb_share="//192.168.160.50/deddspace-nas"
smb_mount_point="/media/dankk/truenas-smb"
smb_options="vers=3.0,credentials=/home/dankk/.smbcreds,iocharset=utf8,uid=1000,gid=1000,noperm"

# Function to mount a share
mount_share() {
    share_type=$1
    share=$2
    mount_point=$3
    options=$4

    # Check if the mount point already exists
    if [ ! -d "$mount_point" ]; then
        log_and_flush "Creating mount point directory for $share_type..."
        sudo mkdir -p "$mount_point"
    fi

    # Mount the share
    echo "Mounting $share_type share..."
    sudo mount -t $share_type -o "$options" "$share" "$mount_point"

    # Check if the mount was successful
    if [ $? -eq 0 ]; then
        log_and_flush "$share_type share mounted successfully!"
    else
        log_and_flush "Failed to mount $share_type share."
    fi
}

# Mount NFS share
mount_share "nfs" "$nfs_truenas_ip:$nfs_share" "$nfs_mount_point" "$nfs_options"

# Mount SMB share
mount_share "cifs" "$smb_share" "$smb_mount_point" "$smb_options"
