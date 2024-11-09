# Set runtime vars
SOURCE="${HOME}/tmp_restore"

# Update system and install required packages
echo "Updating system and installing packages..."
sudo pacman --noconfirm -Syyu
sudo pacman --noconfirm -S base-devel fakeroot docker docker-compose unzip vim yay zip

# Add user to docker group
echo "Adding $USER to group 'docker'"
sudo usermod -aG docker $USER

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

# Cleanup
echo "Cleaning up..."
rm -rf $HOME/tmp_restore
unset BACKUP_FILE

# Install from aur
# Why down here? Because some trusted keys are imported above
echo "Installing from aur"
yay -S --sudoloop --noconfirm 1password pycharm-community-jre slack-desktop sublime-text-4 webstorm webstorm-jre

# Last thing we do...
read -p "- Reboot? [y/N]: " REBOOT
if [ $REBOOT == 'y' ]; then
	reboot
fi
