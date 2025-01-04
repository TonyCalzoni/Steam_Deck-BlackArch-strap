#!/bin/bash

# if a password was set by decky, this will run when the program closes
temp_pass_cleanup() {
  echo $PASS | sudo -S -k passwd -d deck
}

# removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

# check if JQ is installed
if ! command -v jq &> /dev/null
then
    echo "JQ could not be found, please install it"
    echo "Info on how to install it can be found at https://stedolan.github.io/jq/download/"
    exit 1
fi

# check if github.com is reachable
if ! curl -Is https://github.com | head -1 | grep 200 > /dev/null
then
    echo "Github appears to be unreachable, you may not be connected to the internet"
    exit 1
fi

# if the script is not root yet, get the password and rerun as root
if (( $EUID != 0 )); then
    PASS_STATUS=$(passwd -S deck 2> /dev/null)
    if [ "$PASS_STATUS" = "" ]; then
        echo "Deck user not found. Continuing anyway, as it probably just means user is on a non-steamos system."
    fi

    if [ "${PASS_STATUS:5:2}" = "NP" ]; then # if no password is set
        if ( zen_nospam --title="BlackArch Strapper" --width=300 --height=200 --question --text="You appear to have not set an admin password.\nWe can still install by temporarily setting your password to 'Decky!' and continuing, then removing it when the installer finishes\nAre you okay with that?" ); then
            yes "Decky!" | passwd deck # set password to Decky!
            trap temp_pass_cleanup EXIT # make sure that password is removed when application closes
            PASS="Decky!"
        else exit 1; fi
    else
        # get password
        FINISHED="false"
        while [ "$FINISHED" != "true" ]; do
            PASS=$(zen_nospam --title="BlackArch Strapper" --width=300 --height=100 --entry --hide-text --text="Enter your sudo/admin password")
            if [[ $? -eq 1 ]] || [[ $? -eq 5 ]]; then
                exit 1
            fi
            if ( echo "$PASS" | sudo -S -k true ); then
                FINISHED="true"
            else
                zen_nospam --title="BlackArch Strapper" --width=150 --height=40 --info --text "Incorrect Password"
            fi
        done
    fi

    if ! [ $USER = "deck" ]; then
        zen_nospam --title="BlackArch Strapper" --width=300 --height=100 --warning --text "You appear to not be on a deck.\nThis should still mostly work, but you may not get full functionality."
    fi
    
    echo "$PASS" | sudo -E -S -k bash "$0" "$@" # rerun script as root
    exit 1
fi

# all code below should be run as root
USER_DIR="$(getent passwd $SUDO_USER | cut -d: -f6)"
HOMEBREW_FOLDER="${USER_DIR}/homebrew"

(
echo "Number" ; echo "# Disabling Read-Only file system" ;

echo "Number" ; echo "# Setting up pacman" ;

echo "Number" ; echo "# Retrieving base dependencies from Arch Repository" ;

echo "Number" ; echo "# Setting up brew" ;

echo "Number" ; echo "# Setting up yay" ;

echo "Number" ; echo "# Setting up blackarch-keyring" ;

echo "Number" ; echo "# " ;


# this (retroactively) fixes a bug where users who ran the installer would have homebrew owned by root instead of their user
# will likely be removed at some point in the future
if [ "$SUDO_USER" =  "deck" ]; then
  sudo chown -R deck:deck "${HOMEBREW_FOLDER}"
fi

echo "100" ; echo "# Install finished, installer can now be closed";
) |
zen_nospam --progress \
  --title="BlackArch Installer" \
  --width=300 --height=100 \
  --text="Installing..." \
  --percentage=0 \
  --no-cancel # not actually sure how to make the cancel work properly, so it's just not there unless someone else can figure it out

if [ "$?" = -1 ] ; then
        zen_nospam --title="BlackArch Installer" --width=150 --height=70 --error --text="Download interrupted."
fi
