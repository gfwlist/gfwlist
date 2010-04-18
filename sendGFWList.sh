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
for cmd in sed date base64 gawk svn git perl file
do
  which $cmd &> /dev/null;
  if [ $? -ne 0 ]; then
    echo "Error: depends on $cmd, please install it first.";
    exit 1;
  fi
done

# get formated author and log information
log=$(svn log -r BASE:HEAD) || exit 1;
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
    temp=$( echo ${log%%;*} | base64 -d );
    convertedLog+=$temp;
    convertedLog+="\n";
    log=${log#*;};
  fi
  ((i++));
done

# modified by others, commit to local git repository
if [ "$convertedLog" != "" ]; then
  git diff > temp.patch &&

  svn update || exit 1;

  base64 -d gfwlist.txt > list.txt && ./validateChecksum.pl list.txt;
  if [ $? -ne 0 ]; then
    echo "Error: gfwlist.txt from svn is invalid!";
    echo "It must be a download error or somebody made a mistake.";
    echo "Please check with the last committer or report to maintainers group.";
    exit 1;
  fi

  echo -e $convertedLog | git commit -a -F - &&

  [ -s temp.patch ] && git apply temp.patch &&
  rm temp.patch &&

  # remove (if exist) empty temp.patch
  [ ! -s temp.patch -a -e temp.patch ] && rm temp.patch;
fi

if [ "$(git diff)" == "" ]; then
  echo "Info: list.txt not modified.";
  exit 0;
fi

if [ "$*" == "" ]; then
  echo "Error: empty log, please say something about this modification.";
  exit 1;
fi

if [ "$(file list.txt)" != "list.txt: ASCII text" ]; then
  echo "Error: list.txt, please make sure:";
  echo "1. there is no non-ASCII characters;";
  echo "2. configure your text editor to use unix style line break.";
  exit 1;
fi

# update date and checksum
sed -i s/"Last Modified:.*$"/"Last Modified: $(date -Rr list.txt)"/ list.txt &&
./addChecksum.pl list.txt &&

# save local changes to git & svn
# if conflict or network problem occurs: do nothing & throw error message
git commit -a -m "$*" &&
(
  base64 list.txt > gfwlist.txt &&

  # may be running under Windows + Cygwin?
  # convert dos new line to unix style, old mac style ignored
  sed -i 's/\r$//g' gfwlist.txt &&

  # may be failed because of connection/authentication problems
  svn ci gfwlist.txt -m $( echo "$*" | base64 -w 0) ||

  # "svn ci" and "git commit" are atomic operations
  git reset HEAD^ 1> /dev/null;
) &&

# BASE++ if committed
svn update 1> /dev/null;
