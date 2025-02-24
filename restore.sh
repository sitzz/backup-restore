#!/bin/bash

set -e

# Set runtime vars
INCLUDE=$(cat include.txt)
SOURCE="${HOME}/tmp_restore"

# Restore from backup file
read -p "- Please enter backup file name: " BACKUP_FILE
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: file not found $BACKUP_FILE"
    exit 1
fi
mkdir $SOURCE

echo "Ensuring script dependencies..."
sudo pacman --noconfirm -S unzip zip

echo "Unzipping backup file $BACKUP_FILE"
unzip -d $SOURCE $BACKUP_FILE

# Restore files and folders
echo "Restoring backup of files and folders..."
for path in $INCLUDE
do
    if [[ -e "${SOURCE}/${path}" ]]; then
        echo "... Restoring file $path"
        mv -f $SOURCE/$path $HOME
    fi
    if [[ -d "${SOURCE}/${path}" ]]; then
        echo "... Restoring folder $path"
        mv -f $SOURCE/$path $HOME
    fi
done

# Import GnuPG keys
echo "Importing gpg keys..."
gpg --import $HOME/tmp_restore/tmp/secret.gpg
gpg --import $HOME/tmp_restore/tmp/secret_sub.gpg
sudo pacman-key --updatedb
gpg --list-key
read -p "- Please enter key ID to update trust: " GPG_KEY_ID
gpg --edit-key $GPG_KEY_ID

# Update system and install required packages
echo "Updating system..."
sudo pacman --noconfirm -Syu
echo "Installing official packages..."
sudo pacman --noconfirm -S base-devel code dbeaver fakeroot docker docker-buildx docker-compose go mousepad nodejs npm obsidian python-pipx python-pytest python-ruff python-uv screen vim yay
read -p "- Install work applications (aws-cli, aws-vault, k9s, kubectl)? [y/N]: " OFFIWORKAPPS
if [ "${OFFIWORKAPPS,,}" = "y" ]; then
    sudo pacman --noconfirm -S aws-cli aws-vault k9s kubectl
fi

# Remove unwanted packages
echo "Removing unwanted official packages..."
sudo pacman -R kate || true
sudo pacman -R manjaro-application-utility || true
sudo pacman -R pamac-tray-icon-plasma || true
sudo pacman -R pamac-gtk3 || true

# Install aur packages
echo "Installing aur packages"
mkdir -p $HOME/.ICAClient/cache
yay -S --sudoloop --noconfirm 1password postman-bin pycharm-community-jre sublime-text-4 webstorm webstorm-jre
read -p "- Install work applications from AUR (aws-session-manager-plugin, slack-desktop, teams-for-linux)? [y/N]: " AURWORKAPPS
if [ "${AURWORKAPPS,,}" = "y" ]; then
    yay -S --sudoloop --noconfirm aws-session-manager-plugin icaclient slack-desktop teams-for-linux
fi

# Install NVM
echo "Installing nvm..."
git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm
$HOME/.nvm/install.sh

# Add user to docker group
echo "Adding $USER to group 'docker'..."
sudo usermod -aG docker $USER

# Add update checker
# Inspired by: https://www.reddit.com/r/archlinux/comments/1ap45n8/comment/kqdzzk3/
mkdir -p $HOME/.config/systemd/user
cp ./services/* $HOME/.config/systemd/user/
syystemctl --user enable --now checkupdates.timer

# Add loading of .bash_aliases to .bashrc
echo "Updating .bashrc..."
cat <<EOT >> $HOME/.bashrc

if [ -f "${HOME}/.bash_aliases" ]; then
	source $HOME/.bash_aliases
fi

export EDITOR=/usr/bin/vim

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=10000
EOT

# Disable Baloo
echo "Disabling baloo..."
balooctl6 disable

# Cleanup
echo "Cleaning up..."
rm -rf $HOME/tmp_restore
unset BACKUP_FILE
unset FILES
unset FOLDERS
unset SOURCE

# We're done
echo "Done..."
echo ""

# Last thing we do...
read -p "- Reboot? [y/N]: " REBOOT
if [ "${REBOOT,,}" = "y" ]; then
    echo ""
    read -p "Save and close any open applications, then press any key..."
    reboot
fi
