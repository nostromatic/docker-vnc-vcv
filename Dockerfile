# First we get and update last Ubuntu image
FROM    ubuntu
LABEL   maintainer="cyd@9bis.com"

ARG     TZ=${TZ:-Etc/UTC}
ARG     DEBIAN_FRONTEND=noninteractive
RUN	    \
        apt-get update                                 \
        && apt-get install -y                          \
          language-pack-fr                             \
          tzdata

# Second we install VNC, noVNC and websockify
RUN     \
        apt-get install -y --no-install-recommends     \
          x11vnc                                       \
          xvfb                                         \
          novnc                                        \
          websockify

# And finally xfce4 and ratpoison desktop environments
RUN     \
        apt-get install -y --no-install-recommends     \
          dbus-x11                                     \
        && apt-get install -y                          \
          ratpoison                                    \
          xfce4 xfce4-terminal                         \
          xserver-xorg-video-dummy

# We can add additional GUI program (ex: firefox)
RUN     \
        apt-get install -y --no-install-recommends     \
          firefox                                      \
          notepadqq

# We add some tools
RUN     \
        apt-get install -y --no-install-recommends     \
          curl                                         \
          mlocate

# We add a simple user with sudo rights
ENV     USR=user
RUN     \
        groupadd ${USR}                                \
        && useradd -m -g ${USR} -s /bin/bash ${USR}    \
        && echo "${USR}:${USR}01" | chpasswd           \
        && apt-get install -y --no-install-recommends  \
          sudo                                         \
        && echo ${USR}'     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Two ports are availables: 5900 for VNC client, and 6080 for browser access via websockify
EXPOSE  5900 6080

# We set localtime
RUN      if [ "X${TZ}" != "X" ] ; then if [ -f /usr/share/zoneinfo/${TZ} ] ; then rm -f /etc/localtime ; ln -s /usr/share/zoneinfo/${TZ} /etc/localtime ; fi ; fi

# And here is the statup script, everything else is in there
COPY    startup.sh /startup.sh
RUN     chmod 755 /startup.sh

# We do some cleaning
RUN     \
        updatedb ;                                     \
        apt-get clean                                  \
        && rm -rf /var/cache/apt/*                     \
		&& rm -rf /var/lib/apt/lists/*

# We change user
USER    ${USR}
WORKDIR /home/${USR}

ENTRYPOINT [ "/startup.sh" ]
