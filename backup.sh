#!/bin/bash

# are we sure about this?
# set -e

# Check if zip is installed
which zip > /dev/null 2>&1
if [ $? -gt 0 ];then
    echo "ERROR: zip doesn't seem to be installed on system"
    exit 1
fi

# Create a folder for the backup
cd $HOME
DESTINATION="${HOME}/backup_`date +"%Y-%m-%dT%H:%M:%S"`.zip"
echo "Will backup to file ${DESTINATION}"

# Backup of configs and other dot files
echo "### Configs and dot-files ###"

FILES=".bash_aliases .gitconfig .gitconfig-github .gitconfig-gitlab .terraformrc backup.sh TDCRootCA.crt"
for file in $FILES
do
    if [ -n "$(ls -A ${HOME}/${file})" ];then
        echo "... Backing up $file"
        zip -qr5uj $DESTINATION $HOME/$file
    fi
done

# Backup gpg keys
echo "### GnuPG keys ###"

read -p "- Please enter GnuPGP key passphrase: " -s GPG_PASSPHRASE
echo ""
echo "... Backing up GPG keys"
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export --armor --output /tmp/public.asc
zip -qr5uj $DESTINATION /tmp/public.asc
rm /tmp/public.asc
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-keys --output /tmp/secret.gpg
zip -qr5uj $DESTINATION /tmp/secret.gpg
rm /tmp/secret.gpg
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-subkeys --output /tmp/secret_sub.gpg
zip -qr5uj $DESTINATION /tmp/secret_sub.gpg
rm /tmp/secret_sub.gpg
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-ownertrust > /tmp/trust.gpg
zip -qr5uj $DESTINATION /tmp/trust.gpg
rm /tmp/trust.gpg
unset GPG_PASSPHRASE

# Backup common folder
echo "### Common folders ###"

FOLDERS=".aws .ssh .vpn Documents Downloads Music Pictures Terraform"
for folder in $FOLDERS
do
    if [ -n "$(ls -A ${HOME}/${folder})" ]; then
        echo "... Backing up $folder"
        zip -qr5u $DESTINATION $folder
    fi
done

# Backup code directory
echo "### Code folder ###"

# We need to remove any terraform directories, python virtual invironments, node modules etc. - they take up too much space!
echo "... Removing .terraform, .venv, and node_modules folders in code folder"
find ./code -type d -name ".terraform" -exec /bin/rm -r {} \;
find ./code -type d -name ".venv" -exec /bin/rm -r {} \;
find ./code -type d -name "node_modules" -exec /bin/rm -r {} \;
echo "... Backing up code folder"
zip -qr5u $DESTINATION ./code

# We're done
echo "Done..."
