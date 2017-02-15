#!/bin/bash

APP_HOME=$(realpath `dirname $0`)
. $APP_HOME/common_functions.sh

for host in $PING_HOSTS; do
  sname=$(sanitize_varsV2 $host)
  last_status=$(get_last_statusV2 $sname "PING")
  new_status=$last_status

  output=$(/usr/lib/nagios/plugins/check_ping -H lava-cube.com -w 15,90% -c 30,90%)
  # PING WARNING - Packet loss = 0%, RTA = 17.53 ms|rta=17.531000ms;15.000000;30.000000;0.000000 pl=0%;90;90;0
  avg=$(echo $output |sed -r 's/.* RTA = (.*)\..+ ms.*/\1/')
  new_state=$(echo $output |sed -r 's/.* - (.*?)\|.*/\1/')

  #avg=$(ping -q -c 5 lava-cube.com 2>/dev/null |awk -F "/" '$0~/avg/ {print $5}')
  if [[ $? -ne 0 ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Ping Status for $host" "Ping failed for $host"
      new_status="BAD"
      #new_state="Ping Failed"
    fi
  else
    if [[ $avg -lt 100 ]]; then
      if [[ "$last_status" != "OK" ]]; then
        send_notice "Ping Status for $host" "Ping OK for $host"
        new_status="OK"
        #new_state="Ping Successful. Response time: $avg"
      fi
    else
      if [[ "$last_status" != "BAD" ]]; then
        send_notice "Response Time for $host" "Response time greather than 30 ms for $host"
        new_status="BAD"
      fi
    fi
  fi

  record_status $sname "PING" $new_status "$new_state"
done

