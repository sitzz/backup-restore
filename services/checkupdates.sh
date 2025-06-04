#!/bin/bash

# Checking official repository updates
official_updates=$(checkupdates | wc -l)

# Checking AUR updates using yay
aur_updates=$(yay -Qua | wc -l)

# Calculating total number of updates
total_updates=$((official_updates + aur_updates))

if [ $total_updates -gt 0 ]; then
    notify-send -a "Update Checker" "There are $total_updates updates available! ($official_updates official, $aur_updates AUR)"
# Uncomment next 2 lines if you want to be notified even when there are no updates.
#else
#    notify-send -a "Update Checker" "No updates available..."
fi

