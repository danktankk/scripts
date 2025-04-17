#!/bin/bash

# Define the TrueNAS NFS share details
truenas_ip="192.168.160.50"
nfs_share="/mnt/zpool/deddspace-nas"

# Define the mount point in Pop!_OS
mount_point="/media/dankk/truenas-nfs"

# Check if the mount point already exists
if [ ! -d "$mount_point" ]; then
    echo "Creating mount point directory..."
    sudo mkdir -p "$mount_point"
fi

# Mount the TrueNAS NFS share
echo "Mounting TrueNAS NFS share..."
sudo mount -t nfs "$truenas_ip:$nfs_share" "$mount_point"

# Check if the mount was successful
if [ $? -eq 0 ]; then
    echo "TrueNAS NFS share mounted successfully!"
else
    echo "Failed to mount TrueNAS NFS share."
fi
