# First we get and update last Ubuntu image
FROM    ubuntu
LABEL   maintainer="cyd@9bis.com"

ARG     TZ=${TZ:-Etc/UTC}
ARG     DEBIAN_FRONTEND=noninteractive
RUN	    \
        apt-get update                                   \
        && apt-get install -y                            \
          apt-utils                                      \
          language-pack-fr                               \
          tzdata                                         \
        && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Second we install VNC, noVNC and websockify
RUN     \
        apt-get update                                   \
        && apt-get install -y --no-install-recommends    \
          libpulse0                                      \
          x11vnc                                         \
          xvfb                                           \
          novnc                                          \
          websockify                                     \
        && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# And finally xfce4 and ratpoison desktop environments
RUN     \
        apt-get update                                   \
        && apt-get install -y --no-install-recommends    \
          dbus-x11                                       \
        && apt-get install -y                            \
          ratpoison                                      \
          xfce4 xfce4-terminal                           \
          xserver-xorg-video-dummy                       \
        && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# We can add additional GUI program (ex: firefox)
RUN     \
        apt-get update                                   \
        && apt-get install -y --no-install-recommends    \
          firefox                                        \
          notepadqq                                      \
        && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# We add some tools
RUN     \
        apt-get update                                   \
        && apt-get install -y --no-install-recommends    \
          curl                                           \
          mlocate                                        \
          sudo                                           \
        && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# We add sound
RUN     printf 'default-server = unix:/run/user/1000/pulse/native\nautospawn = no\ndaemon-binary = /bin/true\nenable-shm = false' > /etc/pulse/client.conf

# We add a simple user with sudo rights
ENV     USR=user
RUN     \
        groupadd ${USR}                                  \
        && useradd -m -g ${USR} -s /bin/bash ${USR}      \
        && echo "${USR}:${USR}01" | chpasswd             \
        && echo ${USR}'     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Two ports are availables: 5900 for VNC client, and 6080 for browser access via websockify
EXPOSE  5900 6080

# We set localtime
RUN      if [ "X${TZ}" != "X" ] ; then if [ -f /usr/share/zoneinfo/${TZ} ] ; then rm -f /etc/localtime ; ln -s /usr/share/zoneinfo/${TZ} /etc/localtime ; fi ; fi

# And here is the statup script, everything else is in there
COPY    startup.sh /startup.sh
RUN     chmod 755 /startup.sh

# We do some specials
RUN     \
        updatedb ;                                       \
        apt-get clean

# We change user
USER    ${USR}
WORKDIR /home/${USR}
COPY    bgimage.jpg /usr/share/backgrounds/xfce/bgimage.jpg

ENTRYPOINT [ "/startup.sh" ]
