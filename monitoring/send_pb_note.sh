#!/bin/bash
PB_API_KEY=""

curl -s -o /dev/null --header "Access-Token: $PB_API_KEY" --header "Content-Type: application/json" --request POST --data-binary "{\"body\":\"$2\",\"title\":\"$1\",\"type\":\"note\"}" https://api.pushbullet.com/v2/pushes
