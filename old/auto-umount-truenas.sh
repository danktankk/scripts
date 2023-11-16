#!/bin/bash

# Set variables for the iSCSI target and mount point
target="/dev/disk/by-id/scsi-36589cfc0000005c4396bf256e82d0db3-part1"
mount_point="/media/dankk/truenas-iscsi"

# Unmount and logout from iSCSI target
sudo umount "$mount_point"
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:truenas-iscsi --portal 192.168.160.50 --logout

# Verify that iSCSI target is logged out
if [ $? -eq 0 ]; then
    echo "iSCSI target logged out successfully"
else
    echo "Failed to log out from iSCSI target"
fi

# Set variables for NFS share #1
nfs_mount_point="/media/dankk/truenas-nfs"

# Unmount NFS share #1
sudo umount "$nfs_mount_point"

# Verify that NFS share #1 is unmounted
if [ $? -eq 0 ]; then
    echo "NFS share #1 unmounted successfully"
else
    echo "Failed to unmount NFS share #1"
fi

# Set variables for NFS share #2
new_nfs_mount_point="/media/dankk/deddcloud"
new_nfs_server="192.168.160.45"
new_nfs_share="/mnt/deddcloud"

# Unmount NFS share #2
sudo umount "$new_nfs_mount_point"

# Verify that NFS share #2 is unmounted
if [ $? -eq 0 ]; then
    echo "NFS share #2 unmounted successfully"
else
    echo "Failed to unmount NFS share #2"
fi

# Set variables for SMB share
smb_mount_point="/media/dankk/truenas-smb"

# Unmount SMB share
sudo umount "$smb_mount_point"

# Verify that SMB share is unmounted
if [ $? -eq 0 ]; then
    echo "SMB share unmounted successfully"
else
    echo "Failed to unmount SMB share"
fi
