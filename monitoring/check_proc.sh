#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

for entry in $PROCS; do
  proc=$(echo $entry |cut -d= -f1)
  limit=$(echo $entry |cut -d= -f2)
  sname=$(sanitize_varsV2 "$proc")
  last_status=$(get_last_statusV2 $sname "PROC")
  new_status=$last_status

  numrunning=$(/usr/lib/nagios/plugins/check_procs -c $limit: -C $proc |sed -r 's/.*procs=([0-9]+);.*/\1/')
  if [[ $numrunning -lt $limit ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Process $proc Status" "Number of instances of process $proc ($numrunning) is less than the number required ($limit)"
      new_status="BAD"
    fi
  elif [[ $numrunning -gt $limit ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Process $proc Status" "Number of instances of process $proc ($numrunning) is more than the number required ($limit)"
      new_status="BAD"
    fi
  else
    if [[ "$last_status" != "OK" ]]; then
      send_notice "Process $proc Status" "Number of instances of process $proc ($numrunning) is equal to the number required ($limit)"
      new_status="OK"
    fi
  fi
  record_status $sname "PROC" $new_status "Number of process instances: $numrunning"
done

