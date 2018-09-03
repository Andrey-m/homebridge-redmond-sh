#!/bin/bash

devicemac="$1"

function tracemen()
{
    echo -e -n $1
}

function traceme()
{
    echo -e $1
}

if [[ $devicemac =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
    traceme "Will Control: $devicemac";
else
    traceme "Usage <mac>"
    exit;
fi

(( i=0 ))

while true; do
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100 > /dev/null
    sleep 0.2

    magic="5500ffb54c75b1b40c88efaa"
    sleep 0.2

    gatttool -b $devicemac -t random --char-write-req -a 0x000e -n $magic > /dev/null
    sleep 0.2

    magic="550004aa"
    sleep 0.2

    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic > /dev/null
    sleep 0.2

    magic=`printf "550206aa" $i`
    sleep 0.2

    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic > /dev/null
    sleep 0.2

    magic=`printf "5500ffb54c75b1b40c88efaa" $i`
    sleep 0.2

    response=$(gatttool -b $devicemac -t random --char-read -a 0x000b -n $magic)
    reply=`echo $response | grep "descriptor:" | sed "s/.*descriptor: \(.*\)/\\1/g"`

    if [[ $reply ==  "" ]]; then
        echo "No reply"
        #(( i = (i + 1) % 256 ));
    else
        device_on=`echo $reply | awk '{print $12}'`

        if [[ $device_on == "00" ]]; then
            traceme "OFF"
            break;
        fi
    fi
done;
