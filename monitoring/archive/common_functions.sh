[[ -n "$PB_API_KEY" ]] && export PB_API_KEY
[[ -n "$IFTTT_API_KEY" ]] && export IFTTT_API_KEY

send_notice () 
{ 
    now=$(date --rfc-3339='seconds')
    echo -e "[$now] new notification: $1, $2" >> $NOTIFY_LOG 2>&1
    "$notify_script" "$1" "$2" >>"$NOTIFY_LOG" 2>&1
}

sanitize_varsV2 ()
{
  name=$1
  sanitized_name=${name/,/_}
  echo "$sanitized_name"
}

get_last_statusV2 ()
{
  key=$1
  type=$2
  last_status=""
  while read line; do
    if [[ $line =~ ^$key ]]; then
      last_status=${line##$key,$type,}
      last_status=${last_status%%,*}
      break
    fi
  done < $STATUS_FILE

  echo "$last_status"
}

record_status ()
{
  sname=$1
  type=$2
  status=$3
  state=$4

  max_wait=10
  waits=0
  while [[ -e $status_lock && $waits -lt $max_wait ]]; do
    sleep 1
    waits=$((waits + 1))
  done
  if [[ $max_wait -eq $waits ]]; then
    send_notice "Monitor Check Error" "Timeout waiting for status file to become available"
  else
    trap "rm -rf $status_lock" INT TERM EXIT
    mkdir -p $status_lock
    PID=$$
    grep -v "^$sname,$type" $STATUS_FILE > $status_lock/monitor_status.$PID
    echo "$sname,$type,$status,$state" >> $status_lock/monitor_status.$PID
    mv $status_lock/monitor_status.$PID $STATUS_FILE
    rm -rf $status_lock
    trap - INT TERM EXIT
  fi
}

