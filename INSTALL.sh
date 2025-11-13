#!/bin/bash

################################################################################
#                         Function declarations
################################################################################

function fail () {
	echo ${@:-"Install encountered and error\nExiting..."} > /dev/stderr
	exit 1
}

function bash_install {
	local bashrc="${HOME}/.bashrc"

	echo "Adding stuff to bashrc"
	if grep "# add capt to PATH" "$bashrc" > /dev/null; then return 0; fi
	cat <<- EOF >> "$bashrc" || fail

	# add capt to PATH

	export LD_LIBRARY_PATH=${CAPT_DIR}/root/lib/x86_64-linux-gnu:${CAPT_DIR}/root/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH
	export PATH=${CAPT_DIR}:${CAPT_DIR}/root/usr/local/sbin:${CAPT_DIR}/root/usr/local/bin:${CAPT_DIR}/root/usr/sbin:${CAPT_DIR}/root/usr/bin:${CAPT_DIR}/root/sbin:${CAPT_DIR}/root/bin:${CAPT_DIR}/root/usr/games:${CAPT_DIR}/root/usr/local/games:${CAPT_DIR}/snap/bin:\$PATH
	EOF
}

function zsh_install {
	local zshrc="${HOME}/.zshrc"

	echo "Adding stuff to zshrc"
	if grep "# add capt to PATH" "$zshrc" > /dev/null; then return 0; fi
	cat <<- EOF >> "$zshrc" || fail

	# add capt to PATH

	export LD_LIBRARY_PATH=${CAPT_DIR}/root/lib/x86_64-linux-gnu:${CAPT_DIR}/root/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH
	export PATH=${CAPT_DIR}:${CAPT_DIR}/root/usr/local/sbin:${CAPT_DIR}/root/usr/local/bin:${CAPT_DIR}/root/usr/sbin:${CAPT_DIR}/root/usr/bin:${CAPT_DIR}/root/sbin:${CAPT_DIR}/root/bin:${CAPT_DIR}/root/usr/games:${CAPT_DIR}/root/usr/local/games:${CAPT_DIR}/snap/bin:\$PATH
	EOF
}

function fish_install {
	local DEFAULT_FISHRC="${HOME}/.config/fish/config.fish"
	local FISHRC=${DEFAULT_FISHRC}

	if [ ! -f "${FISHRC}" ]; then
		read -p "File 'config.fish' not in expected location.\n Enter path to config.fish. Leave blank to use default location anyway.\n$PS2" FISHRC
		if [ -z "$FISHRC" ]; then
			echo "Using default location '${DEFAULT_FISHRC}'"
			FISHRC="${DEFAULT_FISHRC}"
			mkdir -p $(dirname "${DEFAULT_FISHRC}") || fail
		elif ![ -f  $FISHRC ]; then
			echo "config.fish not in entered location. Aborting..."
			exit 1
		fi
	fi
	echo "Adding stuff to fishrc"
	if grep "# add capt to PATH" "$FISHRC" > /dev/null; then return 0; fi
	cat <<- EOF >> "$FISHRC" || fail "Cannot write to 'config.fish'"

	# add capt to PATH

	set -p LD_LIBRARY_PATH ${CAPT_DIR}/root/lib/x86_64-linux-gnu:${CAPT_DIR}/root/usr/lib/x86_64-linux-gnu
	set -p PATH ${CAPT_DIR}:${CAPT_DIR}/root/bin:${CAPT_DIR}/root/sbin:${CAPT_DIR}/root/usr/bin:${CAPT_DIR}/root/usr/sbin:${CAPT_DIR}/root/usr/games:${CAPT_DIR}/root/usr/local/bin:${CAPT_DIR}/root/usr/local/sbin:${CAPT_DIR}/root/usr/local/games:${CAPT_DIR}/snap/bin
	EOF
}

################################################################################
#                                Script start
################################################################################

CAPT_DIR="${HOME}/sgoinfre/.capt"
echo "Creating directories..."
mkdir -p ${CAPT_DIR}/root || fail
mkdir -p ${CAPT_DIR}/debs_temp || fail

echo "Creating installer script..."
cat << EOF > ${CAPT_DIR}/capt || fail
#!/bin/bash

CAPT_DIR="${CAPT_DIR}"
EOF
cat << "EOF" >> ${CAPT_DIR}/capt || fail
cd ${CAPT_DIR}/debs_temp
rm -rf *.deb
if [[ $# < 2 || "$1" != "install" ]]; then
	echo "Capt only supports 'apt install [packages...]'"
	exit 1
fi
shift
echo "Downloading prerequisites..."
PACKAGES_DOWNLOADED=0
while [ $# -gt 0 ]; do
	if apt-cache depends $1 > /dev/null; then
		apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $1 | grep "^\w" | sort -u)
		((PACKAGES_DOWNLOADED++))
	fi
	shift
done
if [ $PACKAGES_DOWNLOADED -eq 0 ]; then
	exit 1
fi
echo -n "Installing packages"
find . -iname "*.deb" -type f -exec echo -n "." \; -exec dpkg -x {} ${CAPT_DIR}/root \;
echo
echo "Finished installing, removing temp files..."
rm -rf *.deb
echo "Done"
EOF

echo "Setting executable bit on \`capt\` executable..."
chmod +x ${CAPT_DIR}/capt || fail

echo "Which shell do you use?(zsh is default at Codam)"
select selection in "zsh" "bash" "fish"; do
	selection=${selection:-${REPLY}}
	case $selection in
		"zsh")
			zsh_install
			break
			;;
		"bash")
			bash_install
			break
			;;
		"fish")
			fish_install
			break
			;;
		*)
			echo "Invalid input"
	esac
done

echo "Done, please restart your shell or run \`source ${HOME}/.zshrc\` / \`source ${HOME}/.bashrc\` / \'source ${HOME}/.config/fish/config.fish\' (depending on your shell)"
