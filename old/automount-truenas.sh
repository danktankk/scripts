#!/bin/bash

######################################################################
#######  THIS SECTION IS FOR iSCSI AND NOT CURRENTLY NEEDED  #########
######################################################################

# Set variables for the iSCSI target and mount point
#target="/dev/disk/by-id/scsi-36589cfc0000005c4396bf256e82d0db3-part1"
#mount_point="/media/dankk/truenas-iscsi"

# Create the mount point directory if it doesn't exist
#if [ ! -d "$mount_point" ]; then
#    sudo mkdir "$mount_point"
#fi

# Login to iSCSI target with timeout
#if timeout 20 sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:truenas-iscsi --portal 192.168.160.50 --login; then
#    echo "iSCSI target login successful"
#else
#    echo "iSCSI target login failed"
#    exit 1
#fi

# Mount the iSCSI target to the mount point
#sudo mount -t ext4 "$target" "$mount_point"

# Verify that the mount was successful
#if [ $? -eq 0 ]; then
#    echo "iSCSI target mounted successfully to $mount_point"
#else
#    echo "Failed to mount iSCSI target"
#fi

######################################################################
#######################  END iSCSI SECTION  ##########################
######################################################################


# NFS Share (from PVE3 - Server IP 192.168.150.30)
nfs_host_ip="192.168.150.30"
nfs_host_share="/mnt/zfs-nfs"
nfs_mount_point="/media/dankk/zfs-nfs"
nfs_options="rw,noatime,rsize=131072,wsize=131072,hard,intr,timeo=150,retrans=3"

# ZFS Replication Share (from Proxmox IP 192.168.150.30)
zfs_host_ip="192.168.150.30"
zfs_host_share="/mnt/zfs-data"
zfs_mount_point="/media/dankk/zfs-data"
zfs_nfs_options="rw,noatime,rsize=131072,wsize=131072,hard,intr,timeo=150,retrans=3"

# NFS Share 3 Seafile? (from PVE1 - server IP 192.168.160.45)
nfs_seafile_ip="192.168.160.45"
nfs_seafile_share="/mnt/deddcloud"
nfs_seafile_mount_point="/media/dankk/deddcloud"
nfs_seafile_options="rw,noatime,rsize=131072,wsize=131072,hard,intr,timeo=150,retrans=3"

# SMB Share
#smb_share="//192.168.160.50/deddspace-nas"
#smb_mount_point="/media/dankk/truenas-smb"
#smb_options="vers=3.0,credentials=/home/dankk/.smbcreds,iocharset=utf8,uid=1000,gid=1000,noperm"

# Function to mount a share
mount_share() {
    share_type=$1
    share=$2
    mount_point=$3
    options=$4

    # Check if the mount point already exists
    if [ ! -d "$mount_point" ]; then
        echo "Creating mount point directory for $share_type..."
        sudo mkdir -p "$mount_point"
    fi

    # Mount the share
    echo "Mounting $share_type share..."
    sudo mount -t $share_type -o "$options" "$share" "$mount_point"

    # Check if the mount was successful
    if [ $? -eq 0 ]; then
        echo "$share_type share mounted successfully!"
    else
        echo "Failed to mount $share_type share."
    fi
}

# Mount NFS share
mount_share "nfs" "$nfs_host_ip:$nfs_host_share" "$nfs_mount_point" "$nfs_options"

# Mount ZFS Replication share
mount_share "nfs" "$zfs_host_ip:$zfs_host_share" "$zfs_mount_point" "$zfs_nfs_options"

# Mount Seafile NFS share 
mount_share "nfs" "$nfs_seafile_ip:$nfs_seafile_share" "$nfs_seafile_mount_point" "$nfs_seafile_options"

# Mount SMB share
#mount_share "cifs" "$smb_share" "$smb_mount_point" "$smb_options"
