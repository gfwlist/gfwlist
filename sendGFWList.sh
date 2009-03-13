#!/bin/bash
#
# A simple script help to maintain AutoProxy gfwList easily.
#
# Function:
#   Update local svn repository;
#   Commit decoded changes(by others in your team) to local git repository
#           with decoded message and authors name;
#   Update "Last Modified" time;
#   Update "Checksum";
#   Commit your changes to local git repository;
#   Commit your encoded changes to remote svn repository with encoded log.
# Usage:
#   Initialize:
#     $svn checkout https://autoproxy-gfwlist.googlecode.com/svn/trunk/ gfwList --username your-google-user-name
#     $cd gfwList
#     $git init
#     $base64 -d gfwlist.txt > list.txt
#     $git add list.txt
#     $git commit -a -m "init"
#   Normal Usage:
#     edit list.txt as usual;
#     $./sendGFWList.sh "say something about this edit"
# Note:
#   1: You can use "git" to show, diff, log...what's you want;
#   2: "gfwlist.txt" is a fake file, do NOT commit "list.txt" to svn server;
#   3: Do NOT use any unicode character in the list, there is a known bug.
###############################################################################

# dependence
for cmd in sed date base64 gawk svn git
do
  which $cmd &> /dev/null;
  if [ $? -ne 0 ]; then
    echo "Depends on $cmd, please install it first.";
    exit 1;
  fi
done

svn update &&

if [ "$(git diff)" == "" ]; then
  echo "not modified.";
  exit 0;
fi

# get self last changed revision number
oriLang=$LANG; export LANG="en_US";
curRevNum=$( svn info | gawk '/^Last Changed Rev:/ { print $4 }' );
export LANG=$oriLang;

# save local modification
git diff > temp.patch &&

# get formated author and log information
log=$(svn log -r $curRevNum:HEAD) &&
log=$(echo $log | gawk -v RS='------------------------------------------------------------------------'\
  'NR > 2 { if (NF > 10) printf "%s:%s;", $3, $NF; }' ) &&

# convert from base64
i=0 &&
convertedLog="" &&
while [ "$log" != "" ]
do
  if (( $i%2 == 0 )); then # author
    temp=${log%%:*};
    convertedLog+=${temp%@*}; # don't include "@gmail.com"
    convertedLog+=":\"";
    # discard used string
    log=${log#*:};
  else                # log, decode it
    temp=$( echo ${log%%;*} | base64 -d);
    convertedLog+=$temp;
    convertedLog+="\"; ";
    log=${log#*;};
  fi
  ((i++));
done

# replace last ";" symbol to "."
convertedLog=$( echo $convertedLog | sed 's/;$/\./' ) &&

if [ "$convertedLog" != "" ]; then
  # modified by others, commit to local repository.
  # log format: author1:"message1"; author2:"message2"...
  base64 -d gfwlist.txt > list.txt &&
  git commit -a -m "$convertedLog" &&

  # apply local modification
  git apply temp.patch;
fi

# update date and checksum
sed -i s/"Last Modified:.*$"/"Last Modified:  $(date -R -r list.txt)"/ list.txt &&
./addChecksum.pl list.txt &&

# save self change to git
git commit -a -m "$*" &&

# commit to remote svn server
base64 list.txt > gfwlist.txt &&
svn ci gfwlist.txt -m $( echo "$*" | base64 -w 0) &&

rm temp.patch;

