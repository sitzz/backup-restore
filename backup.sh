#!/bin/bash

# are we sure about this?
# set -e

# Set runtime vars
DESTINATION="${HOME}/backup_`date +"%Y-%m-%dT%H:%M:%S"`.zip"
ITEMS="files.txt folders.txt"
FILES=$(cat files.txt)
FOLDERS=$(cat folders.txt)
ZIPAPPEND=""
ZIPARGS=""
ZIPCMD=""

# Prompts for gpg passphrase
read -p "- Please enter GnuPGP key passphrase: " -s GPG_PASSPHRASE

# Start the backup
echo "Will backup to file ${DESTINATION}"

# Backup of files
echo "Taking backup of files..."
for file in $FILES
do
    if [[ -e "${HOME}/${file}" ]]; then
        echo "... Adding $file"
        ITEMS="${ITEMS} ${HOME}/${file}"
    fi
done

# Backup common folder
echo "Taking backup of folders..."
for folder in $FOLDERS
do
    if [[ -d "${HOME}/${folder}" ]]; then
        echo "... Adding $folder"
        ITEMS="${ITEMS} ${HOME}/${folder}"
    fi
done

# Backup gpg keys
echo "Taking backup of GnuPG keys..."

if [ -n "$GPG_PASSPHRASE" ]; then
    echo "... Backing up GPG keys"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export --armor --output /tmp/public.asc
    ITEMS="${ITEMS} /tmp/public.asc"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-keys --output /tmp/secret.gpg
    ITEMS="${ITEMS} /tmp/secret.gpg"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-subkeys --output /tmp/secret_sub.gpg
    ITEMS="${ITEMS} /tmp/secret_sub.gpg"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-ownertrust > /tmp/trust.gpg
    ITEMS="${ITEMS} /tmp/trust.gpg"
else
    echo "!!! Skipping due to missing passphrase"
fi

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
        ZIPCMD=`which zip`
        ZIPARGS="-qr5"
        ZIPAPPEND="-x */.terraform */.venv */node_modules"
    fi
fi

if [ -z "$ZIPCMD" ]; then
    echo "ERROR: no archiving application found, currently supports '7z' and 'zip'"
    exit 1
fi

echo "Creating zip archive..."
$ZIPCMD $ZIPARGS $DESTINATION $ITEMS $ZIPAPPEND

# Clean up
echo "Cleaning up..."
if [ -n "$GPG_PASSPHRASE" ]; then
    rm /tmp/public.asc
    rm /tmp/secret.gpg
    rm /tmp/secret_sub.gpg
    rm /tmp/trust.gpg
fi
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
