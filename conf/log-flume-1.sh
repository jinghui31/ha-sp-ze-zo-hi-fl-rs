#!/bin/bash

i=999
while true
do
  s=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  echo $i,$s >> /tmp/flume-hive.data
  sleep 3
  ((i++))
done
