#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

for entry in $MEM_LIST; do
  process=$(echo $entry |cut -d= -f1)
  limit=$(echo $entry |cut -d= -f2)
  sname=$(sanitize_varsV2 $process)
  last_status=$(get_last_statusV2 $sname "MEM")
  new_status=$last_status
  pid=$(pgrep $process)
  if [[ -z "$pid" ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Memory Utilization for $process" "Memory utilization unretrievable for $process"
      new_status="BAD"
      $rss="Unknown"
    fi
  else
    statm=$(</proc/$pid/statm)
    rss=$(echo "$statm" | awk '{print $2}')
    if [[ $rss -gt $limit ]]; then
      if [[ "$last_status" != "BAD" ]]; then
        send_notice "Memory Utilization for $process" "Memory utilization ($rss) for $process is greater than threshold ($limit)"
        new_status="BAD"
      fi
    else
      if [[ "$last_status" != "OK" ]]; then
        send_notice "Memory Utilization for $process" "Memory utilization ($rss) for $process is back to normal"
        new_status="OK"
      fi
    fi
  fi
  record_status $sname "MEM" $new_status "Memory Utilization: $rss"
done

