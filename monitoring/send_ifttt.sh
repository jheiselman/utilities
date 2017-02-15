#!/bin/bash
IFTTT_API_KEY=""

curl -s -o /dev/null -X POST --header "Content-Type: application/json" --request POST --data-binary "{\"value1\":\"$1\",\"value2\":\"$2\"}" https://maker.ifttt.com/trigger/monitoring_event/with/key/${IFTTT_API_KEY}
