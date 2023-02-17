#!/bin/bash

err_report() {
    echo >&2 "$PNAME : Error on line $1"
    echo >&2 "$PNAME : Please report this issue at\
'https://github.com/McUsr/FB/issues'"
}

export ROOTFOLDERS="OneShot Periodic"

export SCHEMEFOLDERS="Daily DailySnapshot DailyIncremental DailyDifferential\
  Weekly WeeklyIncremental WeeklyDifferential Monthly MonthlyIncremental\
  MonthlyDifferential"


# ok_version()
# returns 0 if the bash version >= 4.2, because that's
# the one with arrays. declare -g, and test -v
# https://wiki.bash-hackers.org/scripting/bashchanges
ok_version() {
  if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 2 ]] ; then
    return 1
  elif [[ ${BASH_VERSINFO[0]} -lt 4 ]]  ; then
    return 1
  else
    return 0
  fi
}


# isASymlink()
# RETURNS 0 if the parameter is a symlink.
# PARAMETER: A symlink
# ( I need the full path to the file, to be able to check it. {realpath} )
isASymlink() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
  file "$1" | grep 'symbolic link' >/dev/null
  return $?
}


# isUnbrokenSymlink()
# RETURNS 0 if the  the symlink is okay.
# PARAMETER: A symlink
isUnbrokenSymlink() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
  if file "$1" | grep 'broken symbolic link' >/dev/null  ; then
    return 1
  fi
  return 0
}


# isWithinPath ()
# PARAMETERS: path1, path2
# Checks if path1 is within path2.

isWithinPath (){ 

  if [[ $# -ne 2 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} : I really need two paths as \
      arguments.\nTerminating..."
    exit 5
  fi
  local probe="${1/$2/}"
  if [[ "$probe" != "${1}" ]] ; then
    # If the probe is shorter, then $2 was chopped off the start of $1
    # because $2 was a  path that contained $1.
    return 0
  else
    return 1
  fi
}

if [[ 0 -eq 1 ]] ; then
# isDirectory()
# RETURNS 0 if is a directory, !0 if not.
# PARAMETER: Path.
isDirectory() {
if [[ $# -ne 1 ]] ; then echo -e >&2 "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
  file "$1" | grep 'directory' >/dev/null
  return $?
}
fi

# hasInternet()
# RETURNS 0 if we're connected, 1 if note
# Needs ping which can be installed by:
# sudo apt install iputils-ping
# `which ping` checks if it is already on your system.

hasInternet() {
  if ping -c 1 -q google.com >&/dev/null ; then
    return 0
  else
    return 1
  fi
}
# export -f hasInternet


# progress_bar()
# shows a "progress bar" for routines that takes time.
progress_bar() {
  trap 'export toquit=true' TERM
  toquit=false
  while true ; do
    printf "%s" "." >/dev/tty
    sleep 3
    if [[ $toquit == true ]] ; then
      exit 0
    fi
  done
}

export -f progress_bar

# servHasInetCtrlC() 
# interrupt handler that sees to that the "progress_bar" stops.
servHasInetCtrlC() {
  if [[ $pbar_pid -ne 0 ]] ; then
    kill "$pbar_pid" ; sleep 1 ; echo >/dev/tty
  fi
  kill $$
}
export -f servHasInetCtrlC

# consoleHasInternet()
# checks if we have our Internet connection
# and times out if we haven't got it still, after 5 minutes.
# both SERVICE_MODE and DEBUG_MODE
# dies, TODO:  Maybe die in the name.
consoleHasInternet() {
trap 'servHasInetCtrlC' INT

  SECONDS=0
  if [[ $# -ne 1 ]] ; then
    if [[ ! -t 1 ]] ; then
      notify-send "${0##*/}/${FUNCNAME[0]}" "I need a parameter for the \
BACKUP_SCHEME in use!\nTerminating... "
    echo -e "${0##*/}/${FUNCNAME[0]} I need a parameter for the\
      BACKUP_SCHEME in use!\nTerminating... " | journalThis 5 FolderBackup
    else
      echo -e >&2 "${0##*/}/${FUNCNAME[0]} I need a parameter for the\
      BACKUP_SCHEME in use!\nTerminating... " 

    fi
    exit 5
  fi
  local inet_gone=false passed_three=false
  declare -g pbar_pid=0
  while true ; do
    if hasInternet ; then
      if [[ $inet_gone == true ]] ; then

        if [[ -t 1 && $pbar_pid -ne 0 ]] ; then
          kill $pbar_pid; sleep 1
        fi

        if [[ ! -t 1 ]] ; then
          notify-send "${0##*/}/${FUNCNAME[0]}" "Your internet connection is \
back. Continuing." &
        else
          echo >/dev/tty
        fi
         echo "${0##*/}/${FUNCNAME[0]}  :Your internet connection is back. \
Continuing..."  | journalThis 5 "$1"  &
      fi
      break
    else
      if [[ $SECONDS -ge  300 ]] ; then
        if [[ ! -t 1 ]] ; then
          notify-send  "${0##*/}/${FUNCNAME[0]}" "No internet connection in 5\
 minutes. Giving up...."
        else
          kill $pbar_pid; sleep 1; pbar_pid=0
          echo  >/dev/tty
        fi
        echo  "${0##*/}/${FUNCNAME[0]} : No internet connection in 5\
minutes. Giving up..."  | journalThis 2 "$1" &
        exit 255
        if [[ -t 1 ]] ; then echo >/dev/tty ; fi
      else
        if [[ $inet_gone == false || $SECONDS -ge 180 ]] ; then

          if [[ $passed_three == false ]] ; then
            passed_three=$inet_gone
            if [[ ! -t 1 ]] ; then
              notify-send "${0##*/}/${FUNCNAME[0]}" "You have no internet\
 connection. Retrying in 3 minutes..." &
            else
              if [[  $pbar_pid -ne 0 ]] ; then
                kill $pbar_pid; sleep 1; pbar_pid=0
                echo  >/dev/tty
              fi
            fi
            echo  "${0##*/}/${FUNCNAME[0]} : You have no internet\
 connection. Retrying in 3 minutes..."  | journalThis 2 "$1" &
          fi
          inet_gone=true
          if [[ -t 1 && $pbar_pid -eq 0 ]] ; then
            progress_bar &
            pbar_pid=$!
          fi
        fi
        sleep 2
      fi
    fi
  done
}

# export -f consoleHasInternet

# consoleFolderIsMounted()
# Checks if our Destination folder is mounted, and times out if it still isn't
# after 5 minutes.  from the command line.
# both SERVICE_MODE and DEBUG_MODE
# dies, TODO:  Maybe die in the name.
consoleFBfolderIsMounted() {
trap 'servHasInetCtrlC' INT
# borrowed from consoleHasInternet
  SECONDS=0
  if [[ $# -ne 1 ]] ; then
    if [[ ! -t 1 ]] ; then
      notify-send "${0##*/}/${FUNCNAME[0]}()"  "I need a parameter for the \
BACKUP_SCHEME in use!\nTerminating... "
    fi
    echo -e "${0##*/}/consoleFBFolderIsMounted()  I need a parameter for the\
      BACKUP_SCHEME in use!\nTerminating... " 1>&2
    exit 5
  fi
  local  no_mounted_folder=false passed_three=false
  while true ; do
    if [[  -d "$FB" ]] ; then
        if [[ $no_mounted_folder == true ]] ; then

          if [[ -t 1 && $pbar_pid -ne 0 ]] ; then
            kill $pbar_pid; sleep 1
          fi

          if [[ ! -t 1 ]] ; then
            notify-send "${0##*/}/${FUNCNAME[0]}" "You have successfully \
mounted \$FB: $FB Continuing..." &
        else
          echo >/dev/tty
        fi
        echo -e "${0##*/} : You have successfully mounted \$FB:\n$FB\n\
Continuing..." | journalThis 5 "$1" &
        fi
        break
    else
      if [[ $SECONDS -ge 300 ]] ; then
        if [[ ! -t 1 ]] ; then
          notify-send "${0##*/}/${FUNCNAME[0]}" "No mounted folder \$FB: \
$FB in 5 minutes. Giving up..." | journalThis 2 "$1"
        else
          kill $pbar_pid; sleep 1; pbar_pid=0
          echo  >/dev/tty
        fi
        echo -e "${0##*/}/${FUNCNAME[0]} : No mounted folder \$FB:\n $FB in \
5 minutes. Giving up..." | journalThis 2 "$1"
        exit 255
        if [[ -t 1 ]] ; then echo >/dev/tty ; fi
      else
        if [[ $no_mounted_folder == false || $SECONDS -ge 180 ]] ; then

          if [[ $passed_three == false ]] ; then
            passed_three=$no_mounted_folder
            if [[ ! -t 1 ]] ; then
              notify-send  "${0##*/}/${FUNCNAME[0]}" "You have forgotten to \
mount/create the root  backupfolder \$FB: $FB. Retrying in 3 minutes..."
            else
              if [[  $pbar_pid -ne 0 ]] ; then
                kill $pbar_pid; sleep 1; pbar_pid=0
                echo  >/dev/tty
              fi
            fi
            echo "${0##*/}/${FUNCNAME[0]} You have forgotten to mount/create \
the root \ backupfolder \$FB: $FB. Retrying in 3 minutes" \
| journalThis 5 "$1"
          fi
          no_mounted_folder=true
          if [[ -t 1 && $pbar_pid -eq 0 ]] ; then
            progress_bar &
            pbar_pid=$!
          fi
        fi
        sleep 2
      fi
    fi
  done
}


export -f consoleFBfolderIsMounted

# TODO: Error output to journal-ctl for backupKind and periodic BackupScheme:
# I might use the methods I learned with regards to redirecting, the thing
# is, I have to send to systemd-cat.  maybe periodicBackupScheme comes in two
# flavors, daemon and console, due to journalling.  - not sure if it is
# necessary when it comes to daemons.


# backupKind()
# Figures out which KIND of backup we are restoring,
# RETURNS: 'OneShot', or 'Periodical', so we know what to do in 'fbrestore'
backupKind() {
  if [[ $# -ne 1 ]] ; then
    echo -e >/dev/tty"${0##*/}/${FUNCNAME[0]} : Need an  argument: \
backup/kind/scheme \nTerminates" >&2 ;
    exit 5
  fi
  local  ORIG="$1" REPLACED="${1/$FB/}"
  if [[ "$ORIG" = "$REPLACED" ]] ; then
    echo -e >/dev/tty "${0##*/}/${FUNCNAME[0]} : The path to the backup \
isn't within  the defined location.\nTerminating..."
    exit 2
  elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then
    echo -e >/dev/tty "${0##*/} : The path to the backup isn't complete with \
a path to the actual backup.\n($FB isn't specific enough,\nthe path must \
include the folder from which to restore.)\nTerminating..."
    exit 2
  fi
  OLDIFS=$IFS
  export IFS='/'
# shellcheck disable=SC2086 # NO QUOTING == disastrous!
  set -- $REPLACED

  # the path starts with a delimiter, so $1 will contain '' for the empty
  # element at front to the left of the delimiter.
  if [[  -n "$1"  ]] ; then
    echo -e >/dev/tty "${0##*/} : The path to the backup \
starting with the KIND doesn't\ start with '/'.\n Is it a slash amiss after \
\$FB\n($FB)\n in the path to the backup ($ORIG)?\nTerminating..."
  exit 2
  fi
  export IFS=$OLDIFS
  echo "$2"
}

# periodicBackupScheme
# RETURNS: the 'Periodic' Backup Scheme for a folder, so that the type of
# restore can be identified by fbrestore.

periodicBackupScheme() {
  if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an \
 argument: backup/kind/scheme \nTerminates" >&2 ; exit 5 ; fi
  local  ORIG="$1"
  local BIT_TO_REMOVE=$FB/Periodic
   local REPLACED="${1/$BIT_TO_REMOVE/}"
  if [[ "$ORIG" = "$REPLACED" ]] ; then
    echo -e >&2 "${0##*/} : The path to the backup isn't within  the defined\
      location.\nTerminating..."
    exit 2
  elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then
    echo -e >&2 "${0##*/} : The path to the backup isn't complete with a path to\
      the actual backup.\n($FB isn't specific enough,\nthe path must include\
      the folder from which to restore.)\nTerminating..."
    exit 2
  fi
  OLDIFS=$IFS
  IFS=/
# shellcheck disable=SC2086 # NO QUOTING == disastrous!
  set -- $REPLACED
# the path starts with a delimiter so $1 will contain '' for the empty element
# at front to the left of the delimiter.  shellcheck disable=SC2157 # code is
# irrelevant because we may get '' out of the set command.

  if [[ -n "$1"  ]] ; then
    echo -e >&2 "${0##*/} : The path to the backup starting\
  with the KIND doesn't\ start with '/'.\n Is it a slash amiss after \$FB\
  ($FB)\n in the path to\ the backup ($ORIG)?\nTerminating..."
     exit 2
  fi
  export IFS=$OLDIFS
  echo "$2"
}


# identifyBackupSourceFolder()
# Param1: 'BackupKind/BackupScheme'
# Param2:   '/Our/parameter/for/a/folder/or/file/to/back/up'
# The path is alredy confirmed to exist.
# Returns the path to the sourcefolder in 'full-symlink-format'

# Example: identifyBackupSourceFolder Periodic/DailySnapshot\
# $FB/Periodic/Daily/etc-apache/apache-2023-01-01
# RETURNS: etc-apache

# Example: identifyBackupSourceFolder\
# Periodic/OneShot/etc-apache/apache-2023-01-01
# RETURNS: etc-apache
identifyBackupSourceFolder() {

  if [[ $# -ne 2 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} : I really need two arguments.\
\nTerminating..."
    exit 5
  fi

  local ORIG="$2"
  local BIT_TO_REMOVE=$FB/$1
  local REPLACED="${2/$BIT_TO_REMOVE/}"
  if [[ "$ORIG" = "$REPLACED" ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} : The path to the backup isn't within \
the defined location.\nTerminating..."
    exit 2
  elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} : The path to the backup isn't complete \
with a path to the actual backup.\n($FB/$1 isn't specific enough,\nthe path \
must include the folder from which to restore.)\nTerminating..."
    exit 2
  fi
  OLDIFS=$IFS
  export IFS=/
# shellcheck disable=SC2086 # NO QUOTING == disastrous!
  set -- $REPLACED
  # the path starts with a delimiter, so $1 will contain '' for the empty
  #  element at front to the left of the delimiter.
  if [[ -n $1 && "$1" != "\""  ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} : The path to the backup starting with \
the PREFIX doesn't start with '/'.\n Is it a slash amiss after \$FB ($FB)\n \
in the  path to the backup ($ORIG)?\nTerminating..."
    exit 2
  fi
  export IFS=$OLDIFS
  echo "$2"
}

# validateFormatOfTimeStampedBackupContainingFolder()
# PARAMETERS: A backup containting folder to validate the name-format of.
# Returns: A true exit code (0) if the name was valid.

validateFormatOfTimeStampedBackupContainingFolder() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]} :\nI really need one argument. \
\nTerminating..."
  fi
   echo "$1" |  grep '.*[-][1-2][09][0-9][0-9][-][01][1-9][-][0-3][0-9]'\
     >/dev/null
   return $?
}


# identifyTimeStampedBackupContainingFolder()
# PARAMETERS: Stem consisting of backup kind and eventually a scheme,
# and the bucket (a folder named by its full symlink name,
# consisting of the full path to the to the source-folder).
# AND THE FULL PATH TO THE BACKUP AS PARAMETER2!
# RETURNS: The folder that contains the actual backups
# of the source folder, IF it's name  is on the proper form.
#
# Example:
# identifyTimeStampedBackupContainingFolder 'OneShot/var-html/'\
# '/pathtoFB/OneShot/var-html/html-2023-01-08/'
# RETURNS: '/var/html'

# Example2:
# identifyTimeStampedBackupContainingFolder 'Periodic/DailySnapshot/var-html/'\
# '/pathtoFB/Periodic/DailySnapshot/var-html/html-2023-01-08/'
# RETURNS: '/var/html'
identifyBackupContainerByTimeStampedFolder() {

# TODO: BACKUP_CONTAINER better than:
# TimeStampedBackupContainingFolder

  if [[ $# -ne 2 ]] ; then
    echo -e >&2 "${0##*/} : I really need two arguments for\
${FUNCNAME[0]}\nTerminating..."
    exit 5
  fi
  local ORIG="$2"
  local DEESCAPED_ORIG BIT_TO_REMOVE DEESCAPED_BIT_TO_REMOVE REPLACED
  DEESCAPED_ORIG="$( echo "$ORIG" | sed -ne 's:\\::g' -e 'p' )"
  BIT_TO_REMOVE="$FB/$1"
  DEESCAPED_BIT_TO_REMOVE=\
"$(echo "$BIT_TO_REMOVE" | sed -ne 's:\\::g' -e 'p')"
  local DBG_ESC=1
  if [[ $DBG_ESC -eq 0 ]] ; then
    echo ORIG : "$ORIG" >&2
    echo DEESCAPED_ORIG : "$DEESCAPED_ORIG" >&2
    echo BIT_TO_REMOVE :"$BIT_TO_REMOVE" >&2
    echo DEESCAPED_BIT_TO_REMOVE : "$DEESCAPED_BIT_TO_REMOVE" >&2
  fi
  REPLACED="${DEESCAPED_ORIG/$DEESCAPED_BIT_TO_REMOVE/}"
  if [[ "$ORIG" = "$REPLACED" ]] ; then
    echo -e "${0##*/} : The path to the backup isn't within  the defined\
      location.\nTerminating..." >&2
    exit 2
  elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : \nThe path\ to the backup isn't \
complete with a path to the actual backup.\n($FB/$1\ isn't specific \
enough,\nthe path must include the folder from which to restore,\n and a \
timestamped folder that contains the actual files containing the backup.)\
\nTerminating..." >&2
    exit 2
  fi
  OLDIFS=$IFS
  export IFS='/'
# shellcheck disable=SC2086 # NO QUOTING == disastrous!
  set -- $REPLACED
  # the path starts with a delimiter, so $1 will contain '' for the empty
  # element at front to the left  of the delimiter.
# echo >/dev/tty "1 : ,$1,"
  if [[ -n "$1"  ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : \nThe path to the backup starting with\
 the PREFIX doesn't start with '/'.\n\ Is it a slash amiss after \$FB\n\
($FB)\n in the path to the backup\ ($ORIG)?\nTerminating..." >&2
    exit 2
  fi
  export IFS=$OLDIFS
  # We check here if the folder conforms with the naming standard.
  if validateFormatOfTimeStampedBackupContainingFolder "$2" ; then
    echo "$2" | sed -ne 's:^\.:\\.:' -e 'p'
  else
    echo -e "${0##*/}/${FUNCNAME[0]} : \nThe name of the folder that is \
supposed to be a timestamped folder,\n that consists of the name of the \
original folder and a timestamp, isn't on the correct format.\
\n($2)?\nTerminating..." >&2
    exit 2
  fi
}

# baseFromFullSymlinkName()
# RETURNS: the base folder name from a full symlink-name.
# PARAMETER: full-symlink-name
# Ex: `baseFromFullSymlinkName usr-share-fonts`
# returns `fonts`
# and before that, I have to figure out todays name.
baseFromFullSymlinkName() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
echo "$1" |  sed -n  's:^.*[-]::p'
}

# baseNameDateStamped()
# returns the base folder name from a full symlink-name with
# Todays iso8601 datestamp appended.
# Ex: `baseNameDateStamped usr-share-fonts-`
# returns `fonts-2023-01-12`
baseNameDateStamped() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
# shellcheck disable=SC2046 # code is irrelevant because reasons
  echo $(echo "$1" |  sed -n  's:^.*[-]::p')-$(date +"%Y-%m-%d")
}

# baseNameTimeStamped()
# returns the base folder name from a full symlink-name with
# an iso8601 datestamp and time appended.
# Ex: `baseNameDateStamped usr-share-fonts`
# returns `fonts-2023-01-12T12:14`
baseNameTimeStamped() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
# shellcheck disable=SC2046 # code is irrelevant because reasons
  echo $(echo "$1" |  sed -n  's:^.*[-]::p')-$(date +"%Y-%m-%dT%H:%M")
}


# baseNameFromBackupFile()
# returns the base folder name which is the name of the tarball,
# without the suffix.
# it handles invisible files.

baseNameFromBackupFile() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates" >&2 ; exit 5 ; fi
  echo "$1"  | sed -n 's,\(.*[-][^.]\+\).*,\1,p'
}


# validPathOrFileName()
# Returns 0 if the path is legal
# it returns true for two / in a row,
# but that IS legal in Unix/Linux
# $HOME//docs/tech is a legal path.
# where the superfluous '/' is simply
# ignored.
# TODO: FIX FOR invisible names?
# TODO: TEST AND FIX BEFORE USE.
validPathOrFileName() {
  grep -En '^/?(([A-Za-z]|[-_+.])+/?)+$' &>/dev/null
  return $?
}


# hasLevel0SnarFile()
# is called from both incremential and
# differential routines to assert that
# we have indeed the level0 snar file.

function hasLevel0SnarFile() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]}: I need exactly 1\
      parameter.\nTerminating"
    exit 5
  fi
  if [[ ! -f "$1" ]] ; then
    echo -e >&2 "${0##*/} : I can't find the file $1, something is terribly \
wrong.\nTerminating..."
    # Will be passed ont crit err in log, but will also make a notifcation.
    exit 9
  fi
}


# nextSnarFile()
# Used for *differential backups*. Takes a name
# of the form base.{number}.suffix and finds
# the first file name, with a higher number in
# it, that doesn't exist.

nextSnarFile() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]}: I need exactly 1\
      parameter.\nTerminating"
    exit 5
  fi
  IFS='.'
  set "$1"
  newNum=1
  # we start
  newfile=$1.$newNum.$3
  while [[ -f "$newfile" ]] ; do
    newNum=$(( newNum + 1 ))
    newfile=$1.$newNum.$3
  done
  echo "$newfile"
}

# fullPathSymlinkName()
# PARAMETERS: the full path to convert.

# RETURNS: the fullPath of the folder we want to create a symlink to,, so that
# there is no ambiguity, as to which folder the symlink points to.

fullPathSymlinkName() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "${0##*/}/${FUNCNAME[0]}: I need exactly 1\
      parameter.\nTerminating"
    exit 5
  fi
  local fn
  fn=$(realpath "$1")
  echo "$fn" | sed -ne 's:^/::' -e 's:/:-:g' -e 's:^\.:\\.:' \
    -e 's:[-]\(\.\):-\\\1:' -e 'p'
}

# pathFromFullSymlinkName(){
# PARAMETERS: the full symlink name to convert.
# RETURNS the fullSymlinkName back to the path it once was.
# Add a trailing slash yourself, on the outside, shoud you need one.

pathFromFullSymlinkName() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "${0##*/}/pathFromFullSymlinkName: I need exactly 1 parameter.\
      \nTerminating"
    exit 5
  fi
  echo "$1" | sed -ne  's:^:/:' -e 's:-:/:g' -e ':/(.*/)$:\1\/:g' \
    -e 's:\\::' -e 'p'
}

# journalThis()
# Sends output to the journal, not sure of the utility for most commandline\
# commands can be useful for fbinstall and fbctl though. so we can keep track\
# of jobs and their  status, insulating the file system.
# PARAMETERS:
#   LOGLEVEL : the log level the message shall be filed under
#   TAG: the tag the message should be tagged under.
# GLOBAL VARIABLES:
#   LOG_TO_JOURNAL : If this variable is set, and true, then the message will\
# be sent to the  log, otherwise, the message will be sent to the console.

journalThis() {

  if [[ $# -ne 2 ]] ; then
    echo -e >&2 "${0##*/}/journalThis(): I really need two \
parameters.\nTerminating..."
    exit 5
  fi
  if [[ "$MODE" == "SERVICE" ]] ; then
# shellcheck disable=SC2086 # code is irrelevant because in sed expression.
tee >(cat 1>&2) | sed -n '/[a-z][A-Z]*/ s:^:<'''$1'''>:p' \
      | systemd-cat -t "$2"
  else
    cat 1>&2
  fi
}

# assertSchemeContainer()
# asserts that both the $FB/Periodic and the 
# $FB/Periodic/$BACKUP_SCHEME folder exists.

assertSchemeContainer() {

  if [[ $# -ne 1 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need an  argument: \
backup/kind/scheme \nTerminates..." >&2 ;
    exit 5
  fi

  local BACKUP_SCHEME=${1}

  mkdir -p "$FB/Periodic"
  # just in case, no harm, no foul.

  SCHEME_CONTAINER="$FB/Periodic/$BACKUP_SCHEME"
  if [[ ! -d "$SCHEME_CONTAINER" ]] ; then
    mkdir -p "$SCHEME_CONTAINER"
    # we can go silent about this, or we can just send a message.
    if [[ $DEBUG -eq 0 ]] ; then
      echo >&2 "$SCHEME_CONTAINER didn't exist, que to make backup"
    fi
  else
    if [[ $DEBUG -eq 0 ]] ; then
      echo >&2 "$SCHEME_CONTAINER exists, NO que to make backup"
    fi
  fi
  echo "SCHEME_CONTAINER"
}

export -f journalThis
# manager()
# find the correct script/dropin-script to execute if any:
# Passes the DELEGATE back to the caller by  global  DELEGATE_SCRIPT variable.
# PARAMETERS (mandatory!)
# BACKUP_SCHEME, or kind what considers OneShot.
# SYMLINK_NAME
# OPERATION backup/restore, so we can use it everywhere.

manager() {
  declare -g DELEGATE_SCRIPT
  local CANDIDATE_SCRIPT

  if [[ $# -ne 3 ]] ; then
    echo -e  "$PNAME/manager() : Wrong number of arguments, I need \
BACKUP_SCHEME SYMLINK_NAME OPERATION\nTerminates..." \
      | journalThis 2 "$BACKUP_SCHEME"
    exit 5
  else
    BACKUP_SCHEME=$1
    SYMLINK_NAME=$2
    OPERATION=$3

    if [[ $OPERATION != "backup" && $OPERATION != "restore" ]] ; then
      echo -e  "$PNAME/manager() : Wrong value for \$OPERATION, MUST  be\
either\"backup\" or \"restore\".\nTerminates..."\
        | journalThis 2 "$BACKUP_SCHEME"
    exit 5
    fi
  fi

  dieIfNotSchemeBinFolderExist "$BACKUP_SCHEME"

  local SCHEME_BIN_FOLDER=$XDG_BIN_HOME/fb/$BACKUP_SCHEME

  local CANDIDATE_SCRIPT="$SCHEME_BIN_FOLDER"/"$BACKUP_SCHEME"."$OPERATION".sh

  if [[ ! -x "$CANDIDATE_SCRIPT" ]] ; then
    # same if with DRYRUN or VERBOSE
    echo -e "$PNAME/manager() : I can't find the backup script\
      $CANDIDATE_SCRIPT.\nThis is a critical error.\nTerminates..."\
      | journalThis 2 "$BACKUP_SCHEME"
    exit 255
  else

    DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
    if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then
      echo "$PNAME/manager() : Current backup script is : $DELEGATE_SCRIPT"\
        | journalThis 7 "$BACKUP_SCHEME"
    fi
  fi
# Looking for a GENERAL replacement is in the $BACKUP_SCHEME.d folder.

  CANDIDATE_SCRIPT=\
"$XDG_BIN_HOME"/fb/"$BACKUP_SCHEME"/"$BACKUP_SCHEME".d/"$BACKUP_SCHEME"."$OPERATION".sh
  if [[  -f "$CANDIDATE_SCRIPT" ]] ; then
    if [[ $DEBUG -eq 0 || $VERBOSE = true || $DRYRUN = true ]] ; then
      echo "$PNAME/manager() :  I have a readable backup script: \
$CANDIDATE_SCRIPT." | journalThis 7 "$BACKUP_SCHEME"
    fi
    if [[ ! -x "$CANDIDATE_SCRIPT" ]] ; then
      echo -e "$PNAME/manager() :  I found a backup dropin script: \
$CANDIDATE_SCRIPT\nBut it isn't executabe.\nTerminates.."\
        | journalThis 7 "$BACKUP_SCHEME"
      exit 5
    else
      DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
      if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then
        echo "$PNAME/manager() : I found a GENERAL backup dropin script: \
Current backup script is : $DELEGATE_SCRIPT"  | journalThis 7 "$BACKUP_SCHEME"
      fi
    fi
  elif [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then
    echo "$PNAME/manager() : I didn't find  a GENERAL backup dropin script \
at: $CANDIDATE_SCRIPT." | journalThis 7 "$BACKUP_SCHEME"
  fi
# Looking for a LOCAL replacement is in the $BACKUP_SCHEME.d folder.
  CANDIDATE_SCRIPT=\
"$XDG_BIN_HOME"/fb/"$BACKUP_SCHEME"/"$SYMLINK_NAME".d/"$BACKUP_SCHEME"."$OPERATION".sh

  if [[  -f "$CANDIDATE_SCRIPT" ]] ; then
    if [[ $DEBUG -eq 0 || $VERBOSE = true || $DRYRUN = true ]] ; then
      echo "$PNAME/manager() : I have a readable LOCAL dropin backup script:\
        $CANDIDATE_SCRIPT." | journalThis 7 "$BACKUP_SCHEME"
    fi
    if [[ ! -x "$CANDIDATE_SCRIPT" ]] ; then
      echo -e "$PNAME/manager() :  I found a LOCAL backup dropin script:\
        $CANDIDATE_SCRIPT.\nBut it isn't executabe.\nTerminates.."\
        | journalThis 7 "$BACKUP_SCHEME"
      exit 5
    else
      DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
      if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then
        echo "$PNAME/manager() : I found a LOCAL backup dropin script :\
          Current backup script is : $DELEGATE_SCRIPT"\
          | journalThis 7 "$BACKUP_SCHEME"
      fi
    fi
  elif [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then
    echo "$PNAME/manager() : I didn't find  a LOCAL backup dropin script in\
      : $CANDIDATE_SCRIPT." | journalThis 7 "$BACKUP_SCHEME"
  fi

}


# verifyEditorToUse()
# selects VISUAL over EDITOR
# sets global THE_EDITOR with the correct editor.
# RETURNS: any error code.
dieIfNoEditorSetToUse() {
  declare -g THE_EDITOR
  FOUND_EDITOR=1

  if [[  -v VISUAL  ]] ; then
    if type -a "$VISUAL" &>/dev/null ; then
      # if 0, found  executable
       FOUND_EDITOR=0 ; THE_EDITOR="$VISUAL"
    fi
  fi

  if [[ $FOUND_EDITOR -eq 0 && -v EDITOR  ]] ; then
    if type -a "$EDITOR" >/dev/null ; then
       FOUND_EDITOR=0 ; THE_EDITOR="$EDITOR"
    fi
  fi
  if [[ $FOUND_EDITOR -ne 0  ]] ; then
    echo -e  "$PNAME : Neither the  variable \$VISUAL nor \$EDITOR was set\
      or didn't point to a binary.\nYou need to set assign the\
      \$EDITOR variable in .bashrc or .bash_profile, then  \"exec bash\" and\
      try again.\nTerminating..." | journalThis 5 OneShot
    exit 255
  fi

}

# dieIfNotValidFullSymlinkName()
# PARAMETERS: SYMLINKNAME SCHEME
# RETURNS: 0, if the symlink name is valid.
dieIfNotValidFullSymlinkName() {
  if [[ $# -ne 2 ]] ; then echo -e  "${0##*/}/${FUNCNAME[0]} : I need two\
    arguments full-symlink-name and scheme.\nTerminates" >&2 ; exit 5 ; fi
  local FULL_SYMLINK_NAME SCHEME
  FULL_SYMLINK_NAME="$1" ; SCHEME=$2
  if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} :FULL_SYMLINK_NAME : $FULL_SYMLINK_NAME"\
      | journalThis 7 "$SCHEME"
  fi
  full_path="$(pathFromFullSymlinkName "$FULL_SYMLINK_NAME")"
  if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} :full_path after :\
      \$(pathFromFullSymlinkName \"\$FULL_SYMLINK_NAME\") : $full_path"\
       | journalThis 7 "$SCHEME"
  fi
  symlink_probe="$(fullPathSymlinkName "$full_path" )"

  if [[ "$FULL_SYMLINK_NAME" != "$symlink_probe" ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : $FULL_SYMLINK_NAME Not a valid symlink\
      name! \nTerminates" >&2 ; exit 5
   fi
}

# dieIfNotValidFbFolderName()
# returns 0 if the folder name within XDG_BIN_HOME/fb given, is a valid one
# TODO: We must premake the folders? Better name, including bin?

dieIfNotValidFbFolderName() {

  if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : I need 1\
    argument.\nTerminates" >&2 ; exit 5 ; fi
  local validFbFolderNames
  validFbFolderNames=( OneShot HourlySnapshot HourlyIncremental \
    HourlyDifferential DailyFull WeeklyFull  WeeklyIncremental \
    WeeklyDifferential MonthlyFull MonthlyDifferential \
    MonthlyIncremental )
  FOUND_SCHEME=1
  for backup_category in "${validFbFolderNames[@]}" ; do
     if [[ $1 = "$backup_category" ]] ; then
      FOUND_SCHEME=0
      break
    fi
  done
  if [[ $FOUND_SCHEME -ne 0 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : $2 Not a valid scheme folder name in\
      the $XDG_BIN_HOME/fb folder! \nTerminates"\
      | journalThis 2 FolderBackup ; exit 2
    # error_code 2, because can be user set from the command line.
  fi
}


# excludeFileHasContents()
# We check if it is isn't empty, and if it is, then we check if
# there is something that can pass for a glob in there.
# PARAMETERS:
# backup_scheme (hopefully vetted)
# symlink name (full symlink name)

excludeFileHasContents() {
  if [[ $# -ne 2 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need two\
    argument\nTerminates" >&2 ; exit 5 ; fi
  local probe backup_scheme symlink_name
  # we have always vetted the parameters backup_scheme and symlink_name
  #  up front by our Callers.
  backup_scheme="$1"
  symlink_name="$2"

  probe="$XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d/exclude.file"

  if [[ -s "$probe" ]] ; then
    if [[ $DEBUG -eq 0 || $VERBOSE == true || $DRYRUN == true ]] ; then
        echo >&2 "$PNAME/${FUNCNAME[0]} : maybe we have an exclude file with\
          contents"
    fi
    grep '[-/.@+a-zA-Z0-9]\+'  < "$probe" &>/dev/null
    return $?
  else
    if [[ $DEBUG -eq 0 || $VERBOSE == true || $DRYRUN == true ]] ; then
      echo >&2 "$PNAME/${FUNCNAME[0]} : we DON'T have an exclude file with\
        contents"
    fi
    return 1
  fi
}
# hasExcludeFile()
# PARAMETERS: BACKUP_SCHEME, SYMLINK_NAME
# RETURNS true/0 if we have an exclude file
# GLOBALS : EXCLUDE_FILE : the full path to any exclude file is delivered\
# through this.
# And, we even check if the include file has any contents. like we do with the
# create exclude file, but this time, it isn't fatal, it is just a NO.

hasExcludeFile() {
# Maybe we can use globals for symlink_name and such as BACKUP_SCHEME\
# for optimization.

  if [[ $# -ne 2 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} I need two parameters BACKUP_SCHEME and\
      SYMLINK_NAME!\nTerminating... " 1>&2
    exit 5
  fi
  declare -g EXCLUDE_FILE
  local symlink_name backup_scheme
  dieIfNotValidFbFolderName "$1"
  # if it isn't valid, die.
  backup_scheme=$1
  symlink_name="$2"

  if [[ -d "$XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d" ]] ; then

    if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ;  then
      echo -e >&2 "$PNAME : We have a dropin directory:\
        \n$XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d"
    fi


    if  excludeFileHasContents "$backup_scheme" "$symlink_name" ; then
      export EXCLUDE_FILE=\
"$XDG_BIN_HOME"/fb/"$backup_scheme"/"$symlink_name".d/exclude.file

      if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ;  then
        echo -e >&2 "$PNAME : We have an \"exclude.file\" file:\
          \n$XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d/exclude.file"
      fi
      return 0
    else
      if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ;  then
        echo -e >&2 "$PNAME : We DON'T have an \"exclude.file\" file:\
          \n$XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d/exclude.file"
      fi
      return 1
    fi
  else
    if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ;  then
      echo -e >&2 "$PNAME : We don't have  a dropin directory:\
        $XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d"
      echo -e >&2 "$PNAME : We don't have an \"exclude.file\" file: \
        $XDG_BIN_HOME/fb/$backup_scheme/$symlink_name.d/exclude.file"
    fi
    return 1
  fi
}

# createExcludeFile()
#
# creates an exclude file, or not, in which case the caller should abort\
# the current operation. that is, this current operation.
# PARAMETERS:
# a scheme name
# A valid symlink name.
# GLOBAL: uses  THE_EDITOR with the correct editor, if any.

createExcludeFile() {
  if [[ $# -ne 2 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need two \
arguments\nTerminates" >&2 ; exit 5 ; fi
  # visual first, editor after.
  dieIfNotValidFbFolderName "$1"
  SCHEME=$1
  dieIfNotValidFullSymlinkName "$2" "$1"
  FULL_SYMLINK_NAME="$2"

# Only one place a the exclude file.
# And if it doesn't exist, then we'll make it.
  if [[ ! -d "$XDG_BIN_HOME"/fb/"$SCHEME"/"$FULL_SYMLINK_NAME".d ]] ; then
    echo >&2 "$XDG_BIN_HOME"/fb/"$SCHEME"/"$FULL_SYMLINK_NAME".d

    if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then
      echo -e "$PNAME : The folder\
        \"$XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d\" didn't exist.\
        \nMaking it.\nmkdir -p ~/.local/bin/fb/OneShot/$FULL_SYMLINK_NAME.d"\
        | journalThis 7 "$SCHEME"
    fi
    mkdir -p "$XDG_BIN_HOME"/fb/"$SCHEME"/"$FULL_SYMLINK_NAME".d
    touch "$XDG_BIN_HOME"/fb/"$SCHEME"/"$FULL_SYMLINK_NAME".d/exclude.file
  fi

  dieIfNoEditorSetToUse

  if "$THE_EDITOR"\
    "$XDG_BIN_HOME"/fb/"$SCHEME"/"$FULL_SYMLINK_NAME".d/exclude.file ;\
  then
    echo -e "${0##*/}/${FUNCNAME[0]} : Something went wrong during editing.\
      \n $XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d/exclude.file\
      \nTerminating..." | journalThis 2 OneShot
    exit 1
  fi

  # Maybe we should check if there were any contents in the file we created
  #  before we see this as a success?
  if excludeFileHasContents "$SCHEME" "$FULL_SYMLINK_NAME" ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : The exclude file\
      \n$XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d/exclude.file\nIs empty!\
      \nTerminating..." | journalThis 2 "$SCHEME"

    exit 1
  fi
}

