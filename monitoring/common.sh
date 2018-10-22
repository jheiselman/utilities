[ -n "$PB_API_KEY" ] && export PB_API_KEY
[ -n "$IFTTT_API_KEY" ] && export IFTTT_API_KEY

notify () 
{ 
    now=$(date --rfc-3339='seconds')
    echo "[$now] new notification: $1, $2" >> $NOTIFY_LOG 2>&1
    "$notify_script" "$1" "$2" >>"$NOTIFY_LOG" 2>&1
}

read_monitor ()
{
  key=$1
  type=$2
  prev_state=""
  while read -r line; do
    line_key="${line%,*,*}"
    if [ "$line_key" = "$key,$type" ]; then
      prev_state="${line##$key,$type,}"
      prev_state="${prev_state%%,*}"
      break
    fi
  done < "$STATUS_FILE"

  echo "$prev_state"
}

save_monitor ()
{
  name=$1
  type=$2
  state=$3
  status=$4

  max_wait=10
  waits=0
  while [ -e "$status_lock" ] && [ $((waits < max_wait)) -eq 1 ]; do
    sleep 1
    waits=$((waits+1))
  done
  if [ $((max_wait == waits)) -eq 1 ]; then
    notify "Monitor Check Error" "Timeout waiting for status file to become available"
    exit 127
  else
    trap "rm -rf $status_lock" INT TERM EXIT
    mkdir -p "$status_lock"
    grep -v "^$name,$type" "$STATUS_FILE" > "$status_lock/monitor_status"
    echo "$name,$type,$state,$status" >> "$status_lock/monitor_status"
    mv "$status_lock/monitor_status" "$STATUS_FILE"
    rm -rf "$status_lock"
    trap - INT TERM EXIT
  fi
}
