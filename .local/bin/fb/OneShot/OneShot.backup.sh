#!/bin/bash
# The version at a8de2b1 contains the scaffolding.

PNAME=${0##*/}
err_report() {
  echo "$PNAME : Error on line $1"
  echo "$PNAME : Please report this issue at\
    'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR
VERSION='v0.0.3c'
if [[ ! -v FB ]] ; then
     echo -e "$PNAME The variable \$FB isn't set, is the system initialized?\
       You need configure it.\nTerminating..." | journalThis 2 OneShot
    exit 255
fi

if [[ ! -d "$FB" ]] ; then
     echo -e "$PNAME" "The folder  $FB  can't be found!\nThe Google Drive\
       folder is probably not shared with with Linux. Isn't set, is the\
       system initialized? Maybe you need to configure it.\nTerminating..."\
       | journalThis 2 OneShot
    exit 255
fi

# shellcheck source=/home/mcusr/.local/bin/fb/shared_functions.sh
if [[ -r "$XDG_BIN_HOME"/fb/shared_functions.sh ]] ; then
  source "$XDG_BIN_HOME"/fb/shared_functions.sh
else
  echo -e  "$PNAME : Can't source: $XDG_BIN_HOME/fb/shared_functions.sh\
    \nTerminates... "
  exit 255
fi
# shellcheck disable=SC2034  # warning not relevant, var read by getopt(3)
GETOPT_COMPATIBLE=true

if [[ $# -eq 0 ]] ; then
  echo -e "$PNAME : Too few arguments. At least I need a folder target\
    to backup.\nExecute \"$PNAME -h\" for help. Terminating..." >&2
 exit 2
fi
DEBUG=1
help() {
cat  << EOF

$PNAME:  Restores a previous folder backup, made with the fb system.

syntax:

  $PNAME [options] <source folder>  <full-symlink-name>  <destination>
  It is meant to be executed by *fboneshot* and not individually.

  Options:

  -h| --help.    Shows this help.
  -n| --dry-run  Shows what would have happened
  -v| --verbose  Shows more detailed output.
  -V| --version  Shows the version of $PNAME ($VERSION).

EOF
}
# set -x
# https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options
TEMP=$(getopt -o hnvV --longoptions help,verbose,dry-run,version \
              -n "$PNAME" -- "$@")
# shellcheck disable=SC2181 # It's too long to put in  an if test, I feel!
if [[ $? != 0 ]] ; then echo "Terminating..." >&2 ; exit 2 ; fi

# Note the quotes around '$TEMP': they are essential!
eval set -- "$TEMP"

PARSE_DEBUG=1
DRYRUN=false
VERBOSE=false

while true; do
    case "$1" in
      -h | --help )  help ; exit 0 ;;
      -n | --dry-run ) DRYRUN=true; shift ;;
      -v | --verbose ) VERBOSE=true; shift ;;
      -V | --version ) echo "$PNAME" : $VERSION ; exit 0 ;;
      -- ) shift; break ;;
    esac
done

HAVING_ERRORS=false
DEBUG=1


if [[ $# -ne 3 ]] ; then
  echo -e "$PNAME : Wrong number of  few arguments. I need one argument for\
    the folder to backup, the full symlink name, \nand the  path to the\
    destination folder of the backup operation.\
    \nExecute \"$PNAME -h\" for help. Terminating..." >&2
  exit 2
fi

# we do check if the source folder exists. and that it doesn't exist
# within the FB-backup tree.

if [[ -d "$1" ]] ; then
  TARGET_TEST="${1/$FB/}"
  if [[ "$TARGET_TEST" != "$1" ]] ; then
    if [[  "$DRYRUN" = true ]] ;  then
      echo -e "$PNAME : The target folder IS inside $FB.\n(${1})."
      HAVING_ERRORS=true
    else
      # same whether dry-run, verbose, or not.
      echo -e "$PNAME : The target of the backup is not allowed to be inside\
        $FB.\nTerminating..."
      exit 2
    fi
  else
    if [[ $VERBOSE = true || $DEBUG -eq 0  ]] ;  then
      echo -e "$PNAME : The target folder is NOT inside $FB.\n($1)."
    elif [[ $DRYRUN = true ]] ; then
      echo -e "$PNAME : The target folder is NOT inside $FB.\n($1)."
    # else we're passing through further down the road.
    fi
  fi
else
  if [[ $DRYRUN = false ]] ; then
    echo -e "$PNAME : The destination folder $2 does not exist.\
      \nTerminating..."
    exit 2
  fi
fi
TARGET_FOLDER="$1"

# we check if the destination path exists, and within the FB-backup tree.
if [[ -d "$2" ]] ; then
  DEST_TEST="${2/$FB/}"
  if [[ "$DEST_TEST" = "$2" ]] ; then
      echo -e "$PNAME : The destination folder is NOT inside\n$FB\n which it\
        must be. Terminating..."
      exit 2
  else
    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
      echo -e "$PNAME : The destination folder is inside $FB.\n($2)."
    fi
    # else .. silently moving on ...
  fi
else
  if [[ $DRYRUN = false ]] ; then
    echo -e "$PNAME : The destination folder $2 does not exist.\
      \nTerminating..."
    exit 2
  fi
fi

TODAYS_BACKUP_FOLDER="$2"
# we need to check if the full symlink name is within the destination path.

SYMLINK_TEST="${TODAYS_BACKUP_FOLDER/$3/}"
if [[ "$SYMLINK_TEST" = "$TODAYS_BACKUP_FOLDER " ]] ; then
  # same whether dry-run, verbose, or not.
  echo -e "$PNAME : The full symlink name is not the correct one.\n It is\
      not the name of the root folder of the backup.\nTerminating..."
  exit 2
else
  if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
    echo -e "$PNAME : The full symlink name: $3 is the same as the name of\
      the root folder of the backup:\n$TODAYS_BACKUP_FOLDER"
  fi
  # else .. silently moving on ...
fi
SYMLINK_NAME="$3"

# time to look for any exclude files

if hasExcludeFile OneShot "$SYMLINK_NAME" ; then
 if [[ $VERBOSE = true ]] ; then
   echo "$PNAME : I have an exclude file : $EXCLUDE_FILE "
   cat "$EXCLUDE_FILE"
 fi
 EXCLUDE_OPTIONS="--exclude-from=$EXCLUDE_FILE"
else
  EXCLUDE_OPTIONS=
fi

if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
  VERBOSE_OPTIONS="-v -v"
else
  VERBOSE_OPTIONS="-v"
fi
EXIT_STATUS=0
if [[ $DRYRUN = true  ]] ; then

  DRY_RUN_FOLDER=$(mktemp -d "/tmp/OneShot.backup.sh.XXX")
  trap "HAVING_ERRORS=true;ctrl_c" INT

ctrl_c() {
  echo "$PNAME : trapped ctrl-c - interrupted tar command!"
  echo "$PNAME : We: rm -fr $DRY_RUN_FOLDER."
  rm -fr "$DRY_RUN_FOLDER"
}

  TAR_BALL_NAME="$DRY_RUN_FOLDER"/"$(baseNameTimeStamped "$SYMLINK_NAME" )"-backup.tar.gz
  if [[ $HAVING_ERRORS = false ]] ; then

    echo "$PNAME : sudo tar -z $VERBOSE_OPTIONS -c -f\
      $TAR_BALL_NAME $EXCLUDE_OPTIONS -C $TARGET_FOLDER . "
  #  | journalThis 7 OneShot
    sudo tar -z  -c $VERBOSE_OPTIONS -f "$TAR_BALL_NAME" "$EXCLUDE_OPTIONS" -C "$TARGET_FOLDER" .
   #   | journalThis 7 OneShot
    if [[ -d "$DRY_RUN_FOLDER" ]] ; then
        rm -fr "$DRY_RUN_FOLDER"
    fi
    EXIT_STATUS=$?
    if [[ $EXIT_STATUS -gt 1 ]] ; then
      echo "$PNAME : exit status after tar commmand = $EXIT_STATUS"
      echo "$PNAME : rm -fr $DRY_RUN_FOLDER"
    fi
  else
    echo -e "$PNAME :\
      DRY_RUN_FOLDER=\$(mktemp -d \"/tmp/OneShot.restore.sh.XXX\")"
    echo -e "$PNAME : sudo tar -z -c $VERBOSE_OPTIONS -c  $EXCLUDE_OPTIONS -f\
      $TAR_BALL_NAME  -C $TARGET_FOLDER . "
    echo -e "$PNAME : rm -fr $DRY_RUN_FOLDER"
  fi
else
# DRYRUN == false
  TAR_BALL_NAME="$TODAYS_BACKUP_FOLDER"/$(baseNameTimeStamped "$SYMLINK_NAME" )-backup.tar.gz
  trap "HAVING_ERRORS=true;ctrl_c" INT
ctrl_c() {
  echo trapped ctrl-c
  echo rm -f "$TAR_BALL_NAME"
  rm -f "$TAR_BALL_NAME"
}
    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
      echo -e "$PNAME : sudo tar -z -c $VERBOSE_OPTIONS -c  $EXCLUDE_OPTIONS\
        -f $TAR_BALL_NAME  -C $TARGET_FOLDER" .
    fi
    sudo tar -z $VERBOSE_OPTIONS -c "$EXCLUDE_OPTIONS" -f "$TAR_BALL_NAME" -C "$TARGET_FOLDER" .
    EXIT_STATUS=$?
   #   | journalThis 7 OneShot
    if [[ $EXIT_STATUS -gt 1 ]] ; then

      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        echo "$PNAME : exit status after tar commmand (fatal error)\
          = $EXIT_STATUS"
      fi

      if [[ -f "$TAR_BALL_NAME" ]] ; then
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
          echo "$PNAME : rm -f $TAR_BALL_NAME"
        fi
        rm -f "$TAR_BALL_NAME"
      fi
    elif [[ $EXIT_STATUS -eq 0 ]] ; then
      echo -e "\n($TAR_BALL_NAME)\n"
    fi
fi

exit $EXIT_STATUS
