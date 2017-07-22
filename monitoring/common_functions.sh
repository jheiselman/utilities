STATUS_FILE=$APP_HOME/status.log
CONFIG_FILE=$APP_HOME/config
NOTIFY_LOG=$APP_HOME/notify.log

CHATBRIDGE=/dev/udp/127.0.0.1/9001
notify_script=$APP_HOME/send_pb_note
#notify_script=$APP_HOME/send_ifttt
status_lock=/tmp/monitoring_status.lck

[[ ! -e $STATUS_FILE ]] && echo "#name,type,status,state" > $STATUS_FILE

. $CONFIG_FILE

[[ -n "$PB_API_KEY" ]] && export PB_API_KEY
[[ -n "IFTTT_API_KEY" ]] && export IFTTT_API_KEY

check_bot ()
{
  netstat -lun |grep ':9001 ' >/dev/null 2>&1
  echo $(($?^1)) # flip the exit code from 0>1 or 1>0
}

send_notice () 
{ 
    now=$(date --rfc-3339='seconds')
    echo -e "[$now] new notification: $1, $2" >> $NOTIFY_LOG 2>&1;
    bot_is_running=$(check_bot);
    [[ $bot_is_running -eq 1 ]] && echo -e "$2" > $CHATBRIDGE 2>&1;
    [[ $bot_is_running -eq 0 ]] && echo -e "[$now] Using web note for notifications" >> $NOTIFY_LOG && $notify_script "$1" "$2" >>$NOTIFY_LOG 2>&1
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

