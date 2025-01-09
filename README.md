# Installation script that straps BlackArch on top of the Steam Deck running factory/official SteamOS

Dependency requirements: jq, zenity (Both are installed by default on SteamOS)

### WARNING: parts of this script will need to be run again after every system update due to the immutable nature of Valve's SteamOS

Initial testing on Steam Deck works. If you have wifi issues or are at the library, don't be afraid of the errors. It's network related and you can just run the script again, or execute it manually in the terminal

No need to run as root or with sudo, it properly prompts and elevates as needed, and has handling in case the default deck user password is not set

Has an option to include installing Go along with bettercap and some basic tooling, like john and hashcat  
Automatically adds /go/bin to path, and adds it to .bashrc for persistent path

The built-in wifi adapter doesn't support monitor mode out of the box, and external is recommended 
