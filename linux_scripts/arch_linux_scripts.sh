#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Compilation of functions that can be called for Arch Linux.

function update_aur_packages() {
    # Prompts
    read -r -p "Update freefilesync? [y/N] " response1
    read -r -p "Update spotify? [y/N] " response3
    read -r -p "Update vscode? [y/N] " response5

    # Get username
    user_name=$(logname)

    # Install packages
    pacman -S --noconfirm --needed base-devel

    # Update freefilesync
    if [[ "${response1}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        cd "/home/${user_name}/aur/freefilesync" || exit
        git clean -df
        git checkout -- .
        git fetch
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        git diff origin
        read -r -p "Ready to update? [y/N] " response2
        if [[ "${response2}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            git pull
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi

    # Update spotify
    if [[ "${response3}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        read -r -p "Choose the latest key. Press enter to continue: "
        sudo -u "${user_name}" gpg --keyserver 'hkp://keyserver.ubuntu.com' --search-key 'Spotify Public Repository Signing Key'
        cd "/home/${user_name}/aur/spotify" || exit
        git clean -df
        git checkout -- .
        git fetch
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        git diff origin
        read -r -p "Ready to update? [y/N] " response4
        if [[ "${response4}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            git pull
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi

    # Update vscode
    if [[ "${response5}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        cd "/home/${user_name}/aur/vscode" || exit
        git clean -df
        git checkout -- .
        git fetch
        read -r -p "Check the contents of the files before installing. Press enter to continue: "
        git diff origin
        read -r -p "Ready to update? [y/N] " response6
        if [[ "${response6}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            git pull
            sudo -u "${user_name}" makepkg -sirc
        fi
    fi
}

function configure_i3_applet_autostarts() {
    # Parameters
    local blueman_applet=$1
    local pasystray_applet=$1
    local nm_applet=$1

    if [[ "${blueman_applet}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        grep -q -E ".*blueman-applet" '/usr/local/bin/i3_autostart.sh' && sed -i -E "s,.*blueman-applet.*,blueman-applet &," '/usr/local/bin/i3_autostart.sh' || printf '%s\n' 'blueman-applet &' >>'/usr/local/bin/i3_autostart.sh'
    fi

    if [[ "${pasystray_applet}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        grep -q -E ".*pasystray" '/usr/local/bin/i3_autostart.sh' && sed -i -E "s,.*pasystray.*,pasystray &," '/usr/local/bin/i3_autostart.sh' || printf '%s\n' 'pasystray &' >>'/usr/local/bin/i3_autostart.sh'
    fi

    if [[ "${nm_applet}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        grep -q -E ".*nm-applet" '/usr/local/bin/i3_autostart.sh' && sed -i -E "s,.*nm-applet.*,nm-applet &," '/usr/local/bin/i3_autostart.sh' || printf '%s\n' 'nm-applet &' >>'/usr/local/bin/i3_autostart.sh'
    fi
}

function sway_autostart_at_login() {
    # Parameters
    local user_name=$1

    cat <<EOF >>"/home/${user_name}/.bash_profile"
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  XKB_DEFAULT_LAYOUT=us exec sway
fi
EOF
}

function configure_neovim() {
    # Parameters
    local user_name=${1}

}
