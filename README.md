# Raspberry Pi NAS Setup with RAID 1 and Samba

This script automates the setup of a Network Attached Storage (NAS) on a Raspberry Pi using RAID 1 for redundancy and Samba for file sharing. It's designed to enhance data reliability by mirroring data across two drives and to provide easy network access to stored files.

## Prerequisites

- A Raspberry Pi running Raspberry Pi OS.
- Two external drives (USB drives or SSDs) for the RAID 1 array.
- Root access (the script must be run as root).

## Features

- **RAID 1 Configuration**: Mirrors data across two drives for redundancy.
- **Samba File Sharing**: Shares the RAID array over the network, making it accessible to Windows, macOS, and Linux clients.

## Setup Instructions

1. **Prepare Your Raspberry Pi**: Ensure your Raspberry Pi OS is installed and your Raspberry Pi has network connectivity.

2. **Connect Your Drives**: Connect the two external drives to your Raspberry Pi. These will be used for the RAID 1 array.

3. **Download the Script**: Clone the script from GitHub to your Raspberry Pi.

   git clone https://github.com/MrLately/setup_nas_raid_1

4. **Make the Script Executable**:

   chmod +x setup_nas.sh

5. **Go to dir**:

   cd setup_nas_raid_1
   
6. **Run the Script**:

   sudo ./setup_nas.sh
   
   Follow the on-screen instructions to select your drives and confirm the setup steps.

## Usage

Once the script completes, your NAS will be accessible over the network via the Samba protocol. You can access the shared folder from any computer on the same network:

- **Windows**: Use the network browser or enter \\RASPBERRY_PI_IP\nas in the File Explorer address bar.
- **macOS**: Connect to a server via Finder using smb://RASPBERRY_PI_IP/nas.
- **Linux**: Access through the file manager or mount the share using the command line.
- **Android**: Open a file manager app that supports SMB, navigate to 'Network' or 'LAN', tap on the '+' or 'Add' button usually found at the top right corner, then select 'Network drive' or 'SMB'. Enter 'smb://RASPBERRY_PI_IP/ninnie' as the server address.
- **iPhone**: Open the Files app, tap on 'Browse' at the bottom, then '...' (More) > 'Connect to Server'. Enter 'smb://RASPBERRY_PI_IP/ninnie' and tap 'Connect'.

  
## Important Notes

- **Data Loss Warning**: The script will format the drives selected for the RAID 1 array, erasing all existing data. Ensure you have backups of any important data before proceeding.
- **Drive Failure**: In case of a drive failure, replace the failed drive with a new one and add it to the RAID array to rebuild the mirror.
- **Customization**: Advanced users can modify the script to change the mount point, share name, or RAID device name as needed. Can password protect as well but this
default setup is for easy access within the home network.






