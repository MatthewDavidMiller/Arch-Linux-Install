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
        # Creates one partition.  Partition uses the rest of the free space avalailable to create a Linux filesystem partition.
        sgdisk -n 0:0:+${partition_size} -c "${partition_number2}":"Linux Filesystem" -t "${partition_number2}":8300 "${disk}"
    else
        # Creates two partitions.  First one is a 512 MB EFI partition while the second uses the rest of the free space avalailable to create a Linux filesystem partition.
        sgdisk -n 0:0:+${partition_1_size} -c "${partition_number1}":"EFI System Partition" -t "${partition_number1}":ef00 "${disk}"
        sgdisk -n 0:0:+${partition_2_size} -c "${partition_number2}":"Linux Filesystem" -t "${partition_number2}":8300 "${disk}"
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
    lvcreate -L "${root_partition_size}" "${lvm_name}" -n root
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

    mount "/dev/${lvm_name}/root" /mnt
    mkdir '/mnt/boot'
    mount "${partition}" '/mnt/boot'
}

function arch_configure_mirrors() {
    rm -f '/etc/pacman.d/mirrorlist'
    cat <<\EOF >'/etc/pacman.d/mirrorlist'
Server = https://archlinux.surlyjake.com/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
Server = https://mirror.dc02.hackingand.coffee/arch/$repo/os/$arch
Server = https://repo.ialab.dsu.edu/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.dal10.us.leaseweb.net/archlinux/$repo/os/$arch
Server = https://mirror.mia11.us.leaseweb.net/archlinux/$repo/os/$arch
Server = https://mirror.sfo12.us.leaseweb.net/archlinux/$repo/os/$arch
Server = https://mirror.wdc1.us.leaseweb.net/archlinux/$repo/os/$arch
Server = https://mirror.lty.me/archlinux/$repo/os/$arch
Server = https://reflector.luehm.com/arch/$repo/os/$arch
Server = https://mirrors.lug.mtu.edu/archlinux/$repo/os/$arch
Server = https://mirror.kaminski.io/archlinux/$repo/os/$arch
Server = https://iad.mirrors.misaka.one/archlinux/$repo/os/$arch
Server = https://mirrors.ocf.berkeley.edu/archlinux/$repo/os/$arch
Server = https://dfw.mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://iad.mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://ord.mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.rit.edu/archlinux/$repo/os/$arch
Server = https://mirrors.rutgers.edu/archlinux/$repo/os/$arch
Server = https://mirrors.sonic.net/archlinux/$repo/os/$arch
Server = https://arch.mirror.square-r00t.net/$repo/os/$arch
Server = https://mirror.stephen304.com/archlinux/$repo/os/$arch
Server = https://mirror.pit.teraswitch.com/archlinux/$repo/os/$arch
Server = https://mirrors.xtom.com/archlinux/$repo/os/$arch

EOF
}

function arch_install_base_packages_pacstrap() {
    pacstrap /mnt --noconfirm base base-devel linux linux-lts linux-firmware systemd e2fsprogs ntfs-3g exfat-utils vi man-db man-pages texinfo lvm2 xf86-video-intel xf86-video-amdgpu xf86-video-nouveau bash bash-completion ntp util-linux iwd || echo 'Error installing packages.'
}

function arch_install_move_to_script_part_2() {
    cp install_functions.sh '/mnt/install_functions.sh'
    wget -O '/mnt/arch_linux_install_part_2.sh' 'https://raw.githubusercontent.com/MatthewDavidMiller/Arch-Linux-Install/stable/linux_scripts/arch_linux_install_part_2.sh'
    chmod +x '/mnt/arch_linux_install_part_2.sh'
    cat <<EOF >'/mnt/tmp/temp_variables.sh'
disk="${disk}"
partition_number1="${partition_number1}"
partition_number2="${partition_number2}"
ucode_response="${ucode_response}"
device_hostname="${device_hostname}"
user_name="${user_name}"
partition1="${partition1}"
partition2="${partition2}"
ucode="${ucode}"
interface="${interface}"
uuid="${uuid}"
uuid2="${uuid2}"
windows_response="${windows_response}"
lvm_name="${lvm_name}"
disk_password="${disk_password}"
EOF
    arch-chroot /mnt "./arch_linux_install_part_2.sh"
}

function arch_install_extra_packages() {
    pacman -S --noconfirm --needed ${ucode} efibootmgr pacman-contrib sudo networkmanager networkmanager-openvpn ufw wget xorg xorg-xinit xorg-drivers xorg-server xorg-apps bluez bluez-utils pulseaudio pulseaudio-bluetooth pulsemixer libinput xf86-input-libinput firefox gnome-keyring termite htop cron || echo 'Error installing packages.'
}

function get_lvm_uuids() {
    boot_uuid=uuid="$(blkid -o value -s UUID "${partition1}")"
    luks_partition_uuid="$(blkid -o value -s UUID "${partition2}")"
    root_uuid="$(blkid -o value -s UUID /dev/Archlvm/root)"
}

function create_basic_lvm_fstab() {
    rm -f '/etc/fstab'
    {
        printf '%s\n' "UUID=${boot_uuid} /boot/EFI vfat defaults 0 0"
        printf '%s\n' '/swapfile none swap defaults 0 0'
        printf '%s\n' "UUID=${root_uuid} / ext4 defaults 0 0"
    } >>'/etc/fstab'
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
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    # Generate locale
    locale-gen
}

function set_language() {
    rm -f '/etc/locale.conf'
    {
        printf '%s\n' '# language config'
        printf '%s\n' '# file location is /etc/locale.conf'
        printf '%s\n' ''
        printf '%s\n' 'LANG=en_US.UTF-8'
        printf '%s\n' ''
    } >>'/etc/locale.conf'
}

function set_hostname() {
    # Parameters
    local device_hostname=${1}

    rm -f '/etc/hostname'
    {
        printf '%s\n' '# hostname file'
        printf '%s\n' '# File location is /etc/hostname'
        printf '%s\n' "${device_hostname}"
        printf '%s\n' ''
    } >>'/etc/hostname'
}

function setup_hosts_file() {
    # Parameters
    local device_hostname=${1}

    rm -f '/etc/hosts'
    {
        printf '%s\n' '# host file'
        printf '%s\n' '# file location is /etc/hosts'
        printf '%s\n' ''
        printf '%s\n' '127.0.0.1 localhost'
        printf '%s\n' '::1 localhost'
        printf '%s\n' "127.0.1.1 ${device_hostname}.localdomain ${device_hostname}"
        printf '%s\n' ''
    } >>'/etc/hosts'
}

function set_root_password() {
    echo 'Set root password'
    passwd root
}

function arch_configure_kernel() {
    rm -f '/etc/mkinitcpio.conf'
    {
        printf '%s\n' '# config for kernel'
        printf '%s\n' '# file location is /etc/mkinitcpio.conf'
        printf '%s\n' ''
        printf '%s\n' 'MODULES=()'
        printf '%s\n' ''
        printf '%s\n' 'BINARIES=()'
        printf '%s\n' ''
        printf '%s\n' 'FILES=()'
        printf '%s\n' ''
        printf '%s\n' 'HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)'
        printf '%s\n' ''
    } >>'/etc/mkinitcpio.conf'
    mkinitcpio -P
}

function arch_setup_systemd_boot_luks_lvm() {
    mkdir '/boot/loader'
    mkdir '/boot/loader/entries'

    {
        printf '%s\n' '# kernel entry for systemd-boot'
        printf '%s\n' '# file location is /boot/loader/entries/arch_linux_lts.conf'
        printf '%s\n' ''
        printf '%s\n' 'title   Arch Linux LTS Kernel'
        printf '%s\n' 'linux   /vmlinuz-linux-lts'
        printf '%s\n' "initrd  /${ucode}.img"
        printf '%s\n' 'initrd  /initramfs-linux-lts.img'
        printf '%s\n' "options cryptdevice=UUID=${luks_partition_uuid}:cryptlvm root=UUID=${root_uuid} rw"
        printf '%s\n' ''
    } >>'/boot/loader/entries/arch_linux_lts.conf'

    {
        printf '%s\n' '# kernel entry for systemd-boot'
        printf '%s\n' '# file location is /boot/loader/entries/arch_linux.conf'
        printf '%s\n' ''
        printf '%s\n' 'title   Arch Linux Default Kernel'
        printf '%s\n' 'linux   /vmlinuz-linux'
        printf '%s\n' "initrd  /${ucode}.img"
        printf '%s\n' 'initrd  /initramfs-linux.img'
        printf '%s\n' "options cryptdevice=UUID=${luks_partition_uuid}:cryptlvm root=UUID=${root_uuid} rw"
        printf '%s\n' ''
    } >>'/boot/loader/entries/arch_linux.conf'

    {
        printf '%s\n' '# config for systemd-boot'
        printf '%s\n' '# file location is /boot/loader/loader.conf'
        printf '%s\n' ''
        printf '%s\n' 'default  arch_linux.conf'
        printf '%s\n' 'auto-entries 1'
        printf '%s\n' ''
    } >>'/boot/loader/loader.conf'
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

    printf '%s\n' "${user_name} ALL=(ALL) ALL" >>'/etc/sudoers'
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
