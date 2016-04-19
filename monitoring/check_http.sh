#!/bin/bash

. $HOME/code/monitoring/common_functions.sh

for host in $HTTP_HOSTS; do
  santize_vars "HTTP__$host"
  get_last_status $last_status_key

  curl -k -s -m 5 -o /dev/null $host
  if [ $? -ne 0 ]; then
    if [ "$last_status" != "BAD" ]; then
      send_notice "HTTP Status for $host" "Check failed for $host"
      record_status BAD
    fi
  else
    if [ "$last_status" != "OK" ]; then
      send_notice "HTTP Status for $host" "Check OK for $host"
      record_status OK
    fi
  fi
done
