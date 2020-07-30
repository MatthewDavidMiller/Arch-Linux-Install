#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Functions for Arch Linux Configuration script

function get_username() {
    user_name=$(logname)
}

function enable_bluetooth() {
    systemctl enable bluetooth.service
}

function enable_ufw() {
    systemctl enable ufw.service
    ufw enable
}

function configure_xorg() {
    # Parameters
    local user_name=${1}

    sudo -u "${user_name}" Xorg :0 -configure
}

function setup_touchpad() {
    cat <<\EOF >'/etc/X11/xorg.conf.d/20-touchpad.conf'

Section "InputClass"
 Identifier "libinput touchpad catchall"
 Driver "libinput"
 MatchIsTouchpad "on"
 MatchDevicePath "/dev/input/event*"
 Option "Tapping" "on"
 Option "NaturalScrolling" "false"
EndSection

EOF
}

function pacman_auto_clear_cache() {
    systemctl start paccache.timer
    systemctl enable paccache.timer
}

function lock_root() {
    passwd --lock root
}

function install_arch_packages() {
    local PS3='Select packages to install: '
    local options=("Gnome Desktop Environment" "I3 Windows Manager" "Blender" "Gimp" "Libreoffice" "VSCode" "Quit")
    local options_select

    select options_select in "${options[@]}"; do
        case $options_select in

        "Gnome Desktop Environment")
            pacman -S --noconfirm --needed gnome
            ;;
        "I3 Windows Manager")
            pacman -S --noconfirm --needed i3-wm i3blocks i3lock i3status dmenu
            ;;
        "Blender")
            pacman -S --noconfirm --needed blender
            ;;
        "Gimp")
            pacman -S --noconfirm --needed gimp
            ;;
        "Libreoffice")
            pacman -S --noconfirm --needed libreoffice-fresh
            ;;
        "VSCode")
            pacman -S --noconfirm --needed code
            ;;
        "Quit")
            break
            ;;
        *) echo "$REPLY is not an option" ;;
        esac
    done
}

function install_arch_packages_part_2() {
    local PS3='Select packages to install: '
    local options=("Git" "Putty" "Nvidia LTS Driver" "Dolphin File Manager" "Audacity" "Nmap" "Quit")
    local options_select

    select options_select in "${options[@]}"; do
        case $options_select in

        "Git")
            pacman -S --noconfirm --needed git
            ;;
        "Putty")
            pacman -S --noconfirm --needed putty
            ;;
        "Nvidia LTS Driver")
            pacman -S --noconfirm --needed nvidia-lts
            ;;
        "Dolphin File Manager")
            pacman -S --noconfirm --needed dolphin
            ;;
        "Audacity")
            pacman -S --noconfirm --needed audacity
            ;;
        "Nmap")
            pacman -S --noconfirm --needed nmap
            ;;
        "Quit")
            break
            ;;
        *) echo "$REPLY is not an option" ;;
        esac
    done
}

function install_arch_packages_part_3() {
    local PS3='Select packages to install: '
    local options=("Wireshark" "Ntop" "Jnettop" "Nethogs" "Clamav" "Vim" "Quit")
    local options_select

    select options_select in "${options[@]}"; do
        case $options_select in

        "Wireshark")
            pacman -S --noconfirm --needed wireshark-cli
            ;;
        "Ntop")
            pacman -S --noconfirm --needed ntop
            ;;
        "Jnettop")
            pacman -S --noconfirm --needed jnettop
            ;;
        "Nethogs")
            pacman -S --noconfirm --needed nethogs
            ;;
        "Clamav")
            pacman -S --noconfirm --needed clamav
            ;;
        "Vim")
            pacman -S --noconfirm --needed vim
            ;;
        "Quit")
            break
            ;;
        *) echo "$REPLY is not an option" ;;
        esac
    done
}

function install_arch_packages_part_4() {
    local PS3='Select packages to install: '
    local options=("Shellcheck" "Tftpd" "Cmake" "Pylint" "Light" "Rsync" "Quit")
    local options_select

    select options_select in "${options[@]}"; do
        case $options_select in

        "Shellcheck")
            pacman -S --noconfirm --needed shellcheck
            ;;
        "Tftpd")
            pacman -S --noconfirm --needed tftp-hpa
            ;;
        "Cmake")
            pacman -S --noconfirm --needed cmake
            ;;
        "Pylint")
            pacman -S --noconfirm --needed python-pylint
            ;;
        "Light")
            pacman -S --noconfirm --needed light
            ;;
        "Rsync")
            pacman -S --noconfirm --needed rsync
            ;;
        "Quit")
            break
            ;;
        *) echo "$REPLY is not an option" ;;
        esac
    done
}

function install_arch_packages_part_5() {
    local PS3='Select packages to install: '
    local options=("Seahorse" "Blueman" "Imv" "Quit")
    local options_select

    select options_select in "${options[@]}"; do
        case $options_select in

        "Seahorse")
            pacman -S --noconfirm --needed seahorse
            ;;
        "Blueman")
            pacman -S --noconfirm --needed blueman
            ;;
        "Imv")
            pacman -S --noconfirm --needed imv
            ;;
        "Quit")
            break
            ;;
        *) echo "$REPLY is not an option" ;;
        esac
    done
}

function configure_i3_sway_base() {
    # Parameters
    local user_name=${1}
    local wifi_name=${2}
    local window_manager=${3}

    # Local variables
    local wifi_response
    local monitor_response
    local display1
    local display2

    # Prompts
    read -r -p "Have the wifi autoconnect? [y/N] " wifi_response

    # Setup Duel Monitors
    read -r -p "Is there more than one monitor? [y/N] " monitor_response
    if [[ "${monitor_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        xrandr
        read -r -p "Specify the first display. Example 'HDMI-1': " display1
        read -r -p "Specify the second display. Example 'DVI-D-1': " display2
    fi

    # Setup wm config
    mkdir -p "/home/${user_name}/.config/${window_manager}"
    cp "/etc/${window_manager}/config" "/home/${user_name}/.config/${window_manager}/config"

    # Setup autostart applications
    cat <<EOF >"/usr/local/bin/${window_manager}_autostart.sh"
#!/bin/bash

# Define path to commands.
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

termite &
picom &
xsetroot -solid "#000000"

EOF

    # Have the wifi autoconnect
    if [[ "${wifi_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        cp "/usr/local/bin/${window_manager}_autostart.sh" "/tmp/${window_manager}_autostart.sh"
        bash -c "awk '/xsetroot -solid \"#000000\"/ { print; print \"nmcli connect up '\"'${wifi_name}'\"'\"; next }1' \"/tmp/${window_manager}_autostart.sh\" > \"/usr/local/bin/${window_manager}_autostart.sh\""
    fi

    # Setup duel monitors
    if [[ "${monitor_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        cp "/usr/local/bin/${window_manager}_autostart.sh" "/tmp/${window_manager}_autostart.sh"
        bash -c "awk '/xsetroot -solid \"#000000\"/ { print; print \"xrandr --output ${display2} --auto --right-of ${display1}\"; next }1' \"/tmp/${window_manager}_autostart.sh\" > \"/usr/local/bin/${window_manager}_autostart.sh\""

    fi

    # Allow script to be executable.
    chmod +x "/usr/local/bin/${window_manager}_autostart.sh"

    cat <<EOF >"/home/${user_name}/.config/${window_manager}/config"
    font pango:monospace 12
    
    exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork &
    
    set \$up l
    set \$down k
    set \$left j
    set \$right semicolon
    
    floating_modifier Mod1
    
    bindsym Mod1+Return exec i3-sensible-terminal
    
    bindsym Mod1+Shift+q kill
    
    bindsym Mod1+d exec dmenu_run
    
    bindsym Mod1+\$left focus left
    bindsym Mod1+\$down focus down
    bindsym Mod1+\$up focus up
    bindsym Mod1+\$right focus right
    
    bindsym Mod1+Left focus left
    bindsym Mod1+Down focus down
    bindsym Mod1+Up focus up
    bindsym Mod1+Right focus right
    
    bindsym Mod1+Shift+\$left move left
    bindsym Mod1+Shift+\$down move down
    bindsym Mod1+Shift+\$up move up
    bindsym Mod1+Shift+\$right move right
    
    bindsym Mod1+Shift+Left move left
    bindsym Mod1+Shift+Down move down
    bindsym Mod1+Shift+Up move up
    bindsym Mod1+Shift+Right move right
    
    bindsym Mod1+h split h
    
    bindsym Mod1+v split v
    
    bindsym Mod1+f fullscreen toggle
    
    bindsym Mod1+s layout stacking
    bindsym Mod1+w layout tabbed
    bindsym Mod1+e layout toggle split
    
    bindsym Mod1+Shift+space floating toggle
    
    bindsym Mod1+space focus mode_toggle
    
    bindsym Mod1+a focus parent
    
    bindsym Mod1+Shift+minus move scratchpad

    bindsym Mod1+minus scratchpad show
    
    set \$ws1 "1"
    set \$ws2 "2"
    set \$ws3 "3"
    set \$ws4 "4"
    set \$ws5 "5"
    set \$ws6 "6"
    set \$ws7 "7"
    set \$ws8 "8"
    set \$ws9 "9"
    set \$ws10 "10"
    
    bindsym Mod1+1 workspace number \$ws1
    bindsym Mod1+2 workspace number \$ws2
    bindsym Mod1+3 workspace number \$ws3
    bindsym Mod1+4 workspace number \$ws4
    bindsym Mod1+5 workspace number \$ws5
    bindsym Mod1+6 workspace number \$ws6
    bindsym Mod1+7 workspace number \$ws7
    bindsym Mod1+8 workspace number \$ws8
    bindsym Mod1+9 workspace number \$ws9
    bindsym Mod1+0 workspace number \$ws10
    
    bindsym Mod1+Shift+1 move container to workspace number \$ws1
    bindsym Mod1+Shift+2 move container to workspace number \$ws2
    bindsym Mod1+Shift+3 move container to workspace number \$ws3
    bindsym Mod1+Shift+4 move container to workspace number \$ws4
    bindsym Mod1+Shift+5 move container to workspace number \$ws5
    bindsym Mod1+Shift+6 move container to workspace number \$ws6
    bindsym Mod1+Shift+7 move container to workspace number \$ws7
    bindsym Mod1+Shift+8 move container to workspace number \$ws8
    bindsym Mod1+Shift+9 move container to workspace number \$ws9
    bindsym Mod1+Shift+0 move container to workspace number \$ws10
    
    bindsym Mod1+Shift+c reload
    
    bindsym Mod1+Shift+r restart
    
    bindsym Mod1+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"
    
    mode "resize" {
        
        bindsym \$left       resize shrink width 10 px or 10 ppt
        bindsym \$down       resize grow height 10 px or 10 ppt
        bindsym \$up         resize shrink height 10 px or 10 ppt
        bindsym \$right      resize grow width 10 px or 10 ppt
        
        bindsym Left        resize shrink width 10 px or 10 ppt
        bindsym Down        resize grow height 10 px or 10 ppt
        bindsym Up          resize shrink height 10 px or 10 ppt
        bindsym Right       resize grow width 10 px or 10 ppt
        
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym Mod1+r mode "default"
    }
    
    bindsym Mod1+r mode "resize"
    
    bar {
        status_command i3status
        mode hide
        hidden_state hide
        modifier Mod1
    }
    
    exec --no-startup-id bash '/usr/local/bin/${window_manager}_autostart.sh'
    
EOF

}

function configure_xinit() {
    # Parameters
    local user_name=${1}

    # Copy default config
    cp '/etc/X11/xinit/xinitrc' "/home/${user_name}/.xinitrc"

}

function configure_xinit_i3() {
    # Parameters
    local user_name=${1}

    sed -i -E '/(^\s*[#]*\s*exec xterm.*$)/d' "/home/${user_name}/.xinitrc"
    grep -q -E "(^.*i3.*$)" "/home/${user_name}/.xinitrc" && sed -i -E "s,(^.*i3.*$),exec i3," "/home/${user_name}/.xinitrc" || printf '%s\n' 'exec i3' >>"/home/${user_name}/.xinitrc"
}

function connect_smb() {
    # Parameters
    local user_name=${1}

    # Make /mnt directory
    mkdir '/mnt'

    # Script to connect and mount a smb share
    read -r -p "Mount a samba share? [y/N] " response
    while [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; do
        # Prompts
        # Share location
        read -r -p "Specify share location. Example'//matt-nas.miller.lan/matt_files': " share
        # Mount point location
        read -r -p "Specify mount location. Example'/mnt/matt_files': " mount_location
        # Username
        read -r -p "Specify Username. Example'matthew': " samba_username
        # Password
        read -r -p "Specify Password. Example'password': " password

        # Make directory to mount the share at
        mkdir "${mount_location}"

        # Automount smb share
        grep -q -E "${share} ${mount_location} cifs rw,noauto,x-systemd\.automount,_netdev,uid=${user_name},user,username=${samba_username},password=${password} 0 0" '/etc/fstab' && sed -i -E "s,${share} ${mount_location} cifs rw\,noauto\,x-systemd\.automount\,_netdev\,uid=${user_name}\,user\,username=${samba_username}\,password=${password} 0 0,${share} ${mount_location} cifs rw\,noauto\,x-systemd\.automount\,_netdev\,uid=${user_name}\,user\,username=${samba_username}\,password=${password} 0 0," '/etc/fstab' || printf '%s\n' "${share} ${mount_location} cifs rw,noauto,x-systemd.automount,_netdev,uid=${user_name},user,username=${samba_username},password=${password} 0 0" >>'/etc/fstab'

        # Mount another disk
        read -r -p "Do you want to mount another samba share? [y/N] " response
        if [[ "${response}" =~ ^([nN][oO]|[nN])+$ ]]; then
            printf '%s\n' '' >>'/etc/fstab'
            mount -a
            break
        fi
    done
}

function configure_gdm() {
    # Parameters
    local user_name=${1}

    # Specify session for gdm to use
    read -r -p "Specify session to use. Example: i3 " session

    # Enable gdm
    systemctl enable gdm.service

    # Enable autologin
    cp '/etc/gdm/custom.conf' '/etc/gdm/custom.conf.backup'
    cat <<EOF >'/etc/gdm/custom.conf'
# Enable automatic login for user
[daemon]
AutomaticLogin=${user_name}
AutomaticLoginEnable=True

EOF

    # Setup default session
    cp "/var/lib/AccountsService/users/$user_name" "/var/lib/AccountsService/users/$user_name.backup"
    cat <<EOF >"/var/lib/AccountsService/users/$user_name"
    [User]
    Language=
    Session=${session}
    XSession=${session}
    
EOF
}

function configure_hyperv() {
    systemctl enable hv_fcopy_daemon.service
    systemctl start hv_fcopy_daemon.service
    systemctl enable hv_kvp_daemon.service
    systemctl start hv_kvp_daemon.service
    systemctl enable hv_vss_daemon.service
    systemctl start hv_vss_daemon.service
}

function configure_kvm() {
    # Enable nested virtualization
    cp '/etc/modprobe.d/kvm_intel.conf' '/etc/modprobe.d/kvm_intel.conf.backup'
    grep -q -E "(^\s*[#]*\s*options\s*kvm_intel\s*nested=.*$)" '/etc/modprobe.d/kvm_intel.conf' && sed -i -E "s,(^\s*[#]*\s*options\s*kvm_intel\s*nested=.*$),options kvm_intel nested=1," '/etc/modprobe.d/kvm_intel.conf' || printf '%s\n' 'options kvm_intel nested=1' >>'/etc/modprobe.d/kvm_intel.conf'
}

function configure_termite() {
    # Parameters
    local user_name=${1}

    # Setup termite config
    mkdir -p "/home/${user_name}/.config/termite"
    cp "/home/${user_name}/.config/termite/config" "/home/${user_name}/.config/termite/config.backup"
    cat <<EOF >"/home/${user_name}/.config/termite/config"
    
    [options]
    font = Monospace 16
    scrollback_lines = 10000
    
    [colors]
    
    # If unset, will reverse foreground and background
    highlight = #2f2f2f
    
    # Colors from color0 to color254 can be set
    color0 = #000000
    
    [hints]
    
EOF
}

function configure_sway_config_file() {
    #swaymsg -t get_inputs

    # Parameters
    local user_name=${1}
    local touchpad=${2}

    cat <<EOF >>"/home/${user_name}/.config/sway/config"
    input "${touchpad}" {
        tap enabled
        natural_scroll disabled
    }
    
EOF
}

function install_aur_packages() {
    # Get username
    user_name=$(logname)

    # Prompts
    read -r -p "Install freefilesync? [y/N] " response1
    read -r -p "Install spotify? [y/N] " response3
    read -r -p "Install vscode? [y/N] " response5

    # Install packages
    pacman -S --noconfirm --needed base-devel

    # Create a directory to use for compiling aur packages
    mkdir "/home/${user_name}/aur"
    chown "${user_name}" "/home/${user_name}/aur"
    chmod 744 "/home/${user_name}/aur"

    # Install freefilesync
    if [[ "${response1}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        mkdir "/home/${user_name}/aur/freefilesync"
        git clone 'https://aur.archlinux.org/freefilesync.git' "/home/${user_name}/aur/freefilesync"
        chown -R "${user_name}" "/home/${user_name}/aur/freefilesync"
        chmod -R 744 "/home/${user_name}/aur/freefilesync"
        cd "/home/${user_name}/aur/freefilesync" || exit
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        less PKGBUILD
        read -r -p "Ready to install? [y/N] " response2
        if [[ "${response2}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi

    # Install spotify
    if [[ "${response3}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        mkdir "/home/${user_name}/aur/spotify"
        git clone 'https://aur.archlinux.org/spotify.git' "/home/${user_name}/aur/spotify"
        chown -R "${user_name}" "/home/${user_name}/aur/spotify"
        chmod -R 744 "/home/${user_name}/aur/spotify"
        read -r -p "Choose the latest key. Press enter to continue: "
        sudo -u "${user_name}" gpg --keyserver 'hkp://keyserver.ubuntu.com' --search-key 'Spotify Public Repository Signing Key'
        cd "/home/${user_name}/aur/spotify" || exit
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        less PKGBUILD
        read -r -p "Ready to install? [y/N] " response4
        if [[ "${response4}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi

    # Install vscode
    if [[ "${response5}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        mkdir "/home/${user_name}/aur/vscode"
        git clone 'https://aur.archlinux.org/visual-studio-code-bin.git' "/home/${user_name}/aur/vscode"
        chown -R "${user_name}" "/home/${user_name}/aur/vscode"
        chmod -R 744 "/home/${user_name}/aur/vscode"
        cd "/home/${user_name}/aur/vscode" || exit
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        less PKGBUILD
        read -r -p "Ready to install? [y/N] " response6
        if [[ "${response6}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi
}

function mount_drives() {
    # Make /mnt directory
    mkdir '/mnt'

    read -r -p "Mount a disk? [y/N] " response
    while [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; do

        #See disks
        lsblk -f

        # Prompts
        # Disk location
        read -r -p "Specify disk location. Example'/dev/sda1': " disk1
        # Mount point location
        read -r -p "Specify mount location. Example'/mnt/matt_backup': " mount_location
        #Specify disk type
        read -r -p "Specify disk type. Example'ntfs': " disk_type

        # Get uuid
        uuid="$(blkid -o value -s UUID "${disk1}")"

        # Make directory to mount the disk at
        mkdir "${mount_location}"

        # Automount drive
        grep -q -E "UUID=${uuid} ${mount_location} ${disk_type} rw,noauto,x-systemd\.automount 0 0" '/etc/fstab' && sed -i -E "s,UUID=${uuid} ${mount_location} ${disk_type} rw\,noauto\,x-systemd\.automount 0 0,UUID=${uuid} ${mount_location} ${disk_type} rw\,noauto\,x-systemd\.automount 0 0," '/etc/fstab' || printf '%s\n' "UUID=${uuid} ${mount_location} ${disk_type} rw,noauto,x-systemd.automount 0 0" >>'/etc/fstab'

        # Mount another disk
        read -r -p "Do you want to mount another disk? [y/N] " response
        if [[ "${response}" =~ ^([nN][oO]|[nN])+$ ]]; then
            printf '%s\n' '' >>'/etc/fstab'
            exit
        fi
    done
}

function setup_aliases() {
    # Parameters
    local user_name=${1}

    function copy_ssh_keys() {
        cp '/mnt/matt_files/SSHConfigs/matt_homelab/.' "/home/${user_name}/.ssh/"
    }

    function configure_bashrc() {
        grep -q -E ".*# Aliases" "/home/${user_name}/.bashrc" && sed -i -E "s,.*# Aliases.*,# Aliases," "/home/${user_name}/.bashrc" || printf '%s\n' '# Aliases' >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias sudo='sudo '" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias sudo='sudo '.*,alias sudo='sudo '," "/home/${user_name}/.bashrc" || printf '%s\n' "alias sudo='sudo '" >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias ssh_nas=\"ssh -i '.ssh/nas_key' matthew@matt-nas.miller.lan\"" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias ssh_nas=\"ssh -i '.ssh/nas_key' matthew@matt-nas.miller.lan\".*,alias ssh_nas=\"ssh -i '.ssh/nas_key' matthew@matt-nas.miller.lan\"," "/home/${user_name}/.bashrc" || printf '%s\n' "alias ssh_nas=\"ssh -i '.ssh/nas_key' matthew@matt-nas.miller.lan\"" >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias ssh_openwrt=\"ssh -i '.ssh/openwrt_key' matthew@mattopenwrt.miller.lan\"" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias ssh_openwrt=\"ssh -i '.ssh/openwrt_key' matthew@mattopenwrt.miller.lan\".*,alias ssh_openwrt=\"ssh -i '.ssh/openwrt_key' matthew@mattopenwrt.miller.lan\"," "/home/${user_name}/.bashrc" || printf '%s\n' "alias ssh_openwrt=\"ssh -i '.ssh/openwrt_key' matthew@mattopenwrt.miller.lan\"" >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias ssh_proxmox=\"ssh -i '.ssh/proxmox_key' matthew@matt-prox.miller.lan\"" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias ssh_proxmox=\"ssh -i '.ssh/proxmox_key' matthew@matt-prox.miller.lan\".*,alias ssh_proxmox=\"ssh -i '.ssh/proxmox_key' matthew@matt-prox.miller.lan\"," "/home/${user_name}/.bashrc" || printf '%s\n' "alias ssh_proxmox=\"ssh -i '.ssh/proxmox_key' matthew@matt-prox.miller.lan\"" >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias ssh_vpn=\"ssh -i '.ssh/vpn_key' matthew@matt-vpn.miller.lan\"" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias ssh_vpn=\"ssh -i '.ssh/vpn_key' matthew@matt-vpn.miller.lan\".*,alias ssh_vpn=\"ssh -i '.ssh/vpn_key' matthew@matt-vpn.miller.lan\"," "/home/${user_name}/.bashrc" || printf '%s\n' "alias ssh_vpn=\"ssh -i '.ssh/vpn_key' matthew@matt-vpn.miller.lan\"" >>"/home/${user_name}/.bashrc"
        grep -q -E ".*alias ssh_pihole=\"ssh -i '.ssh/pihole_key' matthew@matt-pihole.miller.lan\"" "/home/${user_name}/.bashrc" && sed -i -E "s,.*alias ssh_pihole=\"ssh -i '.ssh/pihole_key' matthew@matt-pihole.miller.lan\".*,alias ssh_pihole=\"ssh -i '.ssh/pihole_key' matthew@matt-pihole.miller.lan\"," "/home/${user_name}/.bashrc" || printf '%s\n' "alias ssh_pihole=\"ssh -i '.ssh/pihole_key' matthew@matt-pihole.miller.lan\"" >>"/home/${user_name}/.bashrc"
    }
    # Call functions
    copy_ssh_keys
    configure_bashrc
}

function configure_fwupd() {
    # Copy efi file
    cp -a '/usr/lib/fwupd/efi/fwupdx64.efi' '/boot/EFI/'

    # Setup hook
    mkdir -p '/etc/pacman.d/hooks'
    cat <<EOF >'/etc/pacman.d/hooks/fwupd-to-esp.hook'
[Trigger]
Operation = Install
Operation = Upgrade
Type = File
Target = usr/lib/fwupd/efi/fwupdx64.efi

[Action]
When = PostTransaction
Exec = /usr/bin/cp -a /usr/lib/fwupd/efi/fwupdx64.efi /boot/EFI/

EOF
}

function configure_git() {
    # Parameters
    local user_name=${1}

    # Variables
    # Git username
    git_name='MatthewDavidMiller'
    # Email address
    email='matthewdavidmiller1@gmail.com'
    # SSH key location
    key_location='/mnt/matt_files/SSHConfigs/github/github_ssh'
    # SSH key filename
    key='github_ssh'

    # Setup username
    git config --global user.name "${git_name}"

    # Setup email
    git config --global user.email "${email}"

    # Setup ssh key
    mkdir -p "/home/${user_name}/.ssh"
    chmod 700 "/home/${user_name}/.ssh"
    cp "${key_location}" "/home/${user_name}/.ssh/${key}"
    chmod 700 "/home/${user_name}/.ssh/${key}"
    chown "${user_name}" "/home/${user_name}/.ssh/${key}"
    git config --global core.sshCommand "ssh -i ""/home/${user_name}/.ssh/${key}"" -F /dev/null"
}

function configure_serial() {
    # Parameters
    local user_name=${1}

    # Add user to uucp group
    gpasswd -a "${user_name}" uucp
}

function configure_ostimer() {
    grep -q -E ".*timeout" '/boot/loader/loader.conf' && sed -i -E "s,.*timeout.*,timeout 60," '/boot/loader/loader.conf' || printf '%s\n' 'timeout 60' >>'/boot/loader/loader.conf'
}

function configure_ufw_base() {
    # Set default inbound to deny
    ufw default deny incoming

    # Set default outbound to allow
    ufw default allow outgoing
}

function cli_autologin() {
    # Parameters
    local user_name=${1}

    mkdir -p '/etc/systemd/system/getty@tty1.service.d'
    cat <<EOF >'/etc/systemd/system/getty@tty1.service.d/override.conf'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${user_name} --noclear %I \$TERM
EOF
}

function configure_flatpak() {
    pacman -S --noconfirm --needed flatpak
    flatpak remote-add --if-not-exists flathub 'https://flathub.org/repo/flathub.flatpakrepo'
}
