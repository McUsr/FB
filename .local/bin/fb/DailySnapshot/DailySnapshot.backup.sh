#!/bin/bash
# DailySnapshotBackup.
# hourly_backup;(c) 2022 Mcusr -- Vim license.
# This script serves as a template for dropin scripts.
#
# This script gets executed every time the timer interval specified in this
# case DailySnapshot.timer fires and is made for  being  started by the ../governor.sh
# the name of the script should give an idea as to what you are backing up.

# You need to edit it to align with the folder you share with Linux for backup
# purposes, and with the folder you want to make an hourly backup of.  you also
# need to install notify-send.
# https://www.reddit.com/r/Crostini/comments/zl5nte/sending_notifications_to_chromeos_desktop_from/
#
# 27/12: Added "sparsity" doesn't make unneccessary backups anymore.
# 12/01: Real deal ready for production, for what DailySnapshot backups are concerned.

VERSION='v0.0.4'
PNAME="${0##*/}"
# extract scheme name like below, due to naming-convention.
CURSCHEME="${PNAME%%.*}"
# The piece below are set in with m4, to keep just one piece to
# maintain.

# We set the path above the delegate, where is were
# we store the service_functions.file
# shellcheck disable=SC2001,SC2086  # Escaped by sed
pthname="$( echo $0  | sed 's/ /\\ /g' )"
# shellcheck disable=SC2086  # Escaped by sed
fpth="$(realpath $pthname)"; fpth=${fpth%/*} ; fpth=${fpth%/*}
# This is an early include guard, before we know if we can run
# run in this environment at all.

# shellcheck source=/home/mcusr/.local/bin/fb/service_functions.sh
if [[ -r "$fpth"/service_functions.sh ]] ; then
  source "$fpth"/service_functions.sh
else
  echo -e  "$PNAME : Can't source: $fpth/service_functions.sh\
    \nTerminates... "
  exit 255
fi

VERSION='v0.0.4'
if [[ -t 1 ]] ; then
  MODE=DEBUG
else
  MODE=SERVICE
fi
dieIfMandatoryVariableNotSet FB $MODE $CURSCHEME
dieIfMandatoryVariableNotSet XDG_BIN_HOME $MODE $CURSCHEME
dieIfMandatoryVariableNotSet XDG_DATA_HOME $MODE $CURSCHEME

# can't check FB just yet, because it is apt to check for internet first.

if ! isDirectory "$XDG_BIN_HOME" ; then
  fatal_err "the Directory \$XDG_BIN_HOME : $XDG_BIN_HOME doesn't\
    exist!" "$MODE" "$CURSCHEME"
  exit 255
fi

if ! isDirectory "$XDG_DATA_HOME" ; then
  fatal_err "the Directory \$XDG_DATA_HOME : $XDG_DATA_HOME doesn't\
    exist!" "$MODE" "$CURSCHEME"
  exit 255
fi

# Vars below up here, to work globally and just not in the if block..
DEBUG=1
DRYRUN=false
# controls whether we are going to print the backup command to the console/journal,
# (when DRYRUN=0) or if were actually going to perform.
VERBOSE=false

if [[ "$MODE" == "SERVICE" ]] ; then
# https://serverfault.com/questions/573946/how-can-i-send-a-message-to-the-systemd-journal-from-the-command-line
  exec 4>&2 2> >(while read -r REPLY; do printf >&4 '<3>%s\n' "$REPLY"; done)
  trap 'exec >&2-' EXIT

# Normal argument parsing happens here!
else


if [[ $# -eq 0 ]] ; then
  echo -e "$PNAME : Too few arguments. At least I need a folder target\
    to backup.\nExecute \"$PNAME -h\" for help. Terminating..." >&2
 exit 2
fi

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

  GETOPT_COMPATIBLE=true
# time to parse some command line arguments!
# https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options
  TEMP=$(getopt -o hnvV --longoptions help,verbose,dry-run,version \
                -n "$PNAME" -- "$@")
  # shellcheck disable=SC2181 # It's too long to put in  an if test, I feel!
  if [[ $? != 0 ]] ; then echo "$PNAME : Terminating..." >&2 ; exit 2 ; fi

  # Note the quotes around '$TEMP': they are essential!
  eval set -- "$TEMP"

  while true; do
      case "$1" in
        -h | --help )  help ; exit 0 ;;
        -n | --dry-run ) DRYRUN=true; shift ;;
        -v | --verbose ) VERBOSE=true; shift ;;
        -V | --version ) echo "$PNAME" : $VERSION ; exit 0 ;;
        -- ) shift; break ;;
      esac
  done

fi

DEBUG=0
#
# prints out debug messages to the console/journal if its on when instigated by
# systemd --user.
TO_CONSOLE=0
# controls whether debug output will be sent to the journal when the script is called
# from the terminal, and output be sent to the journal anyway, when the script is run
# implicitly by a daemon.
ARCHIVE_OUTPUT=1

# shellcheck source=/home/mcusr/.local/bin/fb/shared_functions.sh
if [[ -r "$XDG_BIN_HOME"/fb/shared_functions.sh ]] ; then
  source "$XDG_BIN_HOME"/fb/shared_functions.sh
else
  echo -e  "$PNAME : Can't source: $XDG_BIN_HOME/fb/shared_functions.sh\
    \nTerminates... "
  exit 255
fi

# shellcheck disable=SC2034  # will be used!
DAYS_TO_KEEP_BACKUPS=14

# TODO: differ between "REAL" mode and debug mode.
if [ $# -ne 2 ] ; then
    if [[ $TO_CONSOLE == false ]] ; then
      notify-send "Folder Backup: ${0##*/}" "I didn't get two mandatory parameters: A backup scheme, and a job-folder, Hopefully you are executing from the commandline. Exiting hard."
    fi
    # TODO : journal message.
    # A criticial error.
    # I think it will be good with date and folder as variables, and the scheme as target.

    echo >&4 "<2>${0##*/} : I didn't get two mandatory parameters: A backup scheme, and a job-folder, Hopefully you are executing from the commandline. Exiting hard."
    exit 255

fi

# ----------------------------------------------------------------------------
# parsing of options happens here!
# ----------------------------------------------------------------------------

BACKUP_SCHEME=$1
SYMLINK_NAME=$2


JOBSFOLDER="$XDG_DATA_HOME"/fbjobs/"$BACKUP_SCHEME"

TARGET_FOLDER=$(realpath "$JOBSFOLDER"/"$SYMLINK_NAME")
if [ $DEBUG -eq 0 ] ; then
  echo >&4 "<7>${0##*/}: TARGET_FOLDER: $TARGET_FOLDER"
  # debug message
fi
THIS_FOLDER_BUCKET=$FB/Periodic/$BACKUP_SCHEME/$SYMLINK_NAME
if [ $DEBUG -eq 0 ] ; then
  echo >&4 "<5>${0##*/} : the backups of $TARGET_FOLDER are stored in: $THIS_FOLDER_BUCKET"
  # TODO: Maybe raise this to notice.

fi

# It might be the first time, for some weird reason
# we but just we! the DailySnapshot NOT this DailySnapshotBackup
# can be called from the OneShot routine.
# or we can somehow had our own idea of how to start
# the things up, so we just silently create it.
# we are here to solve problems, not create them.

if [ ! -d $THIS_FOLDER_BUCKET ] ; then
  mkdir -p $THIS_FOLDER_BUCKET
  if [ $DEBUG -eq 0 ] ; then
    echo >&4 "<7>${0##*/} : $THIS_FOLDER_BUCKET didn\'t exist"
    # A debug message
  fi
else
  if [ $DEBUG -eq 0 ] ; then
    echo >&4 "<7>${0##*/} : $THIS_FOLDER_BUCKET DID  exist"
   # A debug message
  fi
fi

# we generate todays folder name.
TODAYS_FOLDER=$THIS_FOLDER_BUCKET/$(baseNameDateStamped $SYMLINK_NAME)

# we regenerate the folder where the symlinks are
# THIS part isn't in the OneShot script.
# there is  alot that doesn't need to be in the OneShot script,
# But, on the other hand, if the OneShot is executed repeatedly,
# Then maybe the find -cnewer is smart, after all?



if [ ! -d $JOBSFOLDER ] ; then
     notify-send "Folder Backup: ${0##*/}" "The folder $JOBFOLDER doesn't exist. Hopefully you are executing from the commandline and misspelled $BACKUP_SCHEME."
    echo >&4 "<0>${0##*/}: The folder $JOBFOLDER doesn't exist. Hopefully you are executing from the commandline and misspelled $BACKUP_SCHEME."
    exit 255
    # A critical error
fi

if [ $DEBUG -eq 0 ] ; then
  echo >&4 "<7>${0##*/}: JOBSFOLDER: $JOBSFOLDER"
  # a debug message
fi

MAKE_BACKUP=1
# MAKE_BACKUP helps us differ between the case that we need to
# make TODAYS_FOLDER, or not, because if we make it, then there is
# no reason to perform a find -newer, we'll make a backup anyway.

# So we can differ between first run of today,
# and later ones, because we need to rotate backups if
# it is.
MADE_TODAYS_FOLDER=1
if [ ! -d $TODAYS_FOLDER ] ; then
  mkdir -p $TODAYS_FOLDER
  MADE_TODAYS_FOLDER=0

  if [ $DEBUG -eq 0 ] ; then
    echo >&4 "<7>${0##*/}: $TODAYS_FOLDER didn\'t exist, que to make backup"
    # debug message
  fi
  MAKE_BACKUP=0
else
  if [ $DEBUG -eq 0 ] ; then
    echo >&4 "<7>${0##*/}: $TODAYS_FOLDER exists, NO que to make backup"
    # debug
  fi
  modfiles=`find -H $JOBSFOLDER/$SYMLINK_NAME -cnewer $TODAYS_FOLDER`
    if [ $DEBUG -eq 0 ] ; then
      echo >&4 "<7>${0##*/}: +"$modfiles"+"
      # debug message
    fi
  if [ ! -z "$modfiles" ] ; then
    # there are changed files here, and we should perform a backup
    if [ $DEBUG -eq 0 ] ; then

      echo >&4 "<5>${0##*/}: find: There are modified files in target folder: $TARGET_FOLDER and we will perform a $BACKUP_SCHEME backup."
     fi
    MAKE_BACKUP=0
  else
    if [ $DEBUG -eq 0 ] ; then
      echo >&4 "<5>${0##*/}: find: There are no changed files in target folder: $TARGET_FOLDER."
      # notice message
    fi
  fi
fi

if [  $MAKE_BACKUP -eq 0 ] ; then
    # there are changed files here, and we should perform a backup
    # we extract the real path, pointed to by the symlink, which we
    # will make a backup of.


    if [ $DRYRUN -eq 0 ] ; then
      echo >&4 "<5>${0##*/}: sudo tar -zvcf $TODAYS_FOLDER/$(baseNameTimeStamped $SYMLINK_NAME )-backup.tar.gz -C $TARGET_FOLDER ."
      # notice message
    else
      if [ $ARCHIVE_OUTPUT -eq 0 ] ; then
        sudo tar -zvcf $TODAYS_FOLDER/$(baseNameTimeStamped $SYMLINK_NAME )-backup.tar.gz -C $TARGET_FOLDER . >&4
        # the output sent as a notice message.
      else
        sudo tar -zvcf $TODAYS_FOLDER/$(baseNameTimeStamped $SYMLINK_NAME )-backup.tar.gz -C $TARGET_FOLDER . >/dev/null
      fi
    fi

    # TODO: More work on the notify-send message, and needs to send a message to the Journal as well.
    # Needs to learn the journalctl better first.
    if [ $DRYRUN -ne 0 ] ; then
      notify-send "${0##*/}" "Hourly backup complete!"
      echo >&4 "<5>${0##*/}: Hourly backup complete!"
      # notice message
    fi

    # touch $TARGET_FOLDER

    # Line above, when an  existing file have just been updated, or when
    # No no files have been added to the the archive, at least when you see
    # for yourself that the modification date of the $TARGET_FOLDER doesn't change.
    # I think that most archiving utilities at least have an option for unlinking
    # before updating, but if that isn't the case, the touch command is always an
    # option.
else
    notify-send "${0##*/}" "Nothing to hourly backup!"
    echo >&4 "<5>${0##*/}: Nothing to hourly backup!"
    # notice message
fi

 if [ $MADE_TODAYS_FOLDER -eq 0 ] ; then
   :
    # Figure out how many daily folder we got now.
    # DAYS_TO_KEEP_BACKUPS=14
    # $THIS_FOLDER_BUCKET
    # jeg trenger å sile directories på fil navn på riktig  format, og om er
    # directory. så vi ikke gjør noen tabber.
    # lista jeg sitter igjen med er den jeg teller opp for å se om count >= DAYS_TO_KEEP_BACKUPS
    # senker antallet ned til 14.

    # trenger basename fra symlink

    # ls file name <glob>

    # inn i sed som filtrerer på korrekt dato format.
    # fed into a loop, som sjekker om directory.
    # misfits gets removed.
    # then we count.

    # we removes every directory that supercedes the chosen number.

    # we trenger å prepende THIS_FOLDER_BUCKET to basename for ls command.
    # ls -ld homepage* | sed -n '/^d/ s/\(.*\)\(homepage-[1,2][0,9][0-9][0-9]-[0,1][0-9]-[0-3][0-9]\)/\2/p' | wc -l
    # kan sette IFS to newline for henter inn i variabel?
 fi

echo >&2 "${0##*/}: The backup-rotation routine remains to be implemented"
