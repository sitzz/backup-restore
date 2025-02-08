#!/bin/bash

set -e

# Set runtime vars
DESTINATION="${HOME}/backup_`date +"%Y-%m-%dT%H:%M:%S"`.zip"
ITEMS="include.txt"
INCLUDE=$(cat include.txt)
ZIPAPPEND=""
ZIPARGS=""
ZIPCMD=""

# Prompts for gpg passphrase
read -p "- Please enter GnuPGP key passphrase: " -s GPG_PASSPHRASE

# Start the backup
echo "Will backup to file ${DESTINATION}"

# Add files and folders to $ITEMS
echo "Taking backup of files..."
for path in $INCLUDE
do
    if [[ -f "${HOME}/${path}" ]]; then
        echo "... Adding file $path"
        ITEMS="${ITEMS} ${HOME}/${path}"
    fi
    if [[ -d "${HOME}/${path}" ]]; then
        echo "... Adding folder $path"
        ITEMS="${ITEMS} ${HOME}/${path}"
    fi
done

# Backup gpg keys
echo "Taking backup of gpg keys..."

if [ -n "$GPG_PASSPHRASE" ]; then
    echo "... Backing up secrets keys"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-keys --output /tmp/secret.gpg
    ITEMS="${ITEMS} /tmp/secret.gpg"
    echo "... Backing up secrets subkeys"
    gpg --batch --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" --export-options backup --export-secret-subkeys --output /tmp/secret_sub.gpg
    ITEMS="${ITEMS} /tmp/secret_sub.gpg"
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
#$ZIPCMD $ZIPARGS $DESTINATION $ITEMS $ZIPAPPEND

# Clean up
echo "Cleaning up..."
if [ -n "$GPG_PASSPHRASE" ]; then
    rm /tmp/secret.gpg
    rm /tmp/secret_sub.gpg
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
