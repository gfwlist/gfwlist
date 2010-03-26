#!/bin/bash

if [ $# != 1 ]; then
  echo -e "\
    Usage:
     $./lookup.sh wordpress
     $./lookup.sh ghs.l.google
     $./lookup.sh 72.14.203.121 // ghs
     $./lookup.sh 67.207.139.81 // Posterous
     $./lookup.sh 72.32.231.8 // Tumblr
     $./lookup.sh typepad
  ";
  exit 1;
fi

while read line
do

  host=$( echo "$line" |
    grep -oE "[a-z0-9]([a-z0-9_\.\-]*[a-z0-9])?\.[a-z]{2,4}" |
    grep -vE "(aspx?|dotn|exe|fan|html?|php|zh)$"
  );

  [ "$host" ] && [ "$(nslookup $host | grep -i $1)" ] && echo $host;

done < "list.txt"

