#!/bin/bash

#C8:54:A9:29:1B:7F
devicemac="$1"
command="$2"

(
  flock -e 200

function tracemen()
{
  #echo -e -n $1 >>kettellog.txt
  return 0
}

function traceme()
{
  #echo -e $1 >>kettellog.txt
  return 0
}

if [[ $devicemac == "_" ]]; then
    $devicemac=`cat kettle.mac`
fi;

if [[ $devicemac =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
   traceme "Will Control: $devicemac";
else
   traceme "Usage <mac> <command>"
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


# 55:00:ff:b5:4c:75:b1:b4:0c:88:ef:aa
# 55:01:ff:b5:4c:75:b1:b4:0c:88:ef:aa
# 55:02:ff:b5:4c:75:b1:b4:0c:88:ef:aa
# 55:03:ff:b5:4c:75:b1:b4:0c:88:ef:aa
#sdf


(( i=0 ))

if true; then  # Auth sequence.
  while [ $i -lt 2 ]; do
    #echo "Restarting hci0"
    #repll=`/home/ubuntu/r4s_webserver/restart_ble.sh`
    #sleep 0.5;
    #echo "trying:$i"
    traceme "Attempt to write something -> 0x000c"
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100 > /dev/null
    sleep 0.5;

    #gatttool -b $devicemac -t random --listen &
    magic=`printf "55%02xffb54c75b1b40c88efaa" $i`

    traceme "Attempt to write something -> 0x000e ($magic)"
    sleep 0.5;
    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >/tmp/response_auth  &
    gettpid=$!
    #echo "Forked to pid $gettpid"
    sleep 0.5;
    #echo "Killing to pid $gettpid"
    kill $gettpid  >/dev/null 2>/dev/null
    wait $gettpid 2>/dev/null
    response=`cat /tmp/response_auth`;
    reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
    #echo -n "REPLY:$reply"

    is_authorized=`echo $reply | awk '{print $4}'`
    traceme " <$is_authorized> "
    if [[ $is_authorized == "01" ]]; then
      traceme  "Authorized"
      break;
    fi;
    if [[ $is_authorized == "02" ]]; then
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

if [[ $command == "status" ]]; then
  while [ $i -lt 2 ]; do
    #echo "trying:$i"
    #echo "Attempt to write something -> 0x000c"
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100 >/dev/null 2>/dev/null
    sleep 0.5;

    #gatttool -b $devicemac -t random --listen &
    magic=`printf "55%02x06aa" $i`

    #echo "Attempt to write something -> 0x000e ($magic)"
    sleep 0.5;
    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >/tmp/response_status 2>/dev/null &
    gettpid=$!
    #echo "Forked to pid $gettpid"
    sleep 0.5;
    #echo "Killing to pid $gettpid"
    kill $gettpid  >/dev/null 2>/dev/null
    wait $gettpid 2>/dev/null
    response=`cat /tmp/response_status`;
    #echo $response
    reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`

    if [[ $reply == "" ]]; then
      echo "No reply"
      (( i = (i + 1) % 256 ));
    else
      #kettle_keeptemp=`echo $reply | awk '{print $6}'`
      #kettle_temp=`echo $reply | awk '{print $14}'`
      #kettle_temp=`echo $reply | awk '{print $6}'`
      #kettle_keeptemp=`echo $reply | awk '{print $14}'`
      #kettle_keeptemp_mode=`echo $reply | awk '{print $5}'`
      kettle_on=`echo $reply | awk '{print $12}'`

      if [[ $kettle_on == "00" ]]; then
        echo "OFF"
        #echo "state:OFF"
      else
        echo "ON"
        #echo "state:ON"
      fi


      kettle_keeptemp="0"

      if [[ $kettle_keeptemp_mode == "01" ]]; then
        kettle_keeptemp="40"
      elif [[ $kettle_keeptemp_mode == "02" ]]; then
        kettle_keeptemp="55"
      elif [[ $kettle_keeptemp_mode == "03" ]]; then
        kettle_keeptemp="70"
      elif [[ $kettle_keeptemp_mode == "04" ]]; then
        kettle_keeptemp="85"
      elif [[ $kettle_keeptemp_mode == "05" ]]; then
        kettle_keeptemp="95"
      fi

      #echo -n " "
      #echo -n "$((16#$kettle_temp))C "
      #echo -n "Will keep: $((16#$kettle_keeptemp))C "
      #echo -n "Will keep: $(($kettle_keeptemp))C "
      #echo "REPLY:$reply"

      #echo "temp:$((16#$kettle_temp))"
      #echo "heating:$(($kettle_keeptemp))"

      if [[ $command == "status" ]]; then
         break;
      fi;
      (( i = (i + 1) % 256 ));
    fi

  done;
fi;

if [[ $command == "on" ]]; then
    while [ $i -lt 2 ]; do
      #echo "trying:$i"
      #echo "Attempt to write something -> 0x000c"
      gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100 >/dev/null
      sleep 0.5;
      magic="550003aa"

      #echo "Attempt to write something -> 0x000e ($magic)"
      sleep 0.5;
      gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >/tmp/response_on  &
      gettpid=$!
      #echo "Forked to pid $gettpid"
      sleep 0.5;
      #echo "Killing to pid $gettpid"
      kill $gettpid  >/dev/null 2>/dev/null
      wait $gettpid 2>/dev/null
      response=`cat /tmp/response_on`;
      reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`

      is_on=`echo $reply | awk '{print $4}'`
      #echo " <$is_on> "
      if [[ $is_on == "01" ]]; then
	echo  "ON"
	break;
      #else
	#echo  "Trying again..."
      fi;

      if [[ $reply == "" ]]; then
	echo "No reply"
	(( i = (i + 1) % 256 ));
      else
	(( i = (i + 1) % 256 ));
      fi
   done;

fi;

if [[ $command == "off" ]]; then
   while [ $i -lt 2 ]; do
      #echo "trying:$i"
      #echo "Attempt to write something -> 0x000c"
      gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100  >/dev/null
      sleep 0.5;
      magic=`printf "55%02x04aa" $i`

      #echo "Attempt to write something -> 0x000e ($magic)"
      sleep 0.5;
      gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >/tmp/response_off  &
      gettpid=$!
      #echo "Forked to pid $gettpid"
      sleep 0.5;
      #echo "Killing to pid $gettpid"
      kill $gettpid  >/dev/null 2>/dev/null
      wait $gettpid 2>/dev/null
      response=`cat /tmp/response_off`;
      reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`

      is_on=`echo $reply | awk '{print $4}'`
      #echo " <$is_on> "
      if [[ $is_on == "01" ]]; then
	echo  "OFF"
	break;
    #  else
	#echo  "Trying again..."
      fi;

      if [[ $reply == "" ]]; then
	echo "No reply"
	(( i = (i + 1) % 256 ));
      else
	(( i = (i + 1) % 256 ));
      fi
   done;
fi;

) 200>/tmp/lock.file

rm -fr /tmp/lock.file /tmp/response*