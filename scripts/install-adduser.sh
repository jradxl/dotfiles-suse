#!/bin/bash

echo "Adduser Installer"

if [[ -f /usr/local/bin/adduser ]]; then
	echo "adduser is already installed in /usr/local/bin"
else
	echo "Installing adduser to /usr/local/bin"
	cat <<-'EOF' > /usr/local/bin/adduser
		#!/bin/bash

		#
		# Adapted from https://dev.to/amaraiheanacho/user-creation-in-bash-script-1617
		#              https://github.com/Iheanacho-ai/User-creation-script/blob/main/create_users.sh
		#

		# Check if the current user is sudo, exit if it's not the superuser  
		if [ "$EUID" -ne 0 ]; then
		  echo "Please run as root"
		  exit 1
		fi

		## Check if the file was passed into the script
		#if [ -z "$1" ]; then 
		#    echo "Please pass the file parameter"
		#    exit 1
		#fi

		# Define the file paths for the logfile, and the password file
		#INPUT_FILE="$1"

		LOG_FILE="/var/log/user_management.log"

		PASSWORD_FILE="/root/user_passwords.csv"

		# Generate logfiles and password files and grant the user the permissions to edit the password file
		touch "$LOG_FILE"

		#mkdir -p /var/secure
		#chmod 700 /var/secure
		touch "$PASSWORD_FILE"
		chmod 600 "$PASSWORD_FILE"

		# Generate logs and passwords 
		log_message() {
			echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
		}

		generate_passwordY() {
			openssl rand -base64 12
		}

		if [[ -z "$1" ]]; then
			echo "Usage: adduser <user> <optional comma delimited additional group in quotes>"
			exit 0
		else
			username="$1"
			echo "Processing $username"
		fi

		# Check if the personal group exists, create one if it doesn't
		if ! getent group "$username" &>/dev/null; then
			echo "Group $username does not exist, adding it now"
			groupadd "$username"
			log_message "Created personal group $username"
		else
			message="Group $username already exists"
			echo "$message"
			log_message "$message"
		fi 

		# Check if the user exists
		if id -u "$username" &>/dev/null; then
			message="User $username already exists"
			echo "$message"
			log_message "$message"
		else
			# Create a new user with the created group if the user does not exist
			useradd -m -g $username -s /bin/bash "$username"
			message="User $username does not exist, adding it now"
			echo "$message"
			log_message "$message"
		fi

		# Check if the groups were specified
		if [ -z "$2" ]; then
			message="No additional group given"
			echo "$message"
			log_message "$message"
		else
			message="Processing additional group(s)"
			groups="$2"
			echo "$message"
			log_message "$message"

			# Read through the groups saved in the groups variable created earlier and split each group by ','
			IFS=',' read -r -a group_array <<< "$groups"

			# Loop through the groups 
			for group in "${group_array[@]}"; do
				# Remove the trailing and leading whitespaces and save each group to the group variable
				group="$(echo $group | xargs)" # Remove leading/trailing whitespace

				# Check if the group already exists
				if ! getent group "$group" &>/dev/null; then
				    # If the group does not exist, create a new group
				    groupadd "$group"
				    message="Created group $group."
		   	  		echo "$message"
					log_message "$message"
				fi

				# Add the user to each group
				usermod -aG "$group" "$username"
				message="Added user $username to group $group."
		   	  	echo "$message"
				log_message "$message"
			done
		fi

		echo "Do you want to set or update the password?"
		select yn in "Yes" "No"; do
			case "$yn" in
				Yes )
					echo "Setting a password"
					# Create and set a user password
					password="$(generate_passwordY)"
					echo "$username:$password" | chpasswd
					echo "User $username has following password: $password" 
					# Save user and password to a file
		 			echo "$username,$password" >> "$PASSWORD_FILE"
					echo "Also saved to $PASSWORD_FILE Remember to remove file "
					break
					;;
				No )
					echo "No password applied"
					break
					;;
			esac
		done

		log_message "User created successfully"
		echo "User has been created and added optionally had groups added"

		exit 0
EOF

fi

if [[ -f /usr/local/bin/adduser ]]; then
	chmod +x /usr/local/bin/adduser
fi

exit 0

