#!/bin/bash

echo "Undoing changes to ~/.zshrc..."
# Remove any line mentioning .capt from .zshrc
if [ -f ${HOME}/.zshrc ]; then
	sed -i.bak '/\.capt/d' ${HOME}/.zshrc
	rm -f ${HOME}/.zshrc.bak
fi

echo "Undoing changes to ~/.bashrc..."
# Remove any line mentioning .capt from .bashrc
if [ -f ${HOME}/.bashrc ]; then
	sed -i.bak '/\.capt/d' ${HOME}/.bashrc
	rm -f ${HOME}/.bashrc.bak
fi

FISHRC=${HOME}/.config/fish/config.fish
if [ -f $FISHRC ]; then
	echo "Undoing changes to ~/.config/fish/config.fish..."
	# Remove any line mentioning .capt from fish config
	sed -i.bak '/\.capt/d' $FISHRC
	rm -f ${FISHRC}.bak
fi

echo "Removing capt installation..."
rm -rf ${HOME}/.capt

echo "Done uninstalling capt. Restart your shell to apply changes."
