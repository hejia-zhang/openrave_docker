#/bin/bash

xhost +local:root 

docker run \
    -it \
    --rm \
    --gpus all \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /dev/bus/usb:/dev/bus/usb:ro \
    -v /dev:/dev \
    --env="DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --name "openrave" \
    --privileged \
    openrave_docker;

xhost -local:root
