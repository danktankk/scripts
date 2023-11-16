#!/bin/bash

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
    echo "iSCSI target mounted successfully to $mount_point"
else
    echo "Failed to mount iSCSI target"
fi
