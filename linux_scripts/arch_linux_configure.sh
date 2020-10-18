#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Configuration script for Arch Linux.  Run after installing. Run as root.

# Get script location
# script_location="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Get needed scripts
curl 'https://raw.githubusercontent.com/MatthewDavidMiller/Arch-Linux-Install/stable/linux_scripts/configuration_functions.sh' -o 'configuration_functions.sh'

# Source functions
source configuration_functions.sh

# Default variables
wifi_name='Miller Homelab'

# Call functions
get_username
enable_bluetooth
configure_ufw_base
enable_ufw
configure_xorg "${user_name}"
setup_touchpad
pacman_auto_clear_cache
lock_root
configure_flatpak

PS3='Select Configuration Option: '
options=("Install Arch Linux Packages" "Configure I3 Windows Manager" "Configure Samba Share" "Configure Gnome Display Manager" "Configure Hyper-V" "Configure KVM" "Quit")

select options_select in "${options[@]}"; do
    case $options_select in

    "Install Arch Linux Packages")
        install_arch_packages
        install_arch_packages_part_2
        install_arch_packages_part_3
        install_arch_packages_part_4
        install_arch_packages_part_5
        ;;
    "Configure I3 Windows Manager")
        get_username
        # Install packages
        pacman -S --needed i3-wm i3blocks i3lock i3status dmenu picom xorg-xrandr acpilight
        configure_i3_sway_base "${user_name}" "${wifi_name}" "i3"
        configure_xinit
        configure_xinit_i3
        ;;
    "Configure Samba Share")
        # Install samba
        pacman -S --noconfirm --needed samba
        get_username
        connect_smb "${user_name}"
        ;;
    "Configure Gnome Display Manager")
        get_username
        configure_gdm "${user_name}"
        ;;
    "Configure Hyper-V")
        # Install hyperv tools
        pacman -S --noconfirm --needed hyperv
        configure_hyperv
        ;;
    "Configure KVM")
        # Install packages
        pacman -S --noconfirm --needed libvirt gnome-boxes ebtables dnsmasq bridge-utils
        configure_kvm
        ;;
    "Quit")
        break
        ;;
    *) echo "$REPLY is not an option" ;;
    esac
done

PS3='Select Configuration Option: '
options=("Configure Sway" "Configure Termite" "Install Aur Packages" "Mount Drives" "Setup Aliases" "Configure FWUPD" "Quit")

select options_select in "${options[@]}"; do
    case $options_select in

    "Configure Sway")
        get_username
        # Install packages
        pacman -S --needed sway swayidle swaylock i3status dmenu xorg-server-xwayland polkit-gnome xorg-xrandr acpilight
        configure_i3_sway_base "${user_name}" "${wifi_name}" "sway"
        configure_sway_config_file "${user_name}"
        ;;
    "Configure Termite")
        get_username
        # Install packages
        pacman -S --noconfirm --needed termite
        configure_termite "${user_name}"
        ;;
    "Install Aur Packages")
        get_username
        install_aur_packages
        ;;
    "Mount Drives")
        # Install linux-utils
        pacman -S --noconfirm --needed util-linux
        mount_drives
        ;;
    "Setup Aliases")
        get_username
        setup_aliases "${user_name}"
        ;;
    "Configure FWUPD")
        # Install fwupd
        pacman -S --noconfirm --needed fwupd
        configure_fwupd
        ;;
    "Quit")
        break
        ;;
    *) echo "$REPLY is not an option" ;;
    esac
done

PS3='Select Configuration Option: '
options=("Configure Git" "Configure Serial" "Configure CLI Autologin" "Quit")

select options_select in "${options[@]}"; do
    case $options_select in

    "Configure Git")
        get_username
        # Install git
        pacman -S --noconfirm --needed git
        configure_git "${user_name}"
        ;;
    "Configure Serial")
        get_username
        # Install putty
        pacman -S --noconfirm --needed putty
        configure_serial "${user_name}"
        ;;
    "Configure CLI Autologin")
        get_username
        cli_autologin "${user_name}"
        ;;
    "Quit")
        break
        ;;
    *) echo "$REPLY is not an option" ;;
    esac
done
