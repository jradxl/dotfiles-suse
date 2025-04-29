#!/bin/bash

echo "Configuring SUSE to use SUDO..."

# Example:
# su - root -c "$(pwd)/configure-sudo.sh undo"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Trapped CTRL-C"
    exit 1
}

if [ $(id -u) != 0 ]
then
    echo "This script needs to be run as root: ie sudo"
    exit 1
fi

ARG1="$(tr [A-Z] [a-z] <<< "$1")"
echo "<$ARG1>"

if [[ "$ARG1" == "undo" ]]; then
    echo "Undoing the SUDO Setup..."  
    echo "WARNING: Be sure you know the root password..."

    echo "CAREFUL: Do you want to quit?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes )
			    echo "Quiting..."
                exit 1
			    break
			    ;;
            No )
			    echo "Continuing to undo SUDO..."
			    break
			    ;;
        esac
    done
fi

if [[ "$ARG1" == "undo" ]]; then
    zypper remove -y sudo-policy-sudo-auth-self
    if [[ -f /usr/etc/sudoers.d/50-sudo-auth-self ]]; then
        echo "ERROR: File 50-sudo-auth-self still remains..."
        exit 1
    fi

    if [[ -f /usr/etc/sudoers.d/99-allow-sudo-extra ]]; then
        echo "Removing 99-allow-sudo-extra"
        rm -rf /usr/etc/sudoers.d/99-allow-sudo-extra
    fi

    if [[ -f /etc/sudoers ]]; then
        echo "Removing /etc/sudoers "
        rm -rf /etc/sudoers
    fi

    echo "Undoing SUDO completed."
    exit
fi

echo "Starting to convert to SUDO use..."

SUDOERS_FILE="/usr/etc/sudoers"
SUDOERS_PATH="/usr/etc"
SUDOERS_PATH_DIR="/usr/etc/sudoers.d"
SUDOERS_PATH_OTHER="/etc"
SUDOERS_PATH_OTHER_DIR="/etc/sudoers.d"
SUDOERS_FILE_OTHER="/etc/sudoers"
SUDOERS_FILE_OTHER_NEW="/etc/sudoers.new"

sudo zypper in -y sudo sudo-policy-sudo-auth-self

getent group sudo &>/dev/null
if [[ "$?" != 0 ]]; then
	echo "Group sudo does not exist, adding it now"
	groupadd sudo
	echo "Created sudo group"
    echo "WARNING: There will be no Users in group Sudo"
    exit 1
else
	echo "Group sudo already exists"
    echo "Sudo Members: $(grep sudo: /etc/group)"
    echo "Be sure this is correct"
fi 

if [[ $(sudo ls "$SUDOERS_PATH_DIR"/50-sudo-auth-self) ]]; then
    echo "Provided $SUDOERS_PATH_DIR/50-sudo-auth-self has been installed.."
    chmod 0440 "$SUDOERS_PATH_DIR"/50-sudo-auth-self
else
    echo "ERROR: $SUDOERS_PATH_DIR/50-sudo-auth-self has not been installed."
    exit 1
fi

echo ""
echo "WARNING: allowing SSH root login in case of sudo error..."
echo "WARNING: remember to remove if sudo works"
echo ""

tee "/etc/ssh/sshd_config.d/allow-root.conf" > /dev/null <<-'EOF'
    PermitRootLogin yes
EOF

systemctl restart sshd

tee "$SUDOERS_PATH_OTHER_DIR/99-allow-sudo-extra" > /dev/null <<-'EOF'
Defaults env_keep = "LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS XDG_SESSION_COOKIE XAUTHORITY DISPLAY"
EOF

chmod 0440 "$SUDOERS_PATH_OTHER_DIR/99-allow-sudo-extra"

#Copy /usr/etc/sudoers to /etc/sudoers and...
#Comment out these two lines in /etc/sudoers
#Defaults targetpw   # ask for the password of the target user i.e. root
#ALL   ALL=(ALL) ALL   # WARNING! Only use this together with 'Defaults targetpw'!

if [[ -f "$SUDOERS_FILE" ]]; then
    echo "SUDOERS_FILE found in /usr/etc/"
    echo "Copying to /etc"
    cp "$SUDOERS_FILE" "$SUDOERS_FILE_OTHER"
else
    echo "SUDOERS_FILE not found"
    exit 1
fi

if [[ $(sudo grep '^Defaults targetpw' "$SUDOERS_FILE_OTHER") ]]; then
    #echo "Found it 1"
    cat "$SUDOERS_FILE_OTHER" | sed 's/^Defaults targetpw/#&/' | tee "$SUDOERS_FILE_OTHER_NEW" > /dev/null
    visudo -c -f "$SUDOERS_FILE_OTHER_NEW" &&  mv "$SUDOERS_FILE_OTHER_NEW" "$SUDOERS_FILE_OTHER"
fi

if [[ $(sudo grep '^ALL' "$SUDOERS_FILE_OTHER") ]]; then
    #echo "Found it 2"
    cat "$SUDOERS_FILE_OTHER" | sed 's/^ALL/#&/' | tee "$SUDOERS_FILE_OTHER_NEW" > /dev/null
    visudo -c -f "$SUDOERS_FILE_OTHER_NEW" && mv "$SUDOERS_FILE_OTHER_NEW" "$SUDOERS_FILE_OTHER"
fi

chmod 0440 "$SUDOERS_FILE_OTHER"
echo "VISUDO Parsing check..."
visudo -c

echo ""
echo "Finished processing"
echo "WARNING: Ensure your user accounts have SUDO as an additional group"
echo "EXAMPLE: adduser john sudo"
exit 0

