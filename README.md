# docker-vnc-vcv

This is a test project, you better check the [original code from cyd01](https://github.com/cyd01/docker-vnc-xfce4).

## Description

How to run a GUI application inside a docker container, and to access the application within a browser.  
The easiest combo is to run 
- [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml) a virtual X server that can run on machines with no display hardware and no physical input devices. It emulates a dumb framebuffer using virtual memory
- a [VNC server](https://github.com/LibVNC/x11vnc) to be able to access from everywhere
- [noVNC](https://github.com/novnc/noVNC) + [websockify](https://github.com/novnc/websockify) that allow to do VNC through a browser
- [pulseaudio](https://www.freedesktop.org/wiki/Software/PulseAudio/) to share audio device
- a Window manager (see just below)

into an [Ubuntu](https://ubuntu.com/) base image.

It is possible to choose any windows manager, but some are lighter than others. Below, there will be two simple examples with light ones:
- [ratpoison](http://www.nongnu.org/ratpoison/)
- [Xfce](https://www.xfce.org/)

The final image size is 1.9Go.

## Prepare the host

### GPU support
Install cuda for WSL (NVIDIA GPU with Architecture >= Kepler)
```
https://docs.nvidia.com/cuda/wsl-user-guide/index.html
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
```
Then test it :
```
sudo docker run --gpus all --env NVIDIA_DISABLE_REQUIRE=1 nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark
sudo docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
```
inside a container:
```
user@7673554f575b:~$ nvidia-smi -L    
GPU 0: NVIDIA GeForce RTX 2080 Ti (UUID: GPU-a30c3c6d-06d1-109c-0c63-54bf2c3824b4)
```

Interesting doc: https://www.openrobots.org/morse/doc/latest/headless.html



## Build the docker image for i3

When building the image it is possible to specify a personal timezone
```
docker build .                \
  --file Dockerfile.i3           \
  --tag docker-vnc-i3         \
  --build-arg TZ=Europe/Paris \
  --build-arg LANG=fr_FR.UTF-8
```
It takes few minutes to make it.

### Start with i3
```
docker run --rm                                   \
  --gpus all                                      \
  --interactive                                   \
  --tty                                           \
  --publish 4444:4444                             \
  --publish 6080:6080                             \
  --publish ${VNC_PORT:-5900}:5900                \
  --name desktopi3                                \
  --env DESKTOP_ENV=i3                            \
  --env DESKTOP_KEYBOARD_LAYOUT="fr/azerty"       \
  --env DESKTOP_SIZE="1920x900"                   \
  docker-vnc-i3 /bin/bash
```

## Usage

The built image expose standard ports:
- 5900 for VNC access (here are [VNC clients](https://www.realvnc.com/en/connect/download/viewer/))
- 6080 for noVNC website
- 4444 for ffmpeg stream

So that for browser access the full address is [http://localhost:6080/vnc.html](http://localhost:6080/vnc.html).  
Applications starts with a simple user context: `user` (with password `user01`), and this user has `sudo` priviledges.  

## ffmpeg stream

```
/usr/bin/ffmpeg -threads 8 \
-video_size 1920x900 -f x11grab -i :20 -framerate 60 \
-codec:v libx264 -pix_fmt yuv420p -preset veryfast -fflags nobuffer \
-f flv -drop_pkts_on_overflow 1 -attempt_recovery 1 -recovery_wait_time 1 -rtmp_buffer 60 -listen 1 rtmp://0.0.0.0:4444/stream
```

### (not applicable) Configuration

Some variables can be passed to the `docker run` command to modify image behavior.

| Name                         | Description                                              |
| ---------------------------- | ---------------------------------------------------------|
| DESKTOP_ADDITIONAL_PROGRAMS  | Automatically starts a program (ratpoison only)          |
| DESKTOP_BACKGROUND_IMAGE     | Default background image (can be an url)                 |
| DESKTOP_ENV                  | Choose desktop environment (between ratpoison and xfce4) |
| DESKTOP_KEYBOARD_LAYOUT      | Specify default keyboard layout (format: layout/variant) |
| DESKTOP_SIZE                 | Define the screen size (default 1280x1024)               |
| DESKTOP_THEME                | Set the default Xfce4 theme                              |
| DESKTOP_VNC_PASSWORD         | Set a VNC password (default is none)                     |

_Example_: run Xfce4 in french, with desktop personal settings and sound

    docker run --rm                                                                                               \
      --interactive                                                                                               \
      --tty                                                                                                       \
      --volume /run/user/$(id -u)/pulse/native:/run/user/1000/pulse/native                                        \
      --privileged                                                                                                \
      --publish 6080:6080                                                                                         \
      --publish ${VNC_PORT:-5900}:5900                                                                            \
      --name desktop                                                                                              \
      --env DESKTOP_ENV=xfce4                                                                                     \
      --env LANG=fr_FR.UTF-8                                                                                      \
      --env DESKTOP_KEYBOARD_LAYOUT="fr/azerty"                                                                   \
      --env DESKTOP_SIZE="1920x1080"                                                                              \
      --env DESKTOP_THEME="Greybird-dark"                                                                         \
      --env DESKTOP_BACKGROUND_IMAGE="https://upload.wikimedia.org/wikipedia/commons/9/96/Alberi_AlpediSiusi.JPG" \
      docker-vnc-xfce4 /bin/bash