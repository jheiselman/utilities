#!/bin/bash
APP_HOME=$(realpath `dirname $0`)

for script in $APP_HOME/check_*.sh; do
  echo "Running $script"
  $script
done

$APP_HOME/create_html.sh

