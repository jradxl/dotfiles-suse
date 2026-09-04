#!/bin/bash

#VERSION: 20260904a

echo "RUN-ONCE Started..."

check-pixi() {
	#NOTE: Not on $PATH while running
	echo "    CHECKING FOR PIXI"
	if [[ ! -x "$HOME/.pixi/bin/pixi" ]]; then
		echo "    INstalling PIXI"
		if [[ -x "$HOME/.local/share/chezmoi/scripts/install-pixi.sh" ]]; then
		    "$HOME/.local/share/chezmoi/scripts/install-pixi.sh"
		fi
	else
		echo "    PIXI already installed. Trying to upgrade..."
		echo -n ""
		"$HOME"/.pixi/bin/pixi self-update
	fi
}

check-flatpak() {
	echo "    CHECKING FOR FLATPAK Updates"	
	if [[ -x "/usr/bin/flatpak" ]]; then
		echo "    Updating flatpaks, if any. May ask for sudo password."
		flatpak update
    else
		echo "    Flatpak not installed"
    fi
}

check-pixi
check-flatpak

echo "RUN-ONCE Finished."
exit 0

