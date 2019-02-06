#!/bin/bash

devicemac="$1"
command="$2"


function tracemen()
{ 
  echo -e -n $1
}

function traceme()
{ 
  echo -e $1
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
  while true; do
    traceme "Attempt to write something -> 0x000c"
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
    sleep 0.5;
    
    #gatttool -b $devicemac -t random --listen &
    magic=`printf "55%02xffb54c75b1b40c88efaa" $i`
  
    
    traceme "Attempt to write something -> 0x000e ($magic)"
    sleep 0.5;
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


# Requesting status

if [[ $command == "query" || $command == "queryone" ]]; then
  while true; do
    #echo "Attempt to write something -> 0x000c"
    gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
    sleep 0.5;
    
    #gatttool -b $devicemac -t random --listen &
    magic=`printf "55%02x06aa" $i`
  
    
    #echo "Attempt to write something -> 0x000e ($magic)"
    sleep 0.5;
    gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >response  &
    gettpid=$!
    #echo "Forked to pid $gettpid"
    sleep 0.5;
    #echo "Killing to pid $gettpid"
    kill $gettpid  >/dev/null 2>/dev/null
    wait $gettpid 2>/dev/null
    response=`cat response`;
    reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
         
    
    if [[ $reply == "" ]]; then
      echo "No reply"
      (( i = (i + 1) % 256 ));
    else    
      kettle_keeptemp=`echo $reply | awk '{print $6}'`    
      kettle_on=`echo $reply | awk '{print $12}'`
      kettle_temp=`echo $reply | awk '{print $14}'`
    
      if [[ $kettle_on == "00" ]]; then
        echo -n "OFF"
      else
        echo -n "ON"
      fi
    
      echo -n " "  
      echo -n "$((16#$kettle_temp))C "
      echo -n "Will keep: $((16#$kettle_keeptemp))C "
      echo "REPLY:$reply"
      
      if [[ $command == "queryone" ]]; then
         break;
      fi;    
      (( i = (i + 1) % 256 ));
    fi
    
  done;
fi;

if [[ $command == "on" ]]; then
    while true; do
      #echo "Attempt to write something -> 0x000c"
      gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
      sleep 0.5;
      magic=`printf "55%02x0500000000aa" $i`
      
      #echo "Attempt to write something -> 0x000e ($magic)"
      sleep 0.5;
      gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >response  &
      gettpid=$!
      #echo "Forked to pid $gettpid"
      sleep 0.5;
      #echo "Killing to pid $gettpid"
      kill $gettpid  >/dev/null 2>/dev/null
      wait $gettpid 2>/dev/null
      response=`cat response`;
      reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
      
      is_on=`echo $reply | awk '{print $4}'`
      echo " <$is_on> "
      if [[ $is_on == "01" ]]; then 
	echo  "Success"
	break;
      else
	echo  "Trying again..."
      fi;
      
      if [[ $reply == "" ]]; then
	echo "No reply"
	(( i = (i + 1) % 256 ));
      else    
	(( i = (i + 1) % 256 ));
      fi        
   done;
    
fi;

if [[ $command == "keeptemp" ]]; then
    keep_temp="$3"

    while true; do
      #echo "Attempt to write something -> 0x000c"
      gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
      sleep 0.5;
      magic=`printf "55%02x050000%02x00aa" $i $keep_temp`
      
      #echo "Attempt to write something -> 0x000e ($magic)"
      sleep 0.5;
      gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >response  &
      gettpid=$!
      #echo "Forked to pid $gettpid"
      sleep 0.5;
      #echo "Killing to pid $gettpid"
      kill $gettpid  >/dev/null 2>/dev/null
      wait $gettpid 2>/dev/null
      response=`cat response`;
      reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
      
      is_on=`echo $reply | awk '{print $4}'`
      echo " <$is_on> "
      if [[ $is_on == "01" ]]; then 
	echo  "Success"
	break;
      else
	echo  "Trying again..."
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
   while true; do
      #echo "Attempt to write something -> 0x000c"
      gatttool -b $devicemac -t random --char-write-req --handle=0x000c --value=0100
      sleep 0.5;
      magic=`printf "55%02x04aa" $i`
      
      #echo "Attempt to write something -> 0x000e ($magic)"
      sleep 0.5;
      gatttool -b $devicemac -t random --char-write-req --handle=0x000e --value=$magic --listen >response  &
      gettpid=$!
      #echo "Forked to pid $gettpid"
      sleep 0.5;
      #echo "Killing to pid $gettpid"
      kill $gettpid  >/dev/null 2>/dev/null
      wait $gettpid 2>/dev/null
      response=`cat response`;
      reply=`echo $response | grep "value:" | sed "s/.*value: \(.*\)/\\1/g"`
      
      is_on=`echo $reply | awk '{print $4}'`
      echo " <$is_on> "
      if [[ $is_on == "01" ]]; then 
	echo  "Success"
	break;
      else
	echo  "Trying again..."
      fi;
      
      if [[ $reply == "" ]]; then
	echo "No reply"
	(( i = (i + 1) % 256 ));
      else    
	(( i = (i + 1) % 256 ));
      fi        
   done;
fi;

