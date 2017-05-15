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
	ODIR="$(pwd)"
        echo "Installing base terminal applications..."
        pacman -S zsh git scala jre8-openjdk jdk8-openjdk sbt docker docker-compose emacs htop tlp tlp-rdw firefox atom virtualbox virtualbox-host-modules-arch net-tools nginx --noconfirm
	modprobe vboxdrv
	systemctl enable nginx.service 
	systemctl start nginx.service
	systemctl enable tlp.service
	systemctl enable tlp-sleep.service
	systemctl disable systemd-rfkill.service
	systemctl mask systemd-rfkill.service
	systemctl start tlp.service
	systemctl start tlp-sleep.service
	sudo -i -u $LUSER sh $ODIR/node/nvm.sh
        systemctl enable docker.service
        systemctl start docker.service
        docker info
        usermod -aG docker $LUSER
	echo "Reboot or run newgrp docker to work with docker"
}

function linux_setup_home(){
	# Set up user home
	ODIR="$(pwd)"
	cd /home/$LUSER
	echo -n "Creating required home directories for $LUSER..."
	sudo -iH -u $LUSER mkdir -p {.tmp,.bin,Projects}
	echo "done"
	echo -n "Checking for dotfiles repo..."
	if [[ ! -d .dotfiles ]]; then
		echo "not found"
		echo "Cloning dotfiles repo..."
		sudo -iH -u $LUSER git clone https://github.com/jarlah/dotfiles .dotfiles
	else
		echo "found"
	fi
	echo "done"
	cd "${ODIR}"
}

function linux_setup_git(){
	echo -n "Configuring git..."
	sudo -iH -u $LUSER git config --global user.name "Jarl André Hübenthal"
	sudo -iH -u $LUSER git config --global user.email "jarl.andre@gmail.com"
	sudo -iH -u $LUSER git config --global color.ui true
	echo "done"
}

function linux_setup_ssh_client(){
	echo "Configuring SSH..."
	ODIR="$(pwd)"
        sudo -iH -u $LUSER sh $ODIR/ssh/ssh-keygen.sh
	echo "done"
}

function linux_setup_zsh(){
	ODIR="$(pwd)"
	cd /home/$LUSER
	echo -n "Checking for oh-my-zsh..."
	if [[ ! -d  .oh-my-zsh ]]; then
		echo "not found"
		echo "Cloning oh-my-zsh repo"
		sudo -iH -u $LUSER git clone https://github.com/robbyrussell/oh-my-zsh .oh-my-zsh
	else
		echo "found"
	fi
	echo -n "Copying zsh profiles..."
	sudo -iH -u $LUSER cp .dotfiles/zsh/zshrc-linux .zshrc
	sudo -iH -u $LUSER cp .dotfiles/zsh/kustom-linux.zsh-theme .oh-my-zsh/themes
	sudo -iH -u $LUSER cat .dotfiles/zsh/addons/git.zshrc-addon >> .zshrc
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
		sudo -iH -u $LUSER mkdir -p .config/autostart
	else
		echo "found"
	fi
	cd "${ODIR}"
}

function blacklist_nouveau() {
	echo -n "Disabling nouevau..."
	cp nouveau/blacklist.conf /etc/modprobe.d/blacklist.conf
	echo "done"
}

function increase_watch_limit() {
	echo fs.inotify.max_user_watches=524288 | tee /etc/sysctl.d/40-max-user-watches.conf && sysctl --system
}

function disable_tap_to_click() {
	echo -n "Disabling tap to click...."
	sed -i 's/Option "TapButton1" "1"/#Option "TapButton1" "1"/g' /etc/X11/xorg.conf.d/50-synaptics.conf 
 	sed -i 's/Option "TapButton2" "2"/#Option "TapButton2" "2"/g' /etc/X11/xorg.conf.d/50-synaptics.conf 
 	sed -i 's/Option "TapButton3" "3"/#Option "TapButton3" "3"/g' /etc/X11/xorg.conf.d/50-synaptics.conf 
	echo "done"
}

function remove_bloat_software() {
	echo "Removing bloat software..."
	BLOAT=( 
	  "pidgin"
	  "gnome-robots" 
	  "gnome-chess"
	  "gnome-tetravex"
	  "gnome-nibbles"
	  "xnoise"
	  "empathy"
	  "anjuta"
	  "aisleriot"
	  "accerciser"
	  "gnome-ku"
	  "gnome-mahjongg"
	  "four-in-a-row"
	  "five-or-more"
	  "evolution"
	  "gnome-klotski" 
	  "iagno"
	  "gnome-mines"
	  "polari"
	  "quadrapassel"
  	  "tali"
	  "swell-foop"
	  "transmission-gtk"
	  "transimission-cli"
	  "transmission"
	)
	for toRemove in "${BLOAT[@]}"
	do
	   : 
	   pacman -Rns $toRemove --noconfirm
	done
	echo "done"
}

echo "############################"
echo "## Custom Baseline v$VERSION"
echo "############################"
echo

case "$K_OS" in
	ANTERGOS)
		echo "OS set to ${K_OS}..."
		blacklist_nouveau
		disable_tap_to_click
		increase_watch_limit
		pacman_mirror_list
		antergos_mirror_list	
		remove_bloat_software
		arch_install_base
		linux_setup_home
		linux_setup_git
		linux_setup_ssh_client
		linux_setup_zsh
		linux_gnome_startup_apps
		;;
	*)
		k_os_settings
		;;
esac

echo "Setup complete!"
exit 0
