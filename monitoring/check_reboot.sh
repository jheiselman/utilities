#!/bin/bash

APP_HOME=$(realpath `dirname $0`)
. $APP_HOME/common_functions.sh

if [[ "$SYS_REBOOT" == "1" ]]; then
  sname=$(sanitize_varsV2 "Reboot_Required")
  last_status=$(get_last_statusV2 $sname "SYS")
  state="No reboot required"
  new_status=$last_status

  if [[ -e /var/run/reboot-required ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "Reboot Check" "A reboot is required"
      new_status="BAD"
      state="Reboot Required"
    fi
  else
    if [[ "$last_status" != "OK" ]]; then
      send_notice "Reboot Check" "A reboot is NOT required"
      new_status="OK"
    fi
  fi
fi

record_status $sname "SYS" $new_status "$state"

