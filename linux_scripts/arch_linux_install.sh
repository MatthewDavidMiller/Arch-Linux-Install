#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Install script for Arch Linux. Needs linux_scripts.sh and arch_linux_scripts.sh files.

# Log errors
# exec 2>arch_linux_install.sh_errors.txt

# Get needed scripts
wget -O 'install_functions.sh' 'https://raw.githubusercontent.com/MatthewDavidMiller/Arch-Linux-Install/stable/linux_scripts/install_functions.sh'

# Source functions
source install_functions.sh

# Default variables
wifi_response='n'
windows_response='y'
disk='/dev/sda'
windows_efi_partition_number='2'
partition_number1='1'
partition_number2='6'
delete_partitions_response='n'
ucode_response='y'
wifi_interface='wlan0'
ssid='Miller Homelab'
partition_1_size='512M'
partition_2_size='8193M'
root_partition_size='100%FREE'
lvm_name='Archlvm'

# Prompts, uncomment to use

#read -r -p "Connect to a wireless network? [y/N] " wifi_response
# Specify if windows is installed
#read -r -p "Is windows installed? [y/N] " windows_response
# Specify disk and partition numbers to use for install
#read -r -p "Specify disk to use for install. Example '/dev/sda': " disk
#read -r -p "Specify partition number for /boot. If using windows select the partiton where the EFI folder is located. Example '1': " partition_number1
#read -r -p "Specify partition number for lvm. Example '2': " partition_number2
partition1="${disk}${partition_number1}"
partition2="${disk}${partition_number2}"
windows_efi_partition="${disk}${windows_efi_partition_number}"
# Specify whether to delete all partitions
#read -r -p "Do you want to delete all parititions on ${disk}? [y/N] " delete_partitions_response
# Specify if cpu is intel
#read -r -p "Is the cpu intel? [y/N] " ucode_response
# Specify disk encryption password
read -r -p "Set the password for disk encryption: " disk_password

# Call functions
list_partitions
start_dhcpcd

if [[ "${wifi_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    # Prompts, uncomment to use
    #read -r -p "Specify wireless interface name: " wifi_interface
    #read -r -p "Specify SSID name: " ssid
    arch_connect_to_wifi "${wifi_interface}" "${ssid}"
fi

check_for_internet_access
enable_ntp_timedatectl

if [[ "${delete_partitions_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    delete_all_partitions_on_a_disk "${disk}"
fi

get_ucode_type "${ucode_response}"
create_basic_partitions "${partition_1_size}" "${partition_2_size}"
create_luks_partition "${disk_password}" "${partition2}"
create_basic_lvm "${partition2}" '/tmp/disk_password' "${lvm_name}" "${root_partition_size}"

if [[ "${windows_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    create_basic_filesystems_lvm "${lvm_name}" "db" "${partition1}"
    mount_basic_filesystems_lvm "${lvm_name}" "${partition1}" "${windows_efi_partition}" "db"
else
    create_basic_filesystems_lvm "${lvm_name}" "" "${partition1}"
    mount_basic_filesystems_lvm "${lvm_name}" "${partition1}" "${windows_efi_partition}" ""
fi

arch_configure_mirrors
arch_install_base_packages_pacstrap
arch_install_move_to_script_part_2
