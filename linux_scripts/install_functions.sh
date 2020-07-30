#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Functions for Arch Linux Install script

function list_partitions() {
    lsblk -f
}

function start_dhcpcd() {
    systemctl start "dhcpcd.service"
}

function arch_connect_to_wifi() {
    # Parameters
    local wifi_interface=${1}
    local ssid=${2}

    systemctl start "iwd.service"
    iw dev
    iwctl station "${wifi_interface}" scan
    iwctl station "${wifi_interface}" connect "${ssid}"
}

function check_for_internet_access() {
    if false ping -c2 "google.com"; then
        echo 'No internet'
        exit 1
    fi
}

function enable_ntp_timedatectl() {
    timedatectl set-ntp true
}

function delete_all_partitions_on_a_disk() {
    # Parameters
    local disk=${1}

    local response
    read -r -p "Are you sure you want to delete everything on ${disk}? [y/N] " response
    if [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        # Deletes all partitions on disk
        sgdisk -Z "${disk}"
        sgdisk -og "${disk}"
    fi
}

function get_ucode_type() {
    # Parameters
    local ucode_response=${1}

    if [[ "${ucode_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        ucode='intel-ucode'
    else
        ucode='amd-ucode'
    fi
}

function create_basic_partitions() {
    # Parameters
    local partition_1_size=${1}
    local partition_2_size=${2}

    if [[ "${windows_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        # Creates one partition.  Partition is a Linux Filesystem.
        sgdisk -n 0:0:${partition_2_size} -c "${partition_number2}":"Linux Filesystem" -t "${partition_number2}":8300 "${disk}"
    else
        # Creates two partitions.  First one is a 512 MB EFI partition while the second creates a Linux filesystem partition.
        sgdisk -n 0:0:${partition_1_size} -c "${partition_number1}":"EFI System Partition" -t "${partition_number1}":ef00 "${disk}"
        sgdisk -n 0:0:${partition_2_size} -c "${partition_number2}":"Linux Filesystem" -t "${partition_number2}":8300 "${disk}"
    fi
}

function create_luks_partition() {
    # Parameters
    local disk_password=${1}
    local partition=${2}

    printf '%s\n' "${disk_password}" >'/tmp/disk_password'
    cryptsetup -q luksFormat "${partition}" <'/tmp/disk_password'
}

function create_basic_lvm() {
    # Parameters
    local partition=${1}
    local disk_password=${2}
    local lvm_name=${3}
    local root_partition_size=${4}

    cryptsetup open "${partition}" cryptlvm <"${disk_password}"
    pvcreate '/dev/mapper/cryptlvm'
    vgcreate "${lvm_name}" '/dev/mapper/cryptlvm'
    lvcreate -l "${root_partition_size}" "${lvm_name}" -n root
    rm -f "${disk_password}"
}

function create_basic_filesystems_lvm() {
    # Parameters
    local lvm_name=${1}
    local duel_boot=${2}
    local partition=${3}

    mkfs.ext4 "/dev/${lvm_name}/root"

    if [[ ! "${duel_boot}" =~ ^([d][b])+$ ]]; then
        mkfs.fat -F32 "${partition}"
    fi
}

function mount_basic_filesystems_lvm() {
    # Parameters
    local lvm_name=${1}
    local partition=${2}
    local windows_efi_partition=${3}
    local duel_boot=${4}

    mount "/dev/${lvm_name}/root" /mnt
    mkdir -p '/mnt/boot'

    if [[ "${duel_boot}" =~ ^([d][b])+$ ]]; then
        mount "${windows_efi_partition}" '/mnt/boot'
    else
        mount "${partition}" '/mnt/boot'
    fi

}

function arch_configure_mirrors() {
    cp '/etc/pacman.d/mirrorlist' '/etc/pacman.d/mirrorlist.backup'
    reflector --latest 200 --protocol https --sort rate --save '/etc/pacman.d/mirrorlist'
}

function arch_install_base_packages_pacstrap() {
    pacstrap /mnt --noconfirm base base-devel linux linux-firmware systemd e2fsprogs ntfs-3g exfat-utils vi man-db man-pages texinfo lvm2 xf86-video-intel xf86-video-amdgpu xf86-video-nouveau bash bash-completion ntp util-linux iwd || echo 'Error installing packages.'
}

function arch_install_move_to_script_part_2() {
    cp install_functions.sh '/mnt/install_functions.sh'
    curl 'https://raw.githubusercontent.com/MatthewDavidMiller/Arch-Linux-Install/stable/linux_scripts/arch_linux_install_part_2.sh' -o '/mnt/arch_linux_install_part_2.sh'
    chmod +x '/mnt/arch_linux_install_part_2.sh'
    cat <<EOF >'/mnt/temp_variables.sh'
disk="${disk}"
partition_number1="${partition_number1}"
partition_number2="${partition_number2}"
ucode_response="${ucode_response}"
partition1="${partition1}"
partition2="${partition2}"
ucode="${ucode}"
interface="${interface}"
uuid="${uuid}"
uuid2="${uuid2}"
windows_response="${windows_response}"
lvm_name="${lvm_name}"
disk_password="${disk_password}"
windows_efi_partition="${windows_efi_partition}"
EOF
    arch-chroot /mnt "./arch_linux_install_part_2.sh"
}

function arch_install_extra_packages() {
    # Parameters
    local duel_boot=${1}

    pacman -S --noconfirm --needed ${ucode} efibootmgr pacman-contrib sudo networkmanager networkmanager-openvpn ufw curl xorg xorg-xinit xorg-drivers xorg-server xorg-apps bluez bluez-utils pulseaudio pulseaudio-bluetooth pulsemixer libinput xf86-input-libinput firefox gnome-keyring termite htop cron || echo 'Error installing packages.'

    if [[ ! "${duel_boot}" =~ ^([d][b])+$ ]]; then
        pacman -S --noconfirm --needed linux-lts
    fi
}

function get_lvm_uuids() {
    # Parameters
    local duel_boot=${1}
    local windows_efi_partition=${2}

    luks_partition_uuid="$(blkid -o value -s UUID "${partition2}")"
    root_uuid="$(blkid -o value -s UUID /dev/Archlvm/root)"

    if [[ "${duel_boot}" =~ ^([d][b])+$ ]]; then
        windows_efi_uuid="$(blkid -o value -s UUID "${windows_efi_partition}")"
    else
        boot_uuid=uuid="$(blkid -o value -s UUID "${partition1}")"
    fi

}

function create_basic_lvm_fstab() {
    # Parameters
    local duel_boot=${1}

    cp '/etc/fstab' '/etc/fstab.backup'
    {
        printf '%s\n' '/swapfile none swap defaults 0 0'
        printf '%s\n' "UUID=${root_uuid} / ext4 defaults 0 0"
    } >>'/etc/fstab'

    if [[ "${duel_boot}" =~ ^([d][b])+$ ]]; then
        printf '%s\n' "UUID=${windows_efi_uuid} /boot vfat defaults 0 0" >>'/etc/fstab'
    else
        printf '%s\n' "UUID=${boot_uuid} /boot vfat defaults 0 0" >>'/etc/fstab'
    fi
}

function create_swap_file() {
    # Parameters
    local swap_file_size=${1}

    # Create swapfile
    dd if=/dev/zero of=/swapfile bs=1M count="${swap_file_size}" status=progress
    # Set file permissions
    chmod 600 /swapfile
    # Format file to swap
    mkswap /swapfile
    # Activate the swap file
    swapon /swapfile
}

function set_timezone() {
    ln -sf '/usr/share/zoneinfo/America/New_York' '/etc/localtime'
}

function set_hardware_clock() {
    hwclock --systohc
}

function enable_ntpd_client() {
    systemctl enable ntpd.service
}

function arch_setup_locales() {
    sed -i -E 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    # Generate locale
    locale-gen
}

function set_language() {
    cp '/etc/locale.conf' '/etc/locale.conf.backup'
    grep -q -E "(^\s*[#]*\s*LANG=.*$)" '/etc/locale.conf' && sed -i -E "s,(^\s*[#]*\s*LANG=.*$),LANG=en_US\.UTF-8," '/etc/locale.conf' || printf '%s\n' 'LANG=en_US.UTF-8' >>'/etc/locale.conf'
}

function set_hostname() {
    # Parameters
    local device_hostname=${1}

    cp '/etc/hostname' '/etc/hostname.backup'
    printf '%s\n' "${device_hostname}" >'/etc/hostname'
}

function setup_hosts_file() {
    # Parameters
    local device_hostname=${1}

    cp '/etc/hosts' '/etc/hosts.backup'
    grep -q -E "(^\s*[#]*\s*127\.0\.0\.1 localhost$)" '/etc/hosts' && sed -i -E "s,(^\s*[#]*\s*127\.0\.0\.1 localhost$),127\.0\.0\.1 localhost," '/etc/hosts' || printf '%s\n' '127.0.0.1 localhost' >>'/etc/hosts'
    grep -q -E "(^\s*[#]*\s*::1.*$)" '/etc/hosts' && sed -i -E "s,(^\s*[#]*\s*::1.*$),::1 localhost," '/etc/hosts' || printf '%s\n' '::1 localhost' >>'/etc/hosts'
    grep -q -E "(^\s*[#]*\s*127\.0\.0\.1.*\.localdomain.*$)" '/etc/hosts' && sed -i -E "s,(^\s*[#]*\s*127\.0\.0\.1.*\.localdomain.*$),127\.0\.0\.1 ${device_hostname}\.localdomain ${device_hostname}," '/etc/hosts' || printf '%s\n' "127.0.0.1 ${device_hostname}.localdomain ${device_hostname}" >>'/etc/hosts'
}

function set_root_password() {
    echo 'Set root password'
    passwd root
}

function arch_configure_kernel() {
    cp '/etc/mkinitcpio.conf' '/etc/mkinitcpio.conf.backup'
    grep -q -E "(^\s*[#]*\s*HOOKS=.*$)" '/etc/mkinitcpio.conf' && sed -i -E "s,(^\s*[#]*\s*HOOKS=.*$),HOOKS=\(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck\)," '/etc/mkinitcpio.conf' || printf '%s\n' 'HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)' >>'/etc/mkinitcpio.conf'
    mkinitcpio -P
}

function arch_setup_systemd_boot_luks_lvm() {
    mkdir -p '/boot/loader/entries'

    cat <<EOF >'/boot/loader/entries/arch_linux_lts.conf'
title   Arch Linux LTS Kernel
linux   /vmlinuz-linux-lts
initrd  /${ucode}.img
initrd  /initramfs-linux-lts.img
options cryptdevice=UUID=${luks_partition_uuid}:cryptlvm root=UUID=${root_uuid} rw
EOF

    cat <<EOF >'/boot/loader/entries/arch_linux.conf'
title   Arch Linux Default Kernel
linux   /vmlinuz-linux
initrd  /${ucode}.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=${luks_partition_uuid}:cryptlvm root=UUID=${root_uuid} rw
EOF

    cat <<EOF >'/boot/loader/loader.conf'
default  arch_linux.conf
auto-entries 1
EOF
}

function set_systemd_boot_install_path() {
    bootctl --path=/boot install
}

function create_user() {
    # Parameters
    local user_name=${1}

    useradd -m "${user_name}"
    echo "Set the password for ${user_name}"
    passwd "${user_name}"
    mkdir -p "/home/${user_name}"
    chown "${user_name}" "/home/${user_name}"
}

function add_user_to_sudo() {
    # Parameters
    local user_name=${1}
    grep -q -E "(^\s*[#]*\s*${user_name}.*$)" '/etc/sudoers' && sed -i -E "s,(^\s*[#]*\s*${user_name}.*$),${user_name} ALL=\(ALL\) ALL," '/etc/sudoers' || printf '%s\n' "${user_name} ALL=(ALL) ALL" >>'/etc/sudoers'
}

function enable_network_manager() {
    systemctl enable NetworkManager.service
}

function set_shell_bash() {
    # Parameters
    local user_name=${1}

    chsh -s /bin/bash
    chsh -s /bin/bash "${user_name}"
}
