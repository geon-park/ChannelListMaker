#!/bin/bash
# check root permission
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

# check argument
if [ "$#" -lt 1 ]; then
    echo "Please enter docker container name and tag."
    echo "Usage: ./start.sh container_name [latest]"
    exit
fi

# change shell prompt color
perl -i -p -e "s/PS1='\\\$\\{debian_chroot:\\+\\(\\\$debian_chroot\\)\\}\\\\u@\\\\h:\\\\w\\\\\\\$ '/PS1='\\\\[\\\\033[1;36m\\\\]\\\\u\\\\[\\\\033[1;31m\\\\]@\\\\[\\\\033[1;32m\\\\]\\\\h:\\\\[\\\\033[1;35m\\\\]\\\\w\\\\[\\\\033[1;31m\\\\]\\\\\\\$\\\\[\\\\033[0m\\\\] '/g" ~/.bashrc

# update packages
apt-get update -qq && apt-get dist-upgrade -y

# install docker-ce
if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get remove -y docker docker-engine docker.io
    sudo apt-get update -qq && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -qq && sudo apt-get install -y docker-ce
else
    echo "Docker is already installed."
fi

# create directories
base_dir=/data/tvheadend

config_dir=$base_dir/config
epg2xml_dir=$base_dir/epg2xml
recordings_dir=$base_dir/recordings

if [ ! -d $config_dir ]; then
    mkdir -p $config_dir
fi

if [ ! -d $epg2xml_dir ]; then
    mkdir -p $epg2xml_dir
fi

if [ ! -d $recordings_dir ]; then
    mkdir -p $recordings_dir
fi

# set values
GID=$(id -g $USER)
container_name=$1

image_tag=${2:-stable}

# start container for tvheadend
sudo docker run -d \
    --name=$container_name \
    --network=host \
    --restart=unless-stopped \
    -v $recordings_dir:/recordings \
    -v $config_dir:/config \
    -v $epg2xml_dir:/epg2xml \
    -e PUID=$UID \
    -e PGID=$GID \
    wiserain/tvheadend:$image_tag

# echo about next step
echo "Please add channels.m3u file"
echo "Please change channels.json"
