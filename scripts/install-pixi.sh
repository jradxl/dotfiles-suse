#!/bin/bash

#wget -O "$HOME/scripts/install.sh" https://raw.githubusercontent.com/prefix-dev/pixi/refs/heads/main/install/install.sh
wget -qO- https://raw.githubusercontent.com/prefix-dev/pixi/refs/heads/main/install/install.sh | PIXI_NO_PATH_UPDATE=1 bash

echo ""
echo "PIXI installed: Ensure PATH is set in .bashrc"
echo ""
exit 0

