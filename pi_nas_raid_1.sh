#!/bin/bash

# Configuration variables
MOUNT_POINT="/mnt/nas"
SHARE_NAME="nas"
USER_NAME="pi" # Default user
GROUP_NAME="pi" # Default group
RAID_DEVICE="/dev/md0" # RAID device name

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Update and Upgrade Raspberry Pi OS
echo "Updating and upgrading Raspberry Pi OS..."
apt-get update && apt-get upgrade -y

# Install mdadm for RAID management
echo "Installing mdadm..."
apt-get install mdadm -y

# Detect and list all connected external drives with their names, sizes, and models
echo "Detecting connected external drives..."
lsblk -o NAME,SIZE,MODEL -dp | grep -v "boot\|root"
echo "Please enter the first device name for RAID 1 (e.g., /dev/sda):"
read -r FIRST_DEVICE
echo "Please enter the second device name for RAID 1 (e.g., /dev/sdb):"
read -r SECOND_DEVICE

if [ -z "$FIRST_DEVICE" ] || [ -z "$SECOND_DEVICE" ]; then
    echo "Two drives must be specified. Exiting."
    exit 1
fi

# Confirmation before proceeding with RAID creation and formatting
echo "You have selected $FIRST_DEVICE and $SECOND_DEVICE for RAID 1."
echo "WARNING: This will erase all data on these drives and create a RAID 1 array."
echo "Do you want to proceed? (y/n)"
read -r confirm
if [ "$confirm" != "y" ]; then
    echo "Operation cancelled."
    exit 1
fi

# Create the RAID 1 array
echo "Creating RAID 1 array..."
mdadm --create --verbose $RAID_DEVICE --level=1 --raid-devices=2 $FIRST_DEVICE $SECOND_DEVICE

# Create filesystem on RAID array
echo "Formatting the RAID array to Ext4..."
mkfs.ext4 $RAID_DEVICE

# Create mount point and update /etc/fstab
echo "Creating mount point at $MOUNT_POINT"
mkdir -p $MOUNT_POINT
UUID=$(blkid -o value -s UUID $RAID_DEVICE)
echo "UUID=$UUID $MOUNT_POINT ext4 defaults,auto,users,rw,nofail 0 0" >> /etc/fstab

# Mount the RAID array
echo "Mounting the RAID array..."
mount -a

# Install Samba for file sharing
echo "Installing Samba..."
apt-get install samba samba-common-bin -y

# Configure Samba Share
echo "Configuring Samba Share named $SHARE_NAME for $MOUNT_POINT..."
cat >> /etc/samba/smb.conf <<EOT

[$SHARE_NAME]
path = $MOUNT_POINT
writeable=Yes
create mask=0777
directory mask=0777
public=yes
browsable=yes
guest ok=yes
force user=$USER_NAME
force group=$GROUP_NAME
EOT

# Restart Samba to apply the configuration
echo "Restarting Samba..."
systemctl restart smbd

echo "NAS setup with RAID 1 and Samba configuration completed."
