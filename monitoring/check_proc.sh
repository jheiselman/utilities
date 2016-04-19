#!/bin/bash

. $HOME/code/monitoring/common_functions.sh

for entry in $PROCS; do
  proc=$(echo $entry |cut -d= -f1)
  limit=$(echo $entry |cut -d= -f2)
  santize_vars "PROC__$proc"
  get_last_status $last_status_key
  numrunning=0
  for file in `ls -d /proc/[0-9]*`; do
    if [ -e $file/comm ]; then
      comm=$(cat $file/comm)
      if [ "$comm" == "$proc" ]; then
        numrunning=$((counter + 1))
      fi
    fi
  done
  if [ $numrunning -lt $limit ]; then
    if [ "$last_status" != "BAD" ]; then
      send_notice "Process $proc Status" "Number of instances of process $proc ($numrunning) is less than the number required ($limit)"
      record_status BAD
    fi
  elif [ $numrunning -ge $limit ]; then
    if [ "$last_status" != "OK" ]; then
      send_notice "Process $proc Status" "Number of instances of process $proc ($numrunning) is more than the number required ($limit)"
      record_status OK
    fi
  fi
done
