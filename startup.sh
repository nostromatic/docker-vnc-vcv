#!/bin/bash

# We update apt
sudo apt-get update > /dev/null &

# We check all container parameters
DESKTOP_VNC_PARAMS=""

# We prepare VNC
mkdir ~/.vnc

DESKTOP_SIZE=${DESKTOP_SIZE:-1280x1024}
DESKTOP_ENV=${DESKTOP_ENV:-xfce4}

# We add a password to VNC
if [ "X${DESKTOP_VNC_PASSWORD}" != "X" ] ; then
	echo "init password"
	x11vnc -storepasswd ${DESKTOP_VNC_PASSWORD:-password} ~/.vnc/passwd && chmod 0600 ~/.vnc/passwd
	DESKTOP_VNC_PARAMS=${DESKTOP_VNC_PARAMS}" -passwd ${DESKTOP_VNC_PASSWORD}"
fi
# We set the screen size
if [ "X${DESKTOP_SIZE}" != "X" ] ; then
	echo "set screen size"
	sudo sed -i -E 's/XVFBARGS="-screen 0 [0-9]+x[0-9]+x[0-9]+"/XVFBARGS="-screen 0 '${DESKTOP_SIZE}'x24"/' /bin/xvfb-run
	grep "^XVFBARGS" /bin/xvfb-run
fi

if [ "X${DESKTOP_ENV}" = "Xratpoison" ] ; then
	echo "configure ratpoison"
	# We run firefox at ratpoison startup
	echo "exec firefox" > ~/.ratpoisonrc && chmod +x ~/.ratpoisonrc
	# We run ratpoison at VNC server startup
	echo "exec ratpoison >/dev/null 2>&1" >> ~/.xinitrc
	# We start additinnal programs
	if [ "X${DESKTOP_ADDITIONAL_PROGRAMS}" != "X" ] ; then
		echo "exec ${DESKTOP_ADDITIONAL_PROGRAMS}" >> ~/.ratpoisonrc
	fi
elif  [ "X${DESKTOP_ENV}" = "Xxfce4" ] ; then
	echo "configure Xfce4"
	# We run xfce4 at VNC server startup
	echo "exec /usr/bin/startxfce4 >/dev/null 2>&1" >> ~/.xinitrc
	# We set keyboard
	if [ "X${DESKTOP_KEYBOARD_LAYOUT}" != "X" ] ; then
	  test -d ~/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
      layout=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#/.*$##')
	  variant=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#^.*/##')
	  echo "set ${layout}-${variant} keyboard"
	  printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="keyboard-layout" version="1.0">
  <property name="Default" type="empty">
    <property name="XkbDisable" type="bool" value="false"/>
    <property name="XkbLayout" type="string" value="'${layout}'"/>
    <property name="XkbVariant" type="string" value="'${variant}'"/>
  </property>
</channel>' > ~/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
	fi
	# We set background image
	if [ "X${DESKTOP_BACKGROUND_IMAGE}" != "X" ] ; then
	  if [ $(echo "${DESKTOP_BACKGROUND_IMAGE}" | grep -E "^https?:\/\/" | wc -l) -eq 1 ] ; then
		name=$(echo "${DESKTOP_BACKGROUND_IMAGE}" | sed 's#^.*/##')
	    echo "Set backgroud image to ${DESKTOP_BACKGROUND_IMAGE} / ${name}"
		wget "${DESKTOP_BACKGROUND_IMAGE}"
	  fi
	fi
else 
	echo "Unknown desktop environment" >&2
	exit 1
fi
chmod +x ~/.xinitrc

# We set repeat is on
sudo sed -i 's/tcp/tcp -ardelay 200 -arinterval 20/' /etc/X11/xinit/xserverrc

# We read the command-line parameters
if [ $# -ne 0 ] ; then
	if [ "${1}" = "help" ] ; then
		echo "Available variables:"
		echo "DESKTOP_ENV, DESKTOP_VNC_PASSWORD, DESKTOP_SIZE, DESKTOP_ADDITIONAL_PROGRAMS"
		exit 0
	fi
fi
# We start VNC server
export FD_GEOM=${DESKTOP_SIZE}		# To init a screen display when using Xvfb
x11vnc -create -forever -repeat ${DESKTOP_VNC_PARAMS} &
X11VNC_PID=$!

# We start noVNC
websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

# Prepare addons
echo "wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium" > ~/codium_install

# Is there an option
if [ $# -ne 0 ] ; then
	exec "$@"
else 
	tail -f /dev/null 
fi

kill $WEBSOCKIFY_PID
kill $X11VNC_PID
wait
