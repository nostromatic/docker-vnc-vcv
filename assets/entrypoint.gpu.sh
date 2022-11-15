#!/bin/bash

# We set USER
export USER=$(whoami)

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
	sed -i -E 's/XVFBARGS="-screen 0 [0-9]+x[0-9]+x[0-9]+"/XVFBARGS="-screen 0 '${DESKTOP_SIZE}'x24"/' /bin/xvfb-run
	grep "^XVFBARGS" /bin/xvfb-run
fi

# Init .xinitrc
#printf 'autocutsel -fork -selection CLIPBOARD\nautocutsel -fork -selection PRIMARY\n' > ~/.xinitrc

if [ "X${DESKTOP_ENV}" = "Xvcv" ] ; then
  echo "Configuring VCV Rack"
  # We run i3 at VNC server startup
	echo "exec bash ~/Rack2Free/Rack.sh" >> ~/.xinitrc
elif [ "X${DESKTOP_ENV}" = "Xi3" ] ; then
  echo "Configuring i3"
  # We run i3 at VNC server startup
  #echo "exec i3 >/dev/null 2>&1" >> ~/.xinitrc
  mkdir -p ~/.config/i3
  cp /etc/i3/config ~/.config/i3/
  
  sudo bash /60-configure_gpu_driver.sh
  sudo bash /70-configure_xorg.sh

  #echo "exec --no-startup-id i3-msg 'workspace 1:VCV; exec bash ~/Rack2Free/Rack.sh'" >> ~/.config/i3/config
  if [ "X${DESKTOP_KEYBOARD_LAYOUT}" != "X" ] ; then
    layout=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#/.*$##')
	  variant=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#^.*/##')
  fi
else 
	echo "Unknown desktop environment" >&2
	exit 1
fi

chmod +x ~/.xinitrc

# We set repeat is on
#sudo sed -i 's/tcp/tcp -ardelay 200 -arinterval 20/' /etc/X11/xinit/xserverrc

# We read the command-line parameters
if [ $# -ne 0 ] ; then
	if [ "${1}" = "help" ] ; then
		echo "Available variables:"
		echo "DESKTOP_ENV, DESKTOP_VNC_PASSWORD, DESKTOP_SIZE, DESKTOP_THEME, DESKTOP_ADDITIONAL_PROGRAMS"
		exit 0
	fi
fi

# We set sound
#export PULSE_SERVER=unix:/run/user/$(id -u)/pulse/native

# We start VNC server
export FD_GEOM=${DESKTOP_SIZE}		# To init a screen display when using Xvfb
{ 
  while [ 1 ] ; do
    figlet "x11vnc"
    x11vnc -create -forever -repeat ${DESKTOP_VNC_PARAMS}
    sleep 1
  done
} &

# We start noVNC
figlet websockify
websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

# Run an apt update
sudo apt-get update > /dev/null &

# Is there an option
if [ $# -ne 0 ] ; then
	exec "$@"
else 
	tail -f /dev/null 
fi

kill $WEBSOCKIFY_PID
wait
