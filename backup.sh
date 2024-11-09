#!/bin/bash

# are we sure about this?
# set -e

# Set runtime vars
DESTINATION="${HOME}/backup_`date +"%Y-%m-%dT%H:%M:%S"`.zip"
ITEMS=""
ZIPAPPEND=""
ZIPARGS=""
ZIPCMD=""

cd $HOME
echo "Will backup to file ${HOME}/${DESTINATION}"

# Backup of configs and dot files
echo "### Configs, dot-files, and misc. files ###"

FILES=".bash_aliases .gitconfig .gitconfig-github .gitconfig-gitlab .terraformrc backup.sh TDCRootCA.crt"
for file in $FILES
do
    if [ -n "$(ls -A ${HOME}/${file})" ];then
        echo "... Adding $file"
        ITEMS="${ITEMS} ${file}"
    fi
done

# Backup common folder
echo "### Folders ###"

FOLDERS=".aws .ssh .vpn code Desktop Documents Downloads Music Pictures Terraform"
for folder in $FOLDERS
do
    if [ -n "$(ls -A ${HOME}/${folder})" ]; then
        echo "... Adding $folder"
        ITEMS="${ITEMS} ${folder}"
    fi
done

# Backup gpg keys
echo "### GnuPG keys ###"

read -p "- Please enter GnuPGP key passphrase: " -s GPG_PASSPHRASE
echo ""
echo "... Backing up GPG keys"
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export --armor --output /tmp/public.asc
ITEMS="${ITEMS} /tmp/public.asc"
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-keys --output /tmp/secret.gpg
ITEMS="${ITEMS} /tmp/secret.gpg"
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-subkeys --output /tmp/secret_sub.gpg
ITEMS="${ITEMS} /tmp/secret_sub.gpg"
gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-ownertrust > /tmp/trust.gpg
ITEMS="${ITEMS} /tmp/trust.gpg"

# Add files to zip archive
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ! Currently disabling 7z as it's a bit buggy, need to polish the implementation !
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# # Check for 7z (prefered)
# which 7z > /dev/null 2>&1
# if [ $? -eq 0 ];then
#     echo "Found 7z"
#     ZIPCMD=`which 7z`
#     ZIPARGS="a -mx5 -y -r"
#     ZIPAPPEND="-x!*/.terraform -x!*/.venv -x!*/node_modules"
# fi

# Fallback to zip
if [ -z "$ZIPCMD" ] ;then
    which zip > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "Found zip"
        ZIPCMD=`which zip`
        ZIPARGS="-qr5"
        ZIPAPPEND="-x */.terraform */.venv */node_modules"
    fi
fi

if [ -z "$ZIPCMD" ]; then
    echo "ERROR: no archiving application found, currently supports '7z' and 'zip'"
    exit 1
fi

echo "### Creating zip archive ###"
$ZIPCMD $ZIPARGS $DESTINATION $ITEMS $ZIPAPPEND

# Clean up
echo "### Cleaning up ###"
rm /tmp/public.asc
rm /tmp/secret.gpg
rm /tmp/secret_sub.gpg
rm /tmp/trust.gpg
unset DESTINATION
unset FOLDERS
unset FILES
unset GPG_PASSPHRASE
unset ITEMS
unset ZIPAPPEND
unset ZIPARGS
unset ZIPCMD

# We're done
echo "Done..."
