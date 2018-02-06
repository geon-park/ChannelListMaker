#!/bin/bash
# check root permission
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# change shell prompt color
perl -i -p -e "s/PS1='\\\$\\{debian_chroot:\\+\\(\\\$debian_chroot\\)\\}\\\\u@\\\\h:\\\\w\\\\\\\$ '/PS1='\\\\[\\\\033[1;36m\\\\]\\\\u\\\\[\\\\033[1;31m\\\\]@\\\\[\\\\033[1;32m\\\\]\\\\h:\\\\[\\\\033[1;35m\\\\]\\\\w\\\\[\\\\033[1;31m\\\\]\\\\\\\$\\\\[\\\\033[0m\\\\] '/g" ~/.bashrc

# update packages
echo "start to update packages"
echo "=================================================="
apt-get update -qq && apt-get dist-upgrade -y

# install docker-ce
echo "Check whether docker-ce is installed or not"
echo "=================================================="
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

# set values
timeout_seconds=20
GID=$(id -g $USER)
base_dir=/data/tvheadend
image_tag=stable

# check existing tvheadend container
if [ $(docker ps -a -q --format "{{.Image}}" 2>/dev/null | grep -iF "tvheadend" | wc -l) -ge 1 ]; then
  echo "tvheadend container is already installed. Do you want to make another one? (y/n)"
  while true
  do
    read -t $timeout_seconds create_tvheadend
    create_tvheadend=${create_tvheadend:-n}
    if echo $create_tvheadend | grep -iqE "^[y]"; then
      create_tvheadend="${create_tvheadend:0:1}"
      create_tvheadend="${create_tvheadend,,}"
      break
    elif echo $create_tvheadend | grep -iqE "^[n]"; then
      echo "tvheadend container creating script finished."
      exit
    fi
  done
fi

# create directories
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

# Input container name
echo "Container name for tvheadend"
echo "=================================================="
name_for_tvheadend=""
if [ $(docker ps -a -q --filter name=tvheadend --filter status=running --format "{{.Names}}" 2>/dev/null | grep -w "tvheadend") ]; then
  echo "Input container name for tvheadend."
  read name_for_tvheadend
else
  echo "Input container name for tvheadend in $timeout_seconds seconds. (Default value is tvheadend)"
  read -t $timeout_seconds name_for_tvheadend
fi
name_for_tvheadend=${name_for_tvheadend:-tvheadend}


# start container for tvheadend
echo "Creating container for tvheadend"
echo "=================================================="
sudo docker run -d \
  --name=$name_for_tvheadend \
  --network=host \
  --restart=unless-stopped \
  -v $recordings_dir:/recordings \
  -v $config_dir:/config \
  -v $epg2xml_dir:/epg2xml \
  -e PUID=$UID \
  -e PGID=$GID \
  wiserain/tvheadend:$image_tag

# echo about next step
echo "=================================================="
echo "Please add channels.m3u file"
echo "Please change channels.json"
