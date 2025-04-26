#!/bin/bash

echo "Starting Initial Install of CHEZMOI...."

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

GITREPO1="https://github.com/jradxl/dotfiles-suse.git"
GITREPO2="git@github.com:jradxl/dotfiles-suse.git"

function ctrl_c() {
    echo "Trapped CTRL-C"
    exit 1
}

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
else
    echo "Cannot determine OS version"
    exit 1
fi

if [[ "$ID"=="opensuse-slowroll" || "$ID"="opensuse-tumbleweed" ]]; then
    echo "Good! Running on OpenSUSE"
else
    echo "Not rnning on OpenSUSE Tumbleweed or Slowroll"
    exit 1
fi

echo "Checking for Curl. May ask for superuser access."
if [[ $(command -v curl) ]]; then
    echo "Curl is present, continuing..."
else
    echo "Curl is NOT present, installing..."
    sudo zypper install -y curl
fi

echo "Checking for Wget. May ask for superuser access."
if [[ $(command -v wget) ]]; then
    echo "Wget is present, continuing..."
else
    echo "Wget is NOT present, installing..."
    sudo zypper install -y wget
fi

echo "Checking for Git. May ask for superuser access."
if [[ $(command -v git) ]]; then
    echo "Git is present, continuing..."
else
    echo "Git is NOT present, installing..."
    sudo zypper install -y git
fi

### CHEZMOI ###
if [[ $(command -v chezmoi ) ]]; then
    echo "Chezmoi already installed. Trying to upgrade..."
    chezmoi upgrade
else
    echo "Installing Chezmoi to ~/.local/bin to use existing PATHs" 
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin   
fi

if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
    echo "Chezmoi Dotfiles repo already exists."
else
    echo "Getting existing Dofiles-SUSE repo..."
    chezmoi init "$GITREPO1"
fi

chezmoi --version | awk '{print $1 " " $3}'

echo "Applying Chezmoi updates to the underlying files"
echo "CAREFUL: Do you want to force the application of Chezmoi updates?"
select yn in "Yes" "No"; do
    case $yn in
        Yes )
			echo "Appling Chezmod updates..."
			chezmoi apply --force
			break
			;;
        No )
			echo "Chezmod updates not applied..."
			break
			;;
    esac
done
echo "Finished Chezmoi updating..."

#Set up Github
git config --global user.email "jradxl@gmail.com"
git config --global user.email
git config --global user.name "John Radley"
git config --global user.name

if [[ -f "$HOME/.github.configured" ]]; then
    echo "Github Private Key setup OK"
else
    echo "Github Private Key NOT setup."
    echo "Install the Github Private Key and Y to continue?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) exit;;
        esac
    done
    touch "$HOME/.github.configured"
fi

echo "Test Github access. May ask for passphrase."
if [[ $(ssh github.com) == 1 ]]; then
    echo "Github access failed. Please fix and re-run this script."
    exit 1
fi

if [[ ! -f "$HOME/.chezmoi-pac" ]]; then
    echo "Update .chezmoi-pac when convenient."
    echo 'export CHEZMOI_GITHUB_ACCESS_TOKEN=""' > "$HOME/.chezmoi-pac"
fi

CURENTDIR=$(pwd)
CHEZMOISRC=$(chezmoi source-path)
#echo "$CHEZMOISRC"

if [[ -f "$HOME/.github.configured" ]]; then
    echo "Github ready... Attempting to change Chezmoi repo to git access"
    #NOT USED as opens new shell:  chezmoi cd
    cd "$CHEZMOISRC"
    #echo "Chezmoi Repo Path: <$(pwd)>"
    git remote set-url origin "$GITREPO2"
    #echo "GIT1: <$?>"
    echo "Confirmed New URL: $(git config --get remote.origin.url)"
    #echo "GIT2: <$?>"
    cd "$CURENTDIR"
fi

echo "Installation of Chezmoi completed."

### End Chezmoi ###
exit 0
