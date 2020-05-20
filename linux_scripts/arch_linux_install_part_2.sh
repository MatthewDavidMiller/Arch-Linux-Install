#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Part 2 of install script for Arch Linux.

# Log errors
# exec 2>arch_linux_install_part_2.sh_errors.txt

# Default variables
user_name='matthew'
device_hostname='MatthewLaptop'
swap_file_size='1024'

# Source functions
source install_functions.sh
source temp_variables.sh

# Prompts, uncomment to use

# Specify device hostname
#read -r -p "Set the device hostname: " device_hostname
# Specify user name
#read -r -p "Specify a username for a new user: " user_name

# Call functions

if [[ "${windows_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    arch_install_extra_packages "db"
else
    arch_install_extra_packages ""
fi

if [[ "${windows_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    get_lvm_uuids "db" "${windows_efi_partition}"
else
    get_lvm_uuids "" ""
fi

if [[ "${windows_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    create_basic_lvm_fstab "db"
else
    create_basic_lvm_fstab ""
fi

create_swap_file "${swap_file_size}"
set_timezone
set_hardware_clock
enable_ntpd_client
arch_setup_locales
set_language
set_hostname "${device_hostname}"
setup_hosts_file "${device_hostname}"
set_root_password
arch_configure_kernel
arch_setup_systemd_boot_luks_lvm
set_systemd_boot_install_path
create_user "${user_name}"
add_user_to_sudo "${user_name}"
enable_network_manager
set_shell_bash "${user_name}"
