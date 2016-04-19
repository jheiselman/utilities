#!/bin/bash

. $HOME/code/monitoring/common_functions.sh

for host in $PING_HOSTS; do
  santize_vars "PING__$host"
  get_last_status $last_status_key
  avg=$(ping -c 5 $host 2>/dev/null | awk '$0~/avg/ {print $4}' | cut -d/ -f2 | cut -d. -f1)
  if [ $? -ne 0 ]; then
    if [ "$last_status" != "BAD" ]; then
      $notify_script "Ping Status for $host" "Ping failed for $host"
      record_status BAD
    fi
  else
    if [ $avg -lt 30 ]; then
      if [ "$last_status" != "OK" ]; then
        send_notice "Ping Status for $host" "Ping OK for $host"
        record_status OK
      fi
    else
      send_notice "Response Time for $host" "Response time greather than 30 ms for $host"
      record_status BAD
    fi
  fi
done
