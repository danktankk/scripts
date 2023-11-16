#!/bin/bash

# Set variables for the iSCSI target and mount point
target="/dev/disk/by-id/scsi-36589cfc0000005c4396bf256e82d0db3-part1"
mount_point="/media/dankk/truenas-iscsi"

# Unmount the iSCSI target
sudo umount "$mount_point"

# Verify that the unmount was successful
if [ $? -eq 0 ]; then
    echo "iSCSI target successfully unmounted from $mount_point"
else
    echo "Failed to unmount iSCSI target"
    exit 1
fi

# Disconnect from the iSCSI target
sudo iscsiadm -m node --logout

# Verify that the disconnect was successful
if [ $? -eq 0 ]; then
    echo "iSCSI target successfully disconnected"
else
    echo "Failed to disconnect from iSCSI target"
    exit 1
fi
