#!/bin/bash

if [ $# != 1 ]; then
  echo -e "Usage:\n $./lookup.sh wordpress\n $./lookup.sh ghs\n";
  exit 1;
fi

while read line
do

  host=$( echo "$line" |
    grep -oE "[a-z0-9]([a-z0-9_\.\-]*[a-z0-9])?\.[a-z]{2,3}" |
    grep -vE "dot$|htm$|php$" );

  [ "$host" ] && [ "$(nslookup $host | grep $1)" ] && echo $host;

done < "list.txt"

