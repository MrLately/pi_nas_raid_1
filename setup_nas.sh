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

echo "Starting NAS setup..."
sleep 2 # Gives a small pause for user to read the message

# Update and Upgrade Raspberry Pi OS
echo "Updating and upgrading Raspberry Pi OS..."
apt-get update && apt-get upgrade -y

# Install mdadm for RAID management
echo "Installing mdadm for RAID management..."
apt-get install mdadm -y

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

echo "Selected drives: $FIRST_DEVICE and $SECOND_DEVICE."

# Ensure no partitions on the selected drives are mounted
for device in $FIRST_DEVICE $SECOND_DEVICE; do
    if mount | grep -q $device; then
        echo "Unmounting $device ..."
        umount $device* || { echo "Failed to unmount $device. Exiting."; exit 1; }
    fi
    # Clear any existing RAID signatures
    mdadm --zero-superblock --force $device || { echo "Failed to clear RAID superblock on $device. Exiting."; exit 1; }
done

echo "WARNING: This will erase all data on these drives and create a RAID 1 array."
echo "Do you want to proceed? (y/n)"
read -r confirm
if [ "$confirm" != "y" ]; then
    echo "Operation cancelled by the user."
    exit 1
fi

# Create the RAID 1 array
echo "Creating RAID 1 array..."
if mdadm --create --verbose $RAID_DEVICE --level=1 --raid-devices=2 $FIRST_DEVICE $SECOND_DEVICE; then
    echo "RAID 1 array created successfully."
else
    echo "Failed to create RAID 1 array. Exiting."
    exit 1
fi

sleep 2

# Create filesystem on RAID array
echo "Formatting the RAID array to Ext4..."
mkfs.ext4 $RAID_DEVICE

echo "Creating mount point at $MOUNT_POINT..."
mkdir -p $MOUNT_POINT
UUID=$(blkid -o value -s UUID $RAID_DEVICE)
echo "UUID=$UUID $MOUNT_POINT ext4 defaults,auto,users,rw,nofail 0 0" >> /etc/fstab && mount -a

echo "Setting correct ownership and permissions for the NAS directory..."
chown -R $USER_NAME:$GROUP_NAME $MOUNT_POINT
chmod -R 775 $MOUNT_POINT

# Install Samba for file sharing
echo "Installing Samba..."
apt-get install samba samba-common-bin -y

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

echo "Restarting Samba..."
systemctl restart smbd

RPI_IP=$(hostname -I | awk '{print $1}')
echo "NAS setup with RAID 1 and Samba configuration completed successfully."
echo "Raspberry Pi IP Address: $RPI_IP"
echo "You can now access your NAS at smb://$RPI_IP/$SHARE_NAME from any device on your network."
echo "Setup is complete. Enjoy your new NAS!"







