#!/bin/bash

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
	sudo sed -i -E 's/XVFBARGS="-screen 0 [0-9]+x[0-9]+x[0-9]+"/XVFBARGS="-screen 0 '${DESKTOP_SIZE}'x24"/' /bin/xvfb-run
	grep "^XVFBARGS" /bin/xvfb-run
fi

if [ "X${DESKTOP_ENV}" = "Xratpoison" ] ; then
	# We run firefox at ratpoison startup
	echo "exec firefox" > ~/.ratpoisonrc && chmod +x ~/.ratpoisonrc
	# We run ratpoison at VNC server startup
	echo "exec ratpoison" >> ~/.xinitrc
	# We start additinnal programs
	if [ "X${DESKTOP_ADDITIONAL_PROGRAMS}" != "X" ] ; then
		echo "exec ${DESKTOP_ADDITIONAL_PROGRAMS}" >> ~/.ratpoisonrc
	fi
elif  [ "X${DESKTOP_ENV}" = "Xxfce4" ] ; then
	# We run xfce4 at VNC server startup
	echo "exec /usr/bin/startxfce4" >> ~/.xinitrc
else 
	echo "Unknown desktop environment" >&2
	exit 1
fi
chmod +x ~/.xinitrc

# We read the command-line parameters
if [ $# -ne 0 ] ; then
	if [ "${1}" = "help" ] ; then
		echo "Available variables:"
		echo "DESKTOP_VNC_PASSWORD, DESKTOP_SIZE, DESKTOP_ADDITIONAL_PROGRAMS"
		exit 0
	fi
fi
# We start VNC server
export FD_GEOM=${DESKTOP_SIZE}		# To init a screen display when using Xvfb
export DISPLAY=:0
x11vnc -create -forever ${DESKTOP_VNC_PARAMS} &

# We start noVNC
websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 6080 localhost:5900 &

if [ $# -ne 0 ] ; then
	$@
else 
	tail -f /dev/null 
fi
