#!/bin/bash

# Define the TrueNAS NFS share details
truenas_ip="192.168.160.50"
nfs_share="/mnt/zpool/deddspace-nas"

# Define the mount point in Pop!_OS
mount_point="/media/dankk/truenas-nfs"

# Unmount the TrueNAS NFS share
echo "Unmounting TrueNAS NFS share..."
sudo umount "$mount_point"

# Check if the unmount was successful
if [ $? -eq 0 ]; then
    echo "TrueNAS NFS share unmounted successfully!"
else
    echo "Failed to unmount TrueNAS NFS share."
fi
