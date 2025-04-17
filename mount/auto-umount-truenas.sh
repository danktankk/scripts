#!/bin/bash

# Set the log file path
log_file="/home/dankk/scripts/scripts.log"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$log_file") 2>&1

# Function to log and flush output
log_and_flush() {
    echo "$1"
    sync
}

# Set variables for the iSCSI target and mount point
target="/dev/disk/by-id/scsi-36589cfc0000005c4396bf256e82d0db3-part1"
mount_point="/media/dankk/truenas-iscsi"

# Unmount and logout from iSCSI target
sudo umount "$mount_point"
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:truenas-iscsi --portal 192.168.160.50 --logout

# Verify that iSCSI target is logged out
if [ $? -eq 0 ]; then
    log_and_flush "iSCSI target logged out successfully"
else
    log_and_flush "Failed to log out from iSCSI target"
fi

# Set variables for NFS share
nfs_mount_point="/media/dankk/truenas-nfs"

# Unmount NFS share
sudo umount "$nfs_mount_point"

# Verify that NFS share is unmounted
if [ $? -eq 0 ]; then
    log_and_flush "NFS share unmounted successfully"
else
    log_and_flush "Failed to unmount NFS share"
fi

# Set variables for SMB share
smb_mount_point="/media/dankk/truenas-smb"

# Unmount SMB share
sudo umount "$smb_mount_point"

# Verify that SMB share is unmounted
if [ $? -eq 0 ]; then
    log_and_flush "SMB share unmounted successfully"
else
    log_and_flush "Failed to unmount SMB share"
fi
