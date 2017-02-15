APP_HOME=$HOME/code/monitoring
STATUS_FILE=$APP_HOME/status.log
CONFIG_FILE=$APP_HOME/config
NOTIFY_LOG=$APP_HOME/notify.log

CHATBRIDGE=/dev/udp/127.0.0.1/9001
notify_script=$HOME/code/send_pb_note.sh
#notify_script=$HOME/code/send_ifttt.sh
status_lock=/tmp/monitoring_status.lck

[[ ! -e $STATUS_FILE ]] && touch $STATUS_FILE

. $CONFIG_FILE

now=$(date --rfc-3339='seconds')

check_bot ()
{
  listening=$(netstat -lun |grep :9001 |wc -l)
  [[ $listening -eq 0 ]] && echo ""
  [[ $listening -eq 1 ]] && echo "1"
}

send_notice () 
{ 
    echo -e "[$now] new notification: $1, $2" >> $NOTIFY_LOG 2>&1;
    bot_pid=$(check_bot);
    [[ -n "$bot_pid" ]] && echo -e "$2" > $CHATBRIDGE 2>&1;
    [[ -z "$bot_pid" ]] && echo -e "[$now] Using web note for notifications" >> $NOTIFY_LOG && $notify_script "$1" "$2" >>$NOTIFY_LOG 2>&1
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
    if [[ -n "$sname" ]]; then
      touch $status_lock
      PID=$$
      grep -v "^$sname,$type" $STATUS_FILE > /tmp/monitor_status.$PID.tmp
      echo "$sname,$type,$status,$state" >> /tmp/monitor_status.$PID.tmp
      mv /tmp/monitor_status.$PID.tmp $STATUS_FILE
      rm $status_lock
    fi
  fi
}

