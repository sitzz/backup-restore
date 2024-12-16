#!/bin/bash

# Set runtime vars
SOURCE="${HOME}/tmp_restore"

# Restore from backup file
read -p "- Please enter backup file name: " BACKUP_FILE
echo " ### Unzipping backup file $BACKUP_FILE ###"
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: unable to locate file $BACKUP_FILE"
    exit 1
fi
mkdir $SOURCE
unzip -d $SOURCE $BACKUP_FILE

# Restore files
echo "### Configs, dot-files, and misc. files ###"

FILES=".bash_aliases .gitconfig .gitconfig-github .gitconfig-gitlab .terraformrc backup.sh TDCRootCA.crt"
for file in $FILES
do
    if [ -n "$(ls -A ${SOURCE}/${file})" ];then
        echo "... Moving $file"
        mv -f $SOURCE/$file $HOME
    fi
done

# Restore folders
echo "### Folders ###"
FOLDERS=".aws .ssh .vpn code Desktop Documents Downloads Music Pictures Terraform"
for folder in $FOLDERS
do
    if [ -n "$(ls -A ${SOURCE}/${folder})" ]; then
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
echo "Installing from Arch packages..."
sudo pacman --noconfirm -S aws-cli aws-vault base-devel dbeaver fakeroot docker docker-buildx docker-compose k9s kubectl mousepad nodejs npm obsidian pipx python-pytest python-ruff python-uv screen unzip vim yay zip

# Install from aur
mkdir -p $HOME/.ICAClient/cache
# Why down here? Because some trusted keys are imported above
echo "Installing from aur..."
yay -S --sudoloop --noconfirm 1password aws-session-manager-plugin icaclient postman-bin pycharm-community-jre rider slack-desktop sublime-text-4 teams-for-linux webstorm webstorm-jre

# Add user to docker group
echo "Adding $USER to group 'docker'..."
sudo usermod -aG docker $USER

# Install NVM
echo "Installing nvm..."
git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm
$HOME/.nvm/install.sh

# Add loading of .bash_aliases to .bashrc
echo "Updating .bashrc"
cat <<EOT >> $HOME/.bashrc

if [ -f "${HOME}/.bash_aliases" ]; then
	source $HOME/.bash_aliases
fi

export EDITOR=/usr/bin/vim
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

# Last thing we do...
read -p "- Reboot? [y/N]: " REBOOT
if [ $REBOOT == 'y' ]; then
    echo ""
    read -p "Save and close any open applications, then press any key..."
    reboot
fi
