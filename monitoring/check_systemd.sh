#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

for entry in $SYSTEMD_SERVICES; do
  proc=$entry
  sname=$(sanitize_varsV2 $proc)
  last_status=$(get_last_statusV2 $sname "SYSDSVC")
  new_status=$last_status

  /bin/systemctl -q --user is-failed $proc.service
  retval=$?
  state=$(/bin/systemctl --user is-failed $proc.service)
  if [[ -z "$state" ]]; then
    [[ $retval -eq 0 ]] && state="failed"
    [[ $retval -eq 1 ]] && state="active"
  fi

  if [[ $retval -eq 1 ]]; then
    if [[ "$last_status" != "OK" ]]; then
      send_notice "Service $proc Status" "Service $proc is active"
      new_status="OK"
    fi
  else
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Service $proc Status" "Service $proc is failed"
      new_status="BAD"
    fi
  fi
  record_status $sname "SYSDSVC" $new_status "$state"
done

