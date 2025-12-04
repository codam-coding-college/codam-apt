#!/bin/bash

echo "Creating neccesary directories..."
mkdir -p ${HOME}/.capt/root
mkdir -p ${HOME}/.capt/debs_temp

echo "Creating installer script..."
cat <<"EOF" >${HOME}/.capt/capt
#!/bin/bash

GREEN_COLOR="\033[1;32m"
YELLOW_COLOR="\033[1;33m"
BLUE_COLOR="\033[0;34m"
NO_COLOR="\033[0m"

cd ${HOME}/.capt/debs_temp
rm -rf *.deb

print_error() {
	local RED_COLOR="\033[1;31m"
	echo -e "${RED_COLOR}ERROR: ${NO_COLOR}$1"
}

does_package_exist() {
	if [ ! $1 ]; then
		print_error "Missing the package name..."
		exit 1
	fi
	local name="$1"
	local packages_list=$(apt-cache pkgnames "$name" | grep -x "$name" | wc -l)
	if [ "$packages_list" -eq 0 ]; then 
		print_error "No result found..."
		exit 1
	elif [ "$packages_list" -gt 1 ]; then
		print_error "Multiple packages match this name"
		apt-cache pkgnames "$name" | grep -x "$name"
		exit 1
	fi
}

search_package() {
	if [ ! $1 ]; then
		print_error "Missing the search parameter..."
		exit 1
	fi
	echo "Searching for the package..."
	local search_results=$(apt-cache search --names-only $1)
	local nb_packages=$(echo "$search_results" | wc -l)
	if [ "$nb_packages" -eq 0 ]; then
		print_error "No result found..."
		exit 1
	fi
	echo "$search_results" | while read pkg description; do
		echo -e "${GREEN_COLOR}${pkg}${NO_COLOR} ${description}"
	done
	echo -e "\n${YELLOW_COLOR}Found ${nb_packages} packages${NO_COLOR}"
}

if [[ $1 == "install" ]]; then
	if [ ! $2 ]; then
		print_error "Missing package name..."
		exit 1
	fi
	does_package_exist $2
	echo "Downloading prerequisites..."
	apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $2 | grep "^\w" | sort -u)
	echo "Installing..."
	find . -iname "*.deb" -type f -exec dpkg -x {} ${HOME}/.capt/root \;
	echo "Finished installing, removing temp files..."
	rm -rf *.deb
	echo "Done"
elif [[ $1 == "search" ]]; then
	if [ ! $2 ]; then
		print_error "Missing the search parameter..."
		exit 1
	fi
	search_package $2
else
	echo "Capt only supports \`capt install and capt search\`"
fi

EOF

echo "Setting executable bit on \`capt\` executable..."
chmod +x ${HOME}/.capt/capt

echo "Modifying ~/.zshrc for use with capt..."
cat <<EOF >>${HOME}/.zshrc
export LD_LIBRARY_PATH=${HOME}/.capt/root/lib/x86_64-linux-gnu:${HOME}/.capt/root/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH
export PATH=${HOME}/.capt:${HOME}/.capt/root/usr/local/sbin:${HOME}/.capt/root/usr/local/bin:${HOME}/.capt/root/usr/sbin:${HOME}/.capt/root/usr/bin:${HOME}/.capt/root/sbin:${HOME}/.capt/root/bin:${HOME}/.capt/root/usr/games:${HOME}/.capt/root/usr/local/games:${HOME}/.capt/snap/bin:\$PATH

EOF

echo "Modifying ~/.bashrc for use with capt..."
cat <<EOF >>${HOME}/.bashrc
export LD_LIBRARY_PATH=${HOME}/.capt/root/lib/x86_64-linux-gnu:${HOME}/.capt/root/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH
export PATH=${HOME}/.capt:${HOME}/.capt/root/usr/local/sbin:${HOME}/.capt/root/usr/local/bin:${HOME}/.capt/root/usr/sbin:${HOME}/.capt/root/usr/bin:${HOME}/.capt/root/sbin:${HOME}/.capt/root/bin:${HOME}/.capt/root/usr/games:${HOME}/.capt/root/usr/local/games:${HOME}/.capt/snap/bin:\$PATH

EOF

FISHRC=${HOME}/.config/fish/config.fish
if [ -f $FISHRC ]; then
	echo "Modifying ~/.config/fish/config.fish for use with capt..."
	cat <<EOF >>$FISHRC

# add capt to PATH

set -p LD_LIBRARY_PATH ${HOME}/.capt/root/lib/x86_64-linux-gnu:${HOME}/.capt/root/usr/lib/x86_64-linux-gnu
set -p PATH ${HOME}/.capt:${HOME}/.capt/root/bin:${HOME}/.capt/root/sbin:${HOME}/.capt/root/usr/bin:${HOME}/.capt/root/usr/sbin:${HOME}/.capt/root/usr/games:${HOME}/.capt/root/usr/local/bin:${HOME}/.capt/root/usr/local/sbin:${HOME}/.capt/root/usr/local/games:${HOME}/.capt/snap/bin
EOF
fi

echo "Installation of capt complete!"
echo "Please restart your shell or run \`source ${HOME}/.zshrc\` / \`source ${HOME}/.bashrc\` / \'source ${HOME}/.config/fish/config.fish\' (depending on your shell)"
