#!/bin/bash

# Author: Li Zheng <flyskywhy@gmail.com>
# Simplify the test of running a syncthing server to match many devices.

local_help ()
{
    echo "Automatically add a new syncthing device id from terminal"
    echo "Simple usage:"
    echo "    ./t.sh mkdir 100"
    echo "    ./t.sh sed 97 ZIBCVZJ-FRXCMWH-7YWCRA3-O7XDSUE-GF24LAG-FUDPXGE-M6HSPHG-PDEFTQD"
    echo "    Then you should restart syncthing on server"
    echo
    echo "t.sh mkdir <1-1000>   - mkdir many folders"
    echo "t.sh sed <0-999> <id> - sed the config.xml to add a syncthing device id ref to a folder"
    echo
    echo "t.sh help             - show this help message"
}

local_mkdir ()
{
    folders=$1
    i=0
    while [ $i -lt $folders ]; do
        mkdir -p $i
        i=$(( $i + 1 ))
    done

    echo
}

local_sed ()
{
    folder=$1
    id=$2
    p22000=$((22700 + $folder))
    config=~/.config/syncthing/config.xml

    if [ ! -d $folder ] ; then
        mkdir $folder
    fi

    if [ `grep -c  "$id" $config` = 0 ] ; then
        sed -e "s/SED_FOLDER/$folder/g" -e "s|SED_PWD|$PWD|" -e "s/SED_ID/$id/" t_folder_device_id > tmp_t_folder_device_id
        sed -e "s/SED_FOLDER/$folder/g" -e "s/SED_PORT/$p22000/" -e "s/SED_ID/$id/" t_device_id > tmp_t_device_id
        n=`grep -n "^    </folder>" $config | awk -F: 'END{print $1}'`
        sed -i "$n r tmp_t_folder_device_id" $config
        n=`grep -n "^    </device>" $config | awk -F: 'END{print $1}'`
        sed -i "$n r tmp_t_device_id" $config
    fi

    echo
}

if [ $# = 0 ] ; then
    local_help
elif [ $1 = mkdir ] ; then
    local_mkdir $2
elif [ $1 = sed ] ; then
    local_sed $2 $3
else
    local_help
fi
