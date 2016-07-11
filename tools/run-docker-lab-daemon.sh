#!/bin/bash
#
# start the linux lab via docker with the shared source in $PWD/
#

docker_image=tinylab/linux-lab
local_lab_dir=$PWD/
remote_lab_dir=/linux-lab/

browser=chromium-browser
port=6080
url=http://localhost:$port/vnc.html
pwd=ubuntu

# nfsd.ko must be inserted to enable nfs kernel server
sudo modprobe nfsd

CONTAINER_ID=$(docker run --privileged \
                --cap-add sys_admin --cap-add net_admin \
                --device=/dev/net/tun \
                -d -p $port:$port \
                -v $local_lab_dir:$remote_lab_dir \
                $docker_image)

docker logs $CONTAINER_ID | sed -n 1p

which $browser 2>&1>/dev/null \
    && ($browser $url 2>&1>/dev/null &) \
    && echo "please login with password: $pwd" && exit 0

echo "Usage: Please open $url with password: $pwd"
