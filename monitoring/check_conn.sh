#!/bin/bash

. $HOME/code/monitoring/common_functions.sh

for entry in $CONN_LIST; do
  name=$(echo $entry |cut -d: -f1)
  conn=$(echo $entry |cut -d: -f2)
  limit=$(echo $entry |cut -d: -f3)
  santize_vars "CONN__$name"
  get_last_status $last_status_key

  num_conns=$(grep -- "$conn" /proc/net/nf_conntrack |wc -l)
  if [ $num_conns -lt $limit ]; then
    if [ "$last_status" != "BAD" ]; then
      send_notice "Connection Check for $name" "Check failed for $name"
      record_status BAD
    fi
  elif [ $num_conns -ge $limit ]; then
    if [ "$last_status" != "OK" ]; then
      send_notice "Connection Check for $name" "Check OK for $name"
      record_status OK
    fi
  fi
done

