#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

today=$(date +"%d/%h/%Y")
localnet=$(ip route list scope link |sed -r -e 's/[0-9]+\/.*//g' -e 's/\./\\./g')

for entry in $HTTP_LOGS; do
  sname=$(sanitize_varsV2 "HTTP_Errors")
  last_status=$(get_last_statusV2 $sname "LOG")
  new_status=$last_status
  limit=10

  num_errors=$(grep -- "$today" $entry |grep -v "$localnet" |grep -v -P '(robots.txt|favicon.ico|sitemap.xml)' |grep -v ' [23][0-9][0-9] ' |wc -l)
  if [[ $num_errors -gt $limit ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "HTTP Errors Status" "Number of errors in HTTP log ($num_errors) exceeds the limit ($limit)"
      new_status="BAD"
    fi
  else
    if [[ "$last_status" != "OK" ]]; then
      #send_notice "HTTP Errors Status" "Number of errors in HTTP log ($num_errors) is less than the limit ($limit)"
      new_status="OK"
    fi
  fi

  record_status $sname "LOG" $new_status "Number of Errors: $num_errors"
done
