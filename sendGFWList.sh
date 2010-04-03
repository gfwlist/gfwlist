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
#   Commit your encoded changes to remote svn server with encoded log.
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
#   1: You can use "$git log" "$git show" "$git diff"...;
#   2: Do NOT commit "list.txt" to svn server (it won't by default);
#   3: Do NOT use any unicode character in the list, there is a known bug;
#   4: Do NOT "svn update", run this script to update / commit at any time.
################################################################################

# dependence
for cmd in sed date base64 gawk svn git perl
do
  which $cmd &> /dev/null;
  if [ $? -ne 0 ]; then
    echo "Depends on $cmd, please install it first.";
    exit 1;
  fi
done

# get formated author and log information
log=$(svn log -r BASE:HEAD) &&
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
    convertedLog+=": ";
    # discard used string
    log=${log#*:};
  else                # log, decode it
    temp=$( echo ${log%%;*} | base64 -d);
    convertedLog+=$temp;
    convertedLog+="\n";
    log=${log#*;};
  fi
  ((i++));
done

# modified by others, commit to local git repository.
if [ "$convertedLog" != "" ]; then
  svn update &&

  # save local modification
  [ -n "$(git diff)" ] && git diff > temp.patch; 

  base64 -d gfwlist.txt > list.txt &&
  echo -e $convertedLog | git commit -a -F - ;

  # apply local modification
  [ -s temp.patch ] && git apply temp.patch &&
  rm temp.patch;
fi

if [ "$(git diff)" == "" ]; then
  echo "list.txt not modified.";
  exit 0;
fi

if [ "$*" == "" ]; then
  echo "Empty log, please say something about this modification.";
  exit 1;
fi

# make sure the list doesn't contain unicode chars
file list.txt | grep ASCII 1> /dev/null ||
(
  echo "List contains non-ASCII characters, please remove them." &&
  exit 1;
) &&

# update date and checksum
sed -i s/"Last Modified:.*$"/"Last Modified:  $(date -R -r list.txt)"/ list.txt &&
./addChecksum.pl list.txt &&

# save self change to git. exit directly if conflicting.
git commit -a -m "$*" &&

# commit to remote svn server
base64 list.txt > gfwlist.txt &&
(
  # "svn ci" and "git commit" are atomic operations
  svn ci gfwlist.txt -m $( echo "$*" | base64 -w 0) ||
  # "svn ci" may be failed because of connection problems.
  git reset HEAD^ 1> /dev/null;
) &&

# BASE++, HEAD++, if committed.
svn update 1> /dev/null;

