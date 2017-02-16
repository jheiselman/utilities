#!/bin/bash

APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}
. $APP_HOME/common_functions.sh

for entry in $HTTP_HOSTS; do
  url=$entry
  sname=$(sanitize_varsV2 $url)
  last_status=$(get_last_statusV2 $sname "HTTP")

  port=80
  protocol=$(echo $url |cut -d: -f1)
  host=$(echo $url |sed -r -e 's/^.+:\/\///' -e 's/^([a-zA-Z0-9\-\.:]+).*/\1/')

  if [[ "$protocol" == "https" ]]; then
    port=443
    ssl_opt="-S"
  fi

  /usr/lib/nagios/plugins/check_http -H $host -p $port $ssl_opt >/dev/null 2>&1
  #curl -k -s -m 5 -o /dev/null $url
  if [[ $? -ne 0 ]]; then
    if [[ "$last_status" != "BAD" ]]; then
      send_notice "HTTP Status for $url" "Check failed for $url"
    fi
    new_status="BAD"
    new_state="Down"
  else
    if [[ "$last_status" != "OK" ]]; then
      send_notice "HTTP Status for $url" "Check OK for $url"
    fi
    new_status="OK"
    new_state="Up"
  fi

  record_status $sname "HTTP" $new_status "$new_state"
done

