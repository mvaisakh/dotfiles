#!/bin/bash

cyan='tput setaf 6'
yellow='tput setaf 3'
reset='tput sgr0'

release=$(sed -rn 's/^NAME="([^"]*)"/\1/p' /etc/os-release)

echo -e "\n$($cyan)// Switch to $($yellow)zsh $($cyan)+ $($yellow)zsh-theme-powerlevel10k-git$($cyan) [y/n]$($reset)?"
read -r zsh

echo -e "\n$($cyan)// Install $($yellow)yay$($cyan) as AUR helper$($cyan) [y/n]$($reset)?"
read -r yay

case $release in
	"Arch Linux" | "Artix Linux" | "Manjaro Linux")

		packages="adwaita-icon-theme feh gnome-themes-extra lxappearance otf-font-awesome papirus-icon-theme playerctl pulseaudio rxvt-unicode scrot urxvt-perls xorg-xbacklight dmenu xclip ranger"

		[ ! "$zsh" = "y" ] || packages+=" zsh zsh-theme-powerlevel10k"

		echo -e "\n$($cyan)// Installing required packages$($reset)\n"
		sudo pacman -S $packages

		echo -e "\n$($cyan)// Installing AUR packages$($reset)\n"

		aur_dependencies="base-devel git"
		aur_packages="picom-ibhagwan-git urxvt-resize-font-git ttf-meslo"

		[ ! "$yay" = "y" ] || aur_packages+=" yay-bin"

		echo -e "\n$($cyan)Installing dependencies for building $($yellow) AUR packages $($reset)\n"
		sudo pacman -S $aur_dependencies

		echo -e "\n$($cyan)// Cloning & Building $($yellow)AUR packages$($reset)\n"
		for aur_package in $aur_packages; do
			echo -e "\n$($yellow)$aur_package$($reset)\n"
			git clone https://aur.archlinux.org/"$aur_package" .build
			cd .build && makepkg -si
			cd ../
			rm -rf .build
		done

		git_packages="dwm dwmblocks"

		echo -e "\n$($cyan)// Cloning & Building $($yellow)git packages$($reset)\n"
		for git_package in $git_packages; do
			echo -e "\n$($yellow)$git_package$($reset)\n"
			rm -rf ~/.local/src/"$git_package"
			git clone https://git.keksla.wtf/dj/"$git_package" ~/.local/src/"$git_package"
			pushd ~/.local/src/"$git_package" 1>/dev/null && sudo make install
			popd 1>/dev/null || (
				echo "popd: failed"
				exit
			)
		done
		;;
	*)
		echo -e "\n$($cyan)// woops. you're probably not running an $($yellow)Arch $($cyan)based distro$($reset)\n"
		;;
esac

backup_list=(.vimrc .xprofile .Xresources .zshenv .zshrc)
symlink_list=(.config/git .config/ranger .config/zsh .local/bin .local/share/dwm .local/share/fonts .profile .vimrc .xprofile .Xresources .zshenv)
dir_list=(.config .config/wget/ .cache/zsh .local/share Pictures/Screenshots)

if [ "$zsh" = "y" ]; then
	symlink_list+=(" .zshrc")
	echo -e "\n$($cyan)// Changing default shell to $($yellow)zsh$($reset)\n"
	chsh -s "$(which zsh)"
fi

# get rid of system beep
sudo rmmod pcspkr snd_pcsp &>/dev/null
printf "blacklist pcspkr\nblacklist snd_pcsp" | sudo tee /etc/modprobe.d/nobeep.conf 1>/dev/null

# tap to click
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
    # Enable left mouse button by tapping
    Option "Tapping" "on"
EndSection' | sudo tee /etc/X11/xorg.conf.d/40-libinput.conf 1>/dev/null

# backup some specified files
rm -rf ~/dotfiles/.backup
mkdir ~/dotfiles/.backup
for file in ${backup_list[*]}; do
	cp ~/"$file" ~/dotfiles/.backup 2>/dev/null
done

# cleanup previous files if any
for file in ${symlink_list[*]}; do
	rm -rf ~/"$file"
done

# make sure directories we need are present
for dir in ${dir_list[*]}; do
	mkdir -p ~/"$dir"
done

# create empty config files for programs
touch ~/.config/wget/wgetrc

# go ahead and symlink everything
for file in ${symlink_list[*]}; do
	ln -s ~/dotfiles/"$file" ~/"$file"
done

echo -e "\n$($cyan)// All done. Make sure to:\n
	1. Set themes and fonts using $($yellow)lxappearance $($cyan)after logging into dwm\n
	2. Log out and back in for $($yellow)zsh $($cyan)to kick in\n
	3. Some general configs have been backed to $($yellow) ~/dotfiles/.backup $($cyan)\n
	4. Maybe move useful code from previous $($yellow).zshrc $($cyan)or $($yellow).bashrc\n $($reset)"
