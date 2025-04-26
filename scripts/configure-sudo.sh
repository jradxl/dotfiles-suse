#!/bin/bash

echo "Configuring SUSE to use SUDO..."

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Trapped CTRL-C"
    exit 1
}

now=$(date +"%Y-%m-%d-%M-%S")
SUDOERS_FILE="/usr/etc/sudoers"
SUDOERS_FILE_OTHER="/etc/sudoers"
SUDOERS_NEW="/usr/etc/sudoers.new"
SUDOERS_BAK="/usr/etc/sudoers.bak.$now"
SUDOPATH="/usr/etc"
SUDOPATH_D="/usr/etc/sudoers.d"

sudo zypper in -y sudo sudo-policy-sudo-auth-self

getent group sudo &>/dev/null
if [[ $? -ne 0 ]]; then
	echo "Group sudo does not exist, adding it now"
	groupadd sudo
	echo "Created sudo group"
else
	echo "Group sudo already exists"
fi 

getent group sudo | grep -qw $USER &>/dev/null
if [[ $? -ne 0 ]]; then
	echo "$USER is not in sudo group, adding now"
    sudo usermod -a -G sudo $USER
    echo "Re-Access your account and re-run this script"
    exit 1
else
	echo "$USER is already in sudo group"
fi 

if [[ $(sudo ls "$SUDOPATH_D"/50-sudo-auth-self) ]]; then
    echo "Provided $SUDOPATH_D/50-sudo-auth-self has been installed.."
    sudo chmod 0440 "$SUDOPATH_D"/50-sudo-auth-self
else
    echo "ERROR: $SUDOPATH_D/50-sudo-auth-self has not been installed."
    exit 1
fi

echo ""
echo "WARNING: allowing SSH root login in case of sudo error..."
echo "WARNING: remember to remove if sudo works"
echo ""

sudo tee "/etc/ssh/sshd_config.d/allow-root.conf" > /dev/null <<-'EOF'
    PermitRootLogin yes
EOF

sudo systemctl restart sshd

sudo tee "$SUDOPATH_D/99-allow-sudo-extra" > /dev/null <<-'EOF'
    Defaults env_keep = "LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS XDG_SESSION_COOKIE XAUTHORITY DISPLAY"
EOF

sudo chmod 0440 "$SUDOPATH_D/99-allow-sudo-extra"

#Comment out these two lines in /usr/etc/sudoers
#Defaults targetpw   # ask for the password of the target user i.e. root
#ALL   ALL=(ALL) ALL   # WARNING! Only use this together with 'Defaults targetpw'!

if [[ -f "$SUDOERS_FILE" ]]; then
    echo "SUDOERS file found in /usr/etc/"
    echo "Making backup in case..."
    sudo cp "$SUDOERS_FILE" "$SUDOERS_BAK"
    sudo chmod 0440 "$SUDOERS_FILE"
else
    echo "SUDOERS file not found"
    exit 1
fi

if [[ -f "$SUDOERS_FILE_OTHER" ]]; then
    echo ""
    echo "WARNING: SUDOERS file found in $SUDOERS_FILE_OTHER"
    echo "Perhaps it should be removed"
    echo ""
fi

if [[ $(sudo grep '^Defaults targetpw' "$SUDOERS_FILE") ]]; then
    #echo "Found it 1"
    sudo cat "$SUDOERS_FILE" | sed 's/^Defaults targetpw/#&/' | sudo tee "$SUDOERS_NEW" > /dev/null
    sudo visudo -c -f "$SUDOERS_NEW" && sudo mv "$SUDOERS_NEW" "$SUDOERS_FILE"
fi

if [[ $(sudo grep '^ALL' "$SUDOERS_FILE") ]]; then
    #echo "Found it 2"
    sudo cat "$SUDOERS_FILE" | sed 's/^ALL/#&/' | sudo tee "$SUDOERS_NEW" > /dev/null
    sudo visudo -c -f "$SUDOERS_NEW" && sudo mv "$SUDOERS_NEW" "$SUDOERS_FILE"
fi

echo "VISUDO Parsing check..."
sudo visudo -c

echo ""
echo "Finished processing"
echo "WARNING: Ensure your user accounts have SUDO as an additional group"
echo "EXAMPLE: adduser john sudo"
exit 0

