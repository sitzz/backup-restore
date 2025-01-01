#!/bin/bash

# are we sure about this?
# set -e

# Set runtime vars
FILES=$(cat files.txt)
FOLDERS=$(cat folders.txt)
SOURCE="${HOME}/tmp_restore"

# Restore from backup file
read -p "- Please enter backup file name: " BACKUP_FILE
echo " Unzipping backup file $BACKUP_FILE"
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: unable to locate file $BACKUP_FILE"
    exit 1
fi
mkdir $SOURCE
unzip -d $SOURCE $BACKUP_FILE

echo "Installing packages required by script..."
sudo pacman --noconfirm -S unzip zip

# Restore files
echo "Restoring backup of files..."
for file in $FILES
do
    if [[ -e "${SOURCE}/${file}" ]]; then
        echo "... Moving $file"
        mv -f $SOURCE/$file $HOME
    fi
done

# Restore folders
echo "Restoring backup of folders..."
for folder in $FOLDERS
do
    if [[ -d "${SOURCE}/${folder}" ]]; then
        echo "... Moving $folder"
        mv -f $SOURCE/$folder $HOME
    fi
done

# Import GnuPG keys
echo "Importing gpg keys..."
gpg --import $HOME/tmp_restore/tmp/public.asc
gpg --import $HOME/tmp_restore/tmp/secret.gpg
gpg --import $HOME/tmp_restore/tmp/secret_sub.gpg
gpg --import $HOME/tmp_restore/tmp/trust.gpg
sudo pacman-key --updatedb
gpg --list-key
read -p "- Please enter key ID to update trust: " GPG_KEY_ID
gpg --edit-key $GPG_KEY_ID

# Update system and install required packages
echo "Updating system..."
sudo pacman --noconfirm -Syu
echo "Installing packages..."
sudo pacman --noconfirm -S aws-cli aws-vault base-devel dbeaver fakeroot docker docker-buildx docker-compose go k9s kubectl mousepad nodejs npm obsidian pipx python-pytest python-ruff python-uv screen vim yay

# Install from aur
# Why down here? Because some trusted keys might be imported from a backup above
echo "Installing from aur"
mkdir -p $HOME/.ICAClient/cache
yay -S --sudoloop --noconfirm 1password aws-session-manager-plugin icaclient postman-bin pycharm-community-jre slack-desktop sublime-text-4 teams-for-linux vscodium-bin webstorm webstorm-jre

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

export HISTCONTROL=ignoreboth:erasedups
EOT

# Configure aws-vault
# This is 100 % custom
echo "Setting up aws-vault..."
aws-vault add ent-root
aws-vault exec ent-sysdev-dev -- aws eks update-kubeconfig --name dev-k8s --alias sysdevdev
aws-vault exec ent-sysdev-prd -- aws eks update-kubeconfig --name prd-k8s --alias sysdevprd

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
if [ $REBOOT == 'y' ]; then
    echo ""
    read -p "Save and close any open applications, then press any key..."
    reboot
fi
