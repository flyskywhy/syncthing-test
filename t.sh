#!/bin/bash

# Author: Li Zheng <flyskywhy@gmail.com>
# Simplify the test of running many terminal devices by running many docker containers.

local_help ()
{
    echo "Automatically add a new docker container flyskywhy/syncthing into host computer"
    echo "Simple usage:"
    echo "    ./t.sh mkdir 10"
    echo "    ./t.sh add 0"
    echo "    Then you can use web browser to open host_IP:8700"
    echo "    And so on: <./t.sh add 1> then open host_IP:8701"
    echo
    echo "t.sh mkdir <1-1000>   - mkdir many folders"
    echo "t.sh add <1-1000>     - add a init complete config.xml in a folder and run a container"
    echo
    echo "t.sh run <1-1000>     - docker run a container ref to a folder"
    echo "t.sh kill <1-1000>    - docker kill a container ref to a folder"
    echo "t.sh sed <1-1000>     - replace config/config.xml to be init complete in a folder"
    echo
    echo "t.sh help             - show this help message"
}

local_mkdir ()
{
    folders=$1
    i=0
    while [ $i -lt $folders ]; do
        mkdir -p $i/config
        mkdir -p $i/sync
        i=$(( $i + 1 ))
    done

    echo
}

local_run ()
{
    folder=$1
    p8384=$((8700 + $folder))
    p22000=$((22700 + $folder))
    p21025=$((22700 + $folder))
    docker run -d \
      --restart=on-failure:20 \
      -v /pub/syncthing/$folder/config:/config \
      -v /pub/syncthing/$folder/sync:/sync \
      -p $p8384:8384/tcp \
      -p $p22000:22000/tcp \
      -p $p21025:21025/udp \
      flyskywhy/syncthing

    echo
}

local_kill ()
{
    folder=$1
    p8384=$((8700 + $folder))
    docker ps | grep $p8384 | sed -e 's/ .*//' | xargs docker kill

    echo
}

local_sed ()
{
    folder=$1
    sed -i "s/id=\"default\" path=\"\/home\/syncthing\/Sync\"/id=\"$folder\" path=\"\/sync\"/" $folder/config/config.xml
    sed -i "s/urAccepted>0/urAccepted>-1/" $folder/config/config.xml

    grep "^        <device id=" $folder/config/config.xml
    sed -i "/^        <device id=/r s_folder_device_id" $folder/config/config.xml
    sed -i "/^    <\/device>/r s_device_id" $folder/config/config.xml

    echo
}

local_add ()
{
    folder=$1
    local_run $folder
    while [ ! -f $folder/config/config.xml ]; do
        sleep 1
    done
    sleep 1
    local_kill $folder
    local_sed $folder
    local_run $folder

    echo
}

if [ $# = 0 ] ; then
    local_help
elif [ $1 = mkdir ] ; then
    local_mkdir $2
elif [ $1 = run ] ; then
    local_run $2
elif [ $1 = kill ] ; then
    local_kill $2
elif [ $1 = sed ] ; then
    local_sed $2
elif [ $1 = add ] ; then
    local_add $2
else
    local_help
fi


