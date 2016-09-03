#!/bin/bash
#
# start the linux lab via docker
#

TOP_DIR=$(dirname `readlink -f $0`)

IMAGE=$(< ${TOP_DIR}/lab-name)

short_lab_name=`basename ${IMAGE}`
local_lab_dir=`dirname ${TOP_DIR}`
remote_lab_dir=/$short_lab_name/

browser=chromium-browser
remote_port=6080

CONTAINER_ID=""
[ -f $TOP_DIR/.lab_container_id ] && CONTAINER_ID=$(< $TOP_DIR/.lab_container_id)
if [ -n "$CONTAINER_ID" ]; then
    docker ps -f id=$CONTAINER_ID | grep -v PORTS
    if [ $? -eq 0 ]; then
        echo "LOG: $CONTAINER_ID exist, to create a new one, please remove $TOP_DIR/.lab_container_id"
	exit
    fi
fi

retry=0
local_port=""

local_port=""
while :;
do
    [ $retry -eq 0 ] && [ -f $TOP_DIR/.lab_local_port ] && local_port=$(< $TOP_DIR/.lab_local_port)
    [ -z "$local_port" -o $retry -ne 0 ] && local_port=$((RANDOM/500+6080))

    echo "new vnc port: $local_port"

    # Make sure it is unique
    ports=`docker ps -a | grep -v PORTS | grep "0.0.0.0:" | sed -e "s/.*0.0.0.0:\([0-9]*\)-.*/\1/g" | tr '\n' ' '`
    [ -n "$ports" ] && echo "old vnc ports: $ports"

    retry=1
    for port in $ports
    do
	if [ $local_port -eq $port ]; then
		retry=2
		break
	fi
    done

    [ $retry -eq 1 ] && break
    echo "Retry $retry times to generate a random and unique port"
done

# nfsd.ko must be inserted to enable nfs kernel server
sudo modprobe nfsd

CONTAINER_ID=$(docker run --privileged \
		--name ${short_lab_name}-${local_port} \
                --cap-add sys_admin --cap-add net_admin \
                --device=/dev/net/tun \
                -d -p $local_port:$remote_port \
                -v $local_lab_dir:$remote_lab_dir \
                $IMAGE)

echo "Wait for lab launching..."

while :;
do
    pwd=`docker logs $CONTAINER_ID 2>/dev/null | grep Password`
    sleep 2
    [ -n "$pwd" ] && break
done

echo Container: ${CONTAINER_ID:0:12} $pwd

unix_pwd=`echo $pwd | sed -e "s/.* Password: \([^ ]*\) .*/\1/g"`
vnc_pwd=`echo $pwd | sed -e "s/.* VNC-Password: \(.*\)$/\1/g"`

echo ${CONTAINER_ID:0:12} > $TOP_DIR/.lab_container_id
echo $local_port > $TOP_DIR/.lab_local_port
echo $unix_pwd > $TOP_DIR/.lab_unix_pwd
echo $vnc_pwd > $TOP_DIR/.lab_login_pwd

url=http://localhost:$local_port/vnc.html

$TOP_DIR/open-docker-lab.sh
