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
	echo "exec ~/Rack2Free/Rack >/dev/null 2>&1" >> ~/.xinitrc
elif [ "X${DESKTOP_ENV}" = "Xi3" ] ; then
  echo "Configuring i3"
  # We run i3 at VNC server startup
	echo "exec i3 >/dev/null 2>&1" >> ~/.xinitrc
  mkdir -p ~/.config/i3
  cp /etc/i3/config ~/.config/i3/
  echo "exec --no-startup-id i3-msg 'workspace 1:VCV; exec bash ~/Rack2Free/Rack.sh'" >> ~/.config/i3/config
  if [ "X${DESKTOP_KEYBOARD_LAYOUT}" != "X" ] ; then
    layout=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#/.*$##')
	  variant=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#^.*/##')
  fi
elif [ "X${DESKTOP_ENV}" = "Xratpoison" ] ; then
	echo "Configuring ratpoison"
	# We run ratpoison at VNC server startup
	echo "exec ratpoison >/dev/null 2>&1" >> ~/.xinitrc
	# We start additinnal programs
	if [ "X${DESKTOP_ADDITIONAL_PROGRAMS}" != "X" ] ; then
		echo "exec ${DESKTOP_ADDITIONAL_PROGRAMS}" >> ~/.ratpoisonrc
  else
  	# We run firefox at ratpoison startup
  	echo "exec firefox" > ~/.ratpoisonrc && chmod +x ~/.ratpoisonrc
	fi
elif  [ "X${DESKTOP_ENV}" = "Xxfce4" ] ; then
	echo "Configuring Xfce4"
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
	# We set theme
	if [ "X${DESKTOP_THEME}" != "X" ] ; then
	test -d ~/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
	printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="'${DESKTOP_THEME}'"/>
    <property name="IconThemeName" type="empty"/>
    <property name="DoubleClickTime" type="empty"/>
    <property name="DoubleClickDistance" type="empty"/>
    <property name="DndDragThreshold" type="empty"/>
    <property name="CursorBlink" type="empty"/>
    <property name="CursorBlinkTime" type="empty"/>
    <property name="SoundThemeName" type="empty"/>
    <property name="EnableEventSounds" type="empty"/>
    <property name="EnableInputFeedbackSounds" type="empty"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="empty"/>
    <property name="Antialias" type="empty"/>
    <property name="Hinting" type="empty"/>
    <property name="HintStyle" type="empty"/>
    <property name="RGBA" type="empty"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CanChangeAccels" type="empty"/>
    <property name="ColorPalette" type="empty"/>
    <property name="FontName" type="empty"/>
    <property name="MonospaceFontName" type="empty"/>
    <property name="IconSizes" type="empty"/>
    <property name="KeyThemeName" type="empty"/>
    <property name="ToolbarStyle" type="empty"/>
    <property name="ToolbarIconSize" type="empty"/>
    <property name="MenuImages" type="empty"/>
    <property name="ButtonImages" type="empty"/>
    <property name="MenuBarAccel" type="empty"/>
    <property name="CursorThemeName" type="empty"/>
    <property name="CursorThemeSize" type="empty"/>
    <property name="DecorationLayout" type="empty"/>
  </property>
  <property name="Gdk" type="empty">
    <property name="WindowScalingFactor" type="empty"/>
  </property>
</channel>' > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
	fi
	# We set background image
	if [ "X${DESKTOP_BACKGROUND_IMAGE}" != "X" ] ; then
	  if [ $(echo "${DESKTOP_BACKGROUND_IMAGE}" | grep -E "^https?:\/\/" | wc -l) -eq 1 ] ; then
		wget "${DESKTOP_BACKGROUND_IMAGE}" -O "${HOME}/bgimage.jpg"
		DESKTOP_BACKGROUND_IMAGE="${HOME}/bgimage.jpg"
	  fi
	test -d ~/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
	test -f "${DESKTOP_BACKGROUND_IMAGE}" && printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace1" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace2" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace3" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
      </property>
    </property>
  </property>
</channel>' > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

  # We set clipboard
  test -d ~/.config/autostart || mkdir -p ~/.config/autostart
  cp /etc/xdg/autostart/xfce4-clipman-plugin-autostart.desktop ~/.config/autostart/xfce4-clipman-plugin-autostart.desktop
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

# Is there an option
if [ $# -ne 0 ] ; then
	exec "$@"
else 
	tail -f /dev/null 
fi

kill $WEBSOCKIFY_PID
wait
