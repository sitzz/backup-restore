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
echo "Installing packages..."
sudo pacman --noconfirm -S aws-cli aws-vault base-devel code dbeaver fakeroot docker docker-buildx docker-compose go k9s kubectl mousepad nodejs npm obsidian python-pipx python-pytest python-ruff python-uv screen vim yay

# Install from aur
# Why down here? Because some trusted keys might be imported from a backup above
echo "Installing from aur"
mkdir -p $HOME/.ICAClient/cache
yay -S --sudoloop --noconfirm 1password aws-session-manager-plugin icaclient postman-bin pycharm-community-jre slack-desktop sublime-text-4 teams-for-linux webstorm webstorm-jre

# Install NVM
echo "Installing nvm..."
git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm
$HOME/.nvm/install.sh

# Add user to docker group
echo "Adding $USER to group 'docker'..."
sudo usermod -aG docker $USER

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
