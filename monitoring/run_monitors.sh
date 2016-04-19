#!/bin/bash
MONITORING_HOME=$(dirname $0)

for script in $MONITORING_HOME/check_*.sh; do
  $script
done
