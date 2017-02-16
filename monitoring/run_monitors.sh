#!/bin/bash
APP_HOME="."
[[ $0 =~ / ]] && APP_HOME=${0%/*}

for script in $APP_HOME/check_*.sh; do
  $script
done

$APP_HOME/create_html.sh

