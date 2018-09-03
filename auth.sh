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



traceme "Reading primary info"
#gatttool -b $devicemac -t random --primary

traceme "Reading characteristics info"
#gatttool -b $devicemac -t random --characteristics

traceme "Reading characteristics desc"
#gatttool -b $devicemac -t random --char-desc


traceme "Attempt to write something -> 0x000c"
#gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100

(( i=0 ))

if true; then  # Auth sequence.
  while true; do
    traceme "Attempt to write something -> 0x000c"
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
    sleep 0.5;

    #gatttool -b $devicemac -t random --listen &
    magic=`printf "55%02xffb54c75b1b40c88efaa" $i`


    traceme "Attempt to write something -> 0x000e ($magic)"
    #sleep 0.5;
    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >response  &
    gettpid=$!
    #echo "Forked to pid $gettpid"
    sleep 0.5;
    #echo "Killing to pid $gettpid"
    kill $gettpid  >/dev/null 2>/dev/null
    wait $gettpid 2>/dev/null
    response=`cat response`;
    reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
    echo -n "REPLY:$reply"

    is_authorized=`echo $reply | awk '{print $4}'`
    traceme " <$is_authorized> "
    if [[ $is_authorized == "01" ]]; then
      traceme  "Authorized"
      break;
    fi;

    if [[ $is_authorized == "00" ]]; then
      traceme  "HOLD '+' button"

    fi;

    if [[ $reply == "" ]]; then
      traceme "No reply"
      (( i = (i + 1) % 256 ));
    else
      (( i = (i + 1) % 256 ));
    fi
  done;
fi;

traceme "Ok";

rm -fr response
