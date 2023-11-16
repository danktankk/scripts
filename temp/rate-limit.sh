#!/bin/bash

cat /dev/null > temp  #create this file first
cat /dev/null > temp2  #create this file first
cat /dev/null > temp3   #create this file first

sed -n "/^${yesterday}/,/^${today}/ p" /var/log/pihole.log 1>/home/pi/scripts/temp  #only notes log messages within the last 24 hours
grep -w 'Rate-limiting' /home/pi/scripts/temp 1>/home/pi/scripts/temp2  #searches for a match and stores in a temp file

RESULT=$(grep -c '168.192' /home/pi/scripts/temp2 2>/dev/null)  #counts the number of times '168.192' was found in temp file

  if [ "$RESULT" -gt "0" ]; then  #if >0 results are found then continue
    RESULT=$(grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.168.192' /home/pi/scripts/temp | sort -t . -k 2,2n -k 1,1n | uniq 1>/home/pi/scripts/temp3)
    RESULT=$(sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+).*/\4.\3.\2.\1/' /home/pi/scripts/temp3)
    IP=$(echo "$RESULT" | awk '{print " Client " $1 " has been rate-limited by PiHole."}')  #push notification message

      TIMESTAMPFILE="/var/log/timestamp.txt"
      TIMESTAMPLASTMODIFIED=$(stat -c %Z "$TIMESTAMPFILE")
      CURRENTTIME=$(date +%s)
      TIMEDIFF=$(expr "$CURRENTTIME" - "$TIMESTAMPLASTMODIFIED")

  if [ "$TIMEDIFF" -gt "3600" ]; then   #checks if it has been more than an hour and if so, sends push notification - set to what you prefer
    curl -s \
    --form-string "token=<your pushover api token>" \
    --form-string "user=<your pushover user key>" \
    --form-string "message=$IP" \
    https://api.pushover.net/1/messages.json

  touch $TIMESTAMPFILE  #adds current run time to file

  fi

fi
