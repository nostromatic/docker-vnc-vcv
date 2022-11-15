# This Docker file deploy xvfb + i3 (no GPU support)
FROM    ubuntu:jammy
LABEL   maintainer=Nostromatic

# We prepare environment
ARG     TZ=${TZ:-Etc/UTC}
ARG     LANG=${LANG:-en_US.UTF-8}
ARG     DEBIAN_FRONTEND=noninteractive
RUN     \
        echo "Timezone and locale" >&2                     \
        echo ${LANG} > /etc/default/locale                 \
        && apt-get update                                  \
        && apt-get install -y                              \
          apt-utils                                        \
          software-properties-common                       \
          tzdata                                           \
        && apt-get clean                                   \
        && apt-get autoremove -y                           \
        && rm -rf /tmp/* /var/tmp/*                        \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
        && echo "Timezone and locale OK" >&2

# Second we install VNC, noVNC and websockify
RUN     \
        echo "install VNC, noVNC and websockify" >&2       \
        && apt-get update                                  \
        && apt-get install -y --no-install-recommends      \
          libpulse0                                        \
          x11vnc                                           \
          xvfb                                             \
          novnc                                            \
          websockify                                       \
        && apt-get clean                                   \
        && apt-get autoremove -y                           \
        && rm -rf /tmp/* /var/tmp/*                        \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
        && echo "install VNC, noVNC and websockify OK" >&2

RUN     \
         echo "Install i3" >&2                              \
         && apt-get update                                  \
         && apt-get install -y --no-install-recommends      \
           dbus-x11                                         \
         && apt-get install -y                              \
           i3                                               \
           xserver-xorg-video-dummy                         \
         && apt-get clean                                   \
         && apt-get autoremove -y                           \
         && rm -rf /tmp/* /var/tmp/*                        \
         && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
         && echo "Install i3 OK" >&2

# We add some tools
RUN     \
        echo "Install some tools" >&2                      \
        && apt-get update                                  \
        && apt-get install -y --no-install-recommends      \
          curl                                             \
          dumb-init                                        \
          figlet                                           \
          libnss3-tools                                    \
          sudo                                             \
          vim                                              \
          unzip                                            \
          ffmpeg                                           \
          mesa-utils                                       \
          mesa-utils-extra                                 \
        && apt-get clean                                   \
        && apt-get autoremove -y                           \
        && rm -rf /tmp/* /var/tmp/*                        \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
        && echo "Install some tools OK" >&2

# We can add additional programs
RUN     \
        echo "Install additional programs" >&2         \
        && apt-get update                                  \
        && apt-get install -y --no-install-recommends      \
        zenity                                             \
        && apt-get clean                                   \
        && apt-get autoremove -y                           \
        && rm -rf /tmp/* /var/tmp/*                        \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
        && echo "Install additional GUI programs OK" >&2

# We add sound
#RUN     printf 'default-server = unix:/run/user/1000/pulse/native\nautospawn = no\ndaemon-binary = /bin/true\nenable-shm = false' > /etc/pulse/client.conf

# We add a simple user with sudo rights
ENV     USR=user
ARG     USR_UID=${USER_UID:-1000}
ARG     USR_GID=${USER_GID:-1000}

RUN     \
        echo "Add simple user" >&2                                                      \
        && groupadd --gid ${USR_GID} ${USR}                                             \
        && useradd --uid ${USR_UID} --create-home --gid ${USR} --shell /bin/bash ${USR} \
        && echo "${USR}:${USR}01" | chpasswd                                            \
        && echo ${USR}'     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers                     \
	&& echo "Add simple user OK" >&2

# 5900 for VNC client
# 6080 for browser access via websockify
# 4444 for ffmpeg RTMP TCP stream
EXPOSE  5900 6080 4444

# We set localtime
RUN if [ "X${TZ}" != "X" ] ; then if [ -f /usr/share/zoneinfo/${TZ} ] ; then rm -f /etc/localtime ; ln -s /usr/share/zoneinfo/${TZ} /etc/localtime ; fi ; fi

# And here is the statup script, everything else is in there
COPY    assets/entrypoint.i3.sh /entrypoint.sh
RUN     chmod 755 /entrypoint.sh

# We change user
USER    ${USR}
WORKDIR /home/${USR}

RUN     \
        echo "Install VCV Rack" >&2         \
        && curl https://vcvrack.com/downloads/RackFree-2.1.2-lin.zip -O \
        && unzip RackFree-2.1.2-lin.zip \
        && rm -f RackFree-2.1.2-lin.zip \
        && printf '#!/bin/bash\ncd ~/Rack2Free\n./Rack' > ~/Rack2Free/Rack.sh \
        && rm -rf /tmp/* /var/tmp/*                        \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*    \
        && echo "VCV Rack OK" >&2

ENTRYPOINT [ "/entrypoint.sh" ]