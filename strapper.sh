#!/bin/bash


USER_DIR="$(getent passwd $SUDO_USER | cut -d: -f6)"
HOMEBREW_FOLDER="${USER_DIR}/homebrew"

check_is_deck() {
  UNAME="$(uname -a)"
  if [[ $UNAME =~ "neptune" ]] || [[ $UNAME =~ "jupiter" ]]; then
    echo "Running on Steam Deck"
    IS_DECK=TRUE
  else
    echo "Not running on a Steam Deck"
    IS_DECK=FALSE
  fi
}

disable_readonly_fs() {
  echo "$PASS" | sudo -E -S -k "steamos-readonly disable"
}

enable_readonly_fs() {
  echo "$PASS" | sudo -E -S -k "steamos-readonly enable"
}

init_pacman() {
  echo "$PASS" | sudo -E -S -k "sudo pacman-key --init"
  echo "$PASS" | sudo -E -S -k "pacman-key --populate archlinux"
  if [ $IS_DECK == TRUE ]; then
    echo "$PASS" | sudo -E -S -k "pacman-key --populate holo"
    echo "$PASS" | sudo -E -S -k "steamos-devmode enable"
    echo "$PASS" | sudo -E -S -k "steamos-unminimize"
  fi
  echo "$PASS" | sudo -E -S -k "pacman --sync --noconfirm glibc linux-api-headers"
}

blackarch_strap() {
  echo "Not yet implemented"
}

# if a password was set by decky, this will run when the program closes
temp_pass_cleanup() {
  echo $PASS | sudo -S -k passwd -d deck
}

# removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

# check if JQ is installed
check_jq() {
  if ! command -v jq &> /dev/null
  then
    echo "JQ could not be found, please install it"
    echo "Info on how to install it can be found at https://stedolan.github.io/jq/download/"
    exit 1
  fi
}

# check if github.com is reachable
check_online() {
  if ! curl -Is https://github.com | head -1 | grep 200 > /dev/null
  then
    echo "Github appears to be unreachable, you may not be connected to the internet"
    exit 1
  fi
}

permissions_prompt() {
# if the script is not root yet, get the password and rerun as root
if (( $EUID != 0 )); then
    PASS_STATUS=$(passwd -S deck 2> /dev/null)
    if [ "$PASS_STATUS" = "" ]; then
        echo "Deck user not found. Continuing anyway, as it probably just means user is on a non-steamos system."
    fi

    if [ "${PASS_STATUS:5:2}" = "NP" ]; then # if no password is set
        if ( zen_nospam --title="BlackArch Install Tool" --width=300 --height=200 --question --text="You appear to have not set an admin password.\nWe can still install by temporarily setting your password to 'blackarch' and continuing, then removing it when the installer finishes\nAre you okay with that?" ); then
            yes "blackarch" | passwd deck # set password to blackarch
            trap temp_pass_cleanup EXIT # make sure that password is removed when application closes
            PASS="blackarch"
        else exit 1; fi
    else
        # get password
        FINISHED="false"
        while [ "$FINISHED" != "true" ]; do
            PASS=$(zen_nospam --title="BlackArch Install Tool" --width=300 --height=100 --entry --hide-text --text="Enter your sudo/admin password")
            if [[ $? -eq 1 ]] || [[ $? -eq 5 ]]; then
                exit 1
            fi
            if ( echo "$PASS" | sudo -S -k true ); then
                FINISHED="true"
            else
                zen_nospam --title="BlackArch Install Tool" --width=150 --height=40 --info --text "Incorrect Password"
            fi
        done
    fi
fi
}

present_options() {
  OPTION=$(zen_nospam --title="BlackArch Install Tool" --width=750 --height=400 --list --radiolist --text "Select Option:" --hide-header --column "Buttons" --column "Choice" --column "Info" \
  TRUE "Disable read-only filesystem" "Unlocks file-system" \
  FALSE "Strap BlackArch" "Experimental/Untested" \
  FALSE "Strap BlackArch and install brew" "Straps BlackArch and installs brew to allow for local gcc compilation" \
  FALSE "Strap BlackArch, install brew and go" "Straps BlackArch, installs brew, sets up go within brew" \
  FALSE "Strap BlackArch; install brew, go, and wifi tools" "All of the above, but with aircrack and bettercap" \
  FALSE "Enable read-only filesystem" "Locks file-system" \
  FALSE "Reinitialize pacman" "(Untested and experimental, for after system update)" )
}

main() {
check_online
check_jq
check_is_deck
permissions_prompt
present_options
case $OPTION in
  "Disable read-only filesystem")
    echo "Disabling read-only fs"
    if [ $IS_DECK == TRUE ]; then
      disable_readonly_fs
    else
      echo "Not running on a Steam Deck, this likely is pointless and won't be attempted"
    fi
      ;;

  "Strap BlackArch")
    echo "Strapping"
    if [ $IS_DECK == TRUE ]; then
      disable_readonly_fs
      init_pacman
    else
      echo "Not running on a Steam Deck, parts of this are likely pointless and won't be attempted"
    fi
    blackarch_strap
      ;;

  "Strap BlackArch and install brew")
    echo "Strapping+"
    if [ $IS_DECK == TRUE ]; then
      disable_readonly_fs
      init_pacman
    else
      echo "Not running on a Steam Deck, parts of this are likely pointless and won't be attempted"
    fi
    blackarch_strap
      ;;

  "Strap BlackArch, install brew and go")
    echo "Strapping++"
    if [ $IS_DECK == TRUE ]; then
      disable_readonly_fs
      init_pacman
    else
      echo "Not running on a Steam Deck, parts of this are likely pointless and won't be attempted"
    fi
    blackarch_strap

      ;;

  "Strap BlackArch; install brew, go, and wifi tools")
    echo "Strapping+++"
    if [ $IS_DECK == TRUE ]; then
      disable_readonly_fs
      init_pacman
    else
      echo "Not running on a Steam Deck, parts of this are likely pointless and won't be attempted"
    fi
    blackarch_strap

      ;;

  "Enable read-only filesystem")
    echo "Re-enabling read-only filesystem"
    if [ $IS_DECK == TRUE ]; then
      enable_readonly_fs
    else
      echo "Not running on a Steam Deck, this likely is pointless and won't be attempted"
    fi
      ;;

  "Reinitialize pacman")
    echo "HIGHLY EXPERIMENTAL"
    init_pacman
      ;;

    *)
      echo "u wot m8"
        ;;
esac

}

main
