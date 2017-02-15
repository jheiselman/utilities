#!/bin/bash

APP_HOME=$(realpath `dirname $0`)
. $APP_HOME/common_functions.sh

TMPID=$$

if [[ -n "$CHECK_BW" ]]; then
  sname=$(sanitize_varsV2 $CHECK_BW)
  last_status=$(get_last_statusV2 $sname "CHECK_BW")
  status=$last_status

  rm -f /tmp/check_bw.*
  wget -q -O /tmp/check_bw.$TMPID http://ovweb.mediacomcable.com/um/usage.action?custId=$CHECK_BW
  if [[ $? -eq 0 ]]; then
    line=$(grep -oP '\d+% used.*\d+% left' /tmp/check_bw.$TMPID)
    used=$(echo $line |grep -oP '^\d+')
    left=$(echo $line |grep -oP '\d+% left$' |grep -oP '^\d+')

    days=$(grep -oP 'with \d+ days remaining' /tmp/check_bw.$TMPID |sed -r 's/^.* ([0-9]+) .*$/\1/')
    if [[ -n "$days" ]]; then
      perc_days=$(awk '{printf("%i\n", ($1/30)*100)}' <<<"$days")
      perc_days_left=$((100-perc_days))

      if [[ $used -gt $perc_days_left ]]; then
        if [[ $last_status != "BAD" ]]; then
          status="BAD"
          send_notice "Bandwidth Consumption Status" "Bandwidth consumption has exceeded remaining days. Currently $used%"
        fi
      else
        if [[ $last_status != "OK" ]]; then
          status="OK"
          send_notice "Bandwidth Consumption Status" "Bandwidth consumption is below remaining days. Currently $used%"
        fi
      fi
      state="Used: $used%, Left: $left%, Days left: $days"
    else
      state="Bad response from Mediacom"
    fi

    record_status $sname "CHECK_BW" $status "$state"
    #rm /tmp/check_bw.$TMPID
  else
    # Error checking
    /bin/false
  fi
fi

