#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

for entry in $CONN_LIST; do
  name=$(echo $entry |cut -d: -f1)
  conn=$(echo $entry |cut -d: -f2)
  limit=$(echo $entry |cut -d: -f3)
  sname=$(sanitize_vars $name)
  last_status=$(get_last_statusV2 $sname "CONN")
  new_status=$last_status
  num_conns=$(grep -- "$conn" /proc/net/nf_conntrack |wc -l)
  if [[ $num_conns -lt $limit ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Connection Check for $name" "Check failed for $name"
      new_status="BAD"
    fi
  elif [[ $num_conns -ge $limit ]]; then
    if [[ "$last_status" != "OK" ]]; then
      send_notice "Connection Check for $name" "Check OK for $name"
      new_status="OK"
    fi
  fi

  record_status $sname "CONN" $new_status "Number of connections: $num_conns"
done

