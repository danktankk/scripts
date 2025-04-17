#!/bin/bash

# Mount NTFS drives
ntfs-3g -o defaults,noatime,rw,uid=1000,gid=1000 /dev/disk/by-id/nvme-eui.002538b411506388-part2 /mnt/win11-OS
ntfs-3g -o defaults,noatime,rw,uid=1000,gid=1000 /dev/disk/by-id/ata-Hitachi_HUA723030ALA640_MK0371YVHPPL8A-part1 /mnt/stg1-3tb
ntfs-3g -o defaults,noatime,rw,uid=1000,gid=1000 /dev/disk/by-id/ata-Hitachi_HUA723030ALA640_MK0371YVHN7XHA-part1 /mnt/stg2-3tb
ntfs-3g -o defaults,noatime,rw,uid=1000,gid=1000 /dev/disk/by-id/ata-TOSHIBA_HDWE160_78T8K0AGFB8G-part2 /mnt/stg-6tb-audio

#optional add sleep time
sleep 5

# Mount ext4 drive by-uuid
mount UUID=ceaf2764-d2db-446b-8b7c-b769f0e0dc70 /mnt/stg-6tb-data -t ext4 -o defaults,noatime,rw
mount UUID=dc52203a-2c5a-4d0d-b18e-0ef7fe1d6b9b /mnt/pop-os-data -t ext4 -o defaults,noatime,rw

# Change ownership
chown -R dankk:dankk /mnt/stg-6tb-data
chown -R dankk:dankk /mnt/pop-os-data
