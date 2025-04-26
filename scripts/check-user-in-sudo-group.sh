#!/bin/bash

echo "Checking for SUDO group, and current user is a member"

getent group sudo &>/dev/null
if [[ $? -ne 0 ]]; then
	echo "Group sudo does not exist, adding it now"
	groupadd sudo
	echo "Created sudo group"
else
	echo "Group sudo already exists"
fi 

if [[ -z $1 ]]; then
    username=$USER
else
    username="$1"
fi

getent group sudo | grep -qw $username &>/dev/null
if [[ $? -ne 0 ]]; then
	echo "$username is not in sudo group"
else
	echo "$username is already in sudo group"
fi 
