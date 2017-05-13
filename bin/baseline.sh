#!/bin/bash
VERSION="0.2.2"

# Helper Functions
function k_os_settings() {
	echo "Must set K_OS before running, values include:"
	echo "    ANTERGOS"
	echo "Exiting..."
	exit 1
}

# Check that variables set correctly
K_OS="ANTERGOS"
LUSER="jarl"

function antergos_mirror_list(){
	ODIR="$(pwd)"
	cd /etc/pacman.d
	mv antergos-mirrorlist antergos-mirrorlist.backup
	echo -n "Listing Antergos mirrors by speed..."
	rankmirrors antergos-mirrorlist.backup > antergos-mirrorlist
	echo "done"
	cd "${ODIR}"
}

function pacman_mirror_list() {
	ODIR="$(pwd)"
	echo -n "Downloading the latest Arch NO mirrors..."
	cd /etc/pacman.d
	mv mirrorlist mirrorlist.backup
	curl -Ls https://www.archlinux.org/mirrorlist/\?country\=NO | sed -e 's/^#Server/Server/g' > mirrorlist-us
	echo "done"
	echo -n "Listing Arch mirrors by speed..."
	rankmirrors mirrorlist-us > mirrorlist
	echo "done"
	cd "${ODIR}"
}

function arch_update_and_upgrade(){
	echo "Updating local mirror repos..."
	pacman -Syy
	echo "Peforming system upgrade..."
	pacman -Syu --noconfirm
}

function arch_install_base(){
        echo "Installing base terminal applications..."
        pacman -S zsh git scala jre8-openjdk sbt docker emacs --noconfirm
	ODIR="$(pwd)"
	sudo -i -u $LUSER sh $ODIR/node/nvm.sh
        systemctl enable docker.service
        systemctl start docker.service
        docker info
        usermod -aG docker $LUSER
        sudo -i -u $LUSER newgrp docker
}

function arch_install_base_gui(){
	arch_install_base
	echo "Installing base GUI software..."
	pacman -S firefox intellij-idea-ultimate-edition atom --noconfirm
}

function linux_setup_home(){
	# Set up user home
	ODIR="$(pwd)"
	cd /home/$LUSER
	echo -n "Creating required home directories for $LUSER..."
	mkdir -p {.tmp,.bin,Projects}
	echo "done"
	echo -n "Checking for dotfiles repo..."
	if [[ ! -d .dotfiles ]]; then
		echo "not found"
		echo "Cloning dotfiles repo..."
		git clone https://github.com/jarlah/dotfiles .dotfiles
	else
		echo "found"
	fi
	cd "${ODIR}"
}

function linux_setup_git(){
	echo -n "Configuring git..."
	sudo -i -u $LUSER git config --global user.name "Jarl André Hübenthal"
	sudo -i -u $LUSER git config --global user.email "jarl.andre@gmail.com"
	sudo -i -u $LUSER git config --global color.ui true
	echo "done"
}

function linux_setup_ssh_client(){
	echo "Configuring SSH..."
	ODIR="$(pwd)"
        sudo -iH -u $LUSER sh $ODIR/ssh/ssh-keygen.sh
}

function linux_setup_zsh(){
	ODIR="$(pwd)"
	cd /home/$LUSER
	echo -n "Checking for oh-my-zsh..."
	if [[ ! -d  .oh-my-zsh ]]; then
		echo "not found"
		echo "Cloning oh-my-zsh repo"
		git clone https://github.com/robbyrussell/oh-my-zsh .oh-my-zsh
	else
		echo "found"
	fi
	echo -n "Copying zsh profiles..."
	cp .dotfiles/zsh/zshrc-linux .zshrc
	cp .dotfiles/zsh/kustom-linux.zsh-theme .oh-my-zsh/themes
	cat .dotfiles/zsh/addons/git.zshrc-addon >> .zshrc
	chsh -s "$(which zsh)" "$LUSER"
	echo "done"
	cd "${ODIR}"
}

function linux_gnome_startup_apps(){
	ODIR="$(pwd)"
	cd /home/$LUSER
	echo "Configuring GNOME startup applications..."
	echo -n "Checking for ~/.config/autostart..."
	if [[ ! -d .config/autostart ]]; then
		echo "not found"
		mkdir -p .config/autostart
	else
		echo "found"
	fi
	cd .config/autostart
	echo "done"
	cd "${ODIR}"
}

echo "############################"
echo "## Kustom Baseline v$VERSION"
echo "############################"
echo

case "$K_OS" in
	ANTERGOS)
		echo "OS set to ${K_OS}..."
		
		# Set up mirror lists
		#echo -n "Enabling [multilib] repos..."
		#sh -c "echo \"[multilib]\" >> /etc/pacman.conf"
		sh -c "echo \"Include = /etc/pacman.d/mirrorlist\" >> /etc/pacman.conf"
		echo "done"

		pacman_mirror_list
		antergos_mirror_list	
		
		# Debloat the system
		echo -n "Removing bloat software..."
		pacman -Rns pidgin --noconfirm
		pacman -Rns gnome-robots  --noconfirm
		pacman -Rns gnome-chess  --noconfirm
		pacman -Rns gnome-tetravex  --noconfirm
		pacman -Rns gnome-nibbles  --noconfirm
		pacman -Rns xnoise  --noconfirm
		pacman -Rns empathy  --noconfirm
		pacman -Rns anjuta  --noconfirm
		pacman -Rns aisleriot  --noconfirm
		pacman -Rns accerciser  --noconfirm
		pacman -Rns gnome-ku  --noconfirm
		pacman -Rns gnome-mahjongg  --noconfirm
		pacman -Rns four-in-a-row  --noconfirm
		pacman -Rns five-or-more  --noconfirm
		pacman -Rns evolution  --noconfirm
		pacman -Rns gnome-klotski  --noconfirm
		pacman -Rns iagno  --noconfirm
		pacman -Rns gnome-mines --noconfirm
		pacman -Rns polari --noconfirm
		pacman -Rns quadrapassel --noconfirm
		pacman -Rns tali --noconfirm
		pacman -Rns swell-foop --noconfirm
		pacman -Rns transmission-cli --noconfirm
		echo "done"

		# Install common software
		arch_install_base_gui

		# Set up /home
		linux_setup_home
		linux_setup_home

		# Set up git
		linux_setup_git

		# Set up SSH client
		linux_setup_ssh_client

		# Set up ZSH
		linux_setup_zsh
		linux_setup_zsh

		# Set up GNOME startup programs
		linux_gnome_startup_apps

		;;
	*)
		k_os_settings
		;;
esac

echo "Setup complete!"
exit 0
