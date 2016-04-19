APP_HOME=$HOME/code/monitoring
STATUS_FILE=$APP_HOME/status.log
CONFIG_FILE=$APP_HOME/config
NOTIFY_LOG=$APP_HOME/notify.log
TBRIDGE=/dev/udp/localhost/9001
notify_script=$HOME/code/send_pb_note.sh
status_lock=/tmp/monitoring_status.lck

if [ -e $STATUS_FILE ]; then
  source $STATUS_FILE
else
  touch $STATUS_FILE
fi

source $CONFIG_FILE

send_notice() {
  if [ "$1" = "Process monitoringBot Status" ]; then
    send_pb_note "$1" "$2"
  else
    echo "new notification: $1, $2" >$NOTIFY_LOG 2>&1
    /bin/echo -e "$2" >$TBRIDGE 2>&1
  fi
}

send_pb_note() {
  echo "new notification: $1, $2" >$NOTIFY_LOG 2>&1
  $notify_script "$1" "$2" >$NOTIFY_LOG 2>&1
}

santize_vars() {
  last_status_key=$(echo $1 | sed 's/[^a-zA-Z0-9]/_/g')
}

get_last_status() {
  last_status=$(eval echo \$"$last_status_key")
}

record_status() {
  max_wait=10
  waits=0
  while [ -e $status_lock -a $waits -lt $max_wait ]; do
    sleep 1
    waits=$((waits + 1))
  done
  if [ $max_wait -eq $waits ]; then
    send_pb_note "Monitor Check Error" "Timeout waiting for status file to become available"
  else
    touch $status_lock
    if [ "x$last_status" = "x" ]; then
      echo "$last_status_key=$1" >> $STATUS_FILE
    else
      sed -i "s/$last_status_key=.*/$last_status_key=$1/" $STATUS_FILE
    fi
    rm $status_lock
  fi
}
