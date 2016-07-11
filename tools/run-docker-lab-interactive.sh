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

echo "Usage: Please open $url with password: $pwd"

# nfsd.ko must be inserted to enable nfs kernel server
sudo modprobe nfsd

#docker run --privileged --cap-add sys_admin --cap-add net_admin --device=/dev/net/tun  -i -p $port:$port -v $local_lab_dir:$remote_lab_dir -t $docker_image /bin/bash
docker run --privileged \
        --cap-add sys_admin --cap-add net_admin \
        --device=/dev/net/tun \
        -i \
        -p $port:$port \
        -v $local_lab_dir:$remote_lab_dir \
        -t $docker_image \
        /bin/bash
