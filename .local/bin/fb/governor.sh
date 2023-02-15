#!/bin/bash
# v0.0.4
# Governor.sh
# We are getting the backup-scheme passed as parameter from the
# <backup-scheme>.service, invoked by <backup-scheme>.timer.

# We check for an empty job folder first of all, and if it is,
# we shut down the whole service, and exits gracefully, no questions
# asked.

# First we check if there is any jobs to dispatch from the jobs folder.


# Moving forward:
# Using the XDG_DATA_HOME, would give some leeway as to avoiding hard_coding of paths.
# We are still using this with service. SnapShot

# Config vars you can set to mostly control output.
DEBUG=0

pathToSourcedFiles() {
  # shellcheck disable=SC2001,SC2086  # Escaped by sed
  pthname="$( echo $0  | sed 's/ /\\ /g' )"
  # We do escape any spaces, in the file name, 
  #  knew it could never happen, just in case.
  # shellcheck disable=SC2086  # Escaped by sed
  fpth="$(realpath $pthname)"; fpth="${fpth%/*}"
  echo "$fpth"
}

if [[ $DEBUG -ne 0  ]] ; then
# dieIfCantSourceShellLibrary()
# sources the ShellLibraries
# so we can perform the rest of the tests.
# TODO: Think of modus.
# dieIfCantSourceShellLibrary() {
#   if [[ $# -ne 1 ]] ; then
#     echo -e "$PNAME/${FUNCNAME[0]} : Need an\
#     argument, an existing fb shell library file!\nTerminates..." >&2
#     exit 5
#   fi
#   if [[ -r "${1}" ]] ; then
#     source "${1}"
#   #  source "$fpth"/service_functions.sh
#   else
#     echo -e  "$PNAME/${FUNCNAME[0]} : Can't find/source: ${1}\
#       \nTerminates... " >&2
#     exit 255
#   fi
# }
:
fi
# Program vars, read only, 

PNAME=${0##*/}
VERSION='v0.0.4'
CURSCHEME="${PNAME%%.*}"

if [[ -t 1 ]] ; then
  MODE="DEBUG"
else
  MODE="SERVICE"
fi

# bootstrapping libraries before figuring system paths.
fbBinDir="$(pathToSourcedFiles)"

if [[ $DEBUG -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/service_functions.sh
else
# shellcheck source=service_functions.sh
  source "$fbBinDir"/service_functions.sh
fi

if [[ $# -ne 1 ]] ; then

  if [[ $MODE == "SERVICE" ]] ; then
    notifyErr "$PNAME" "I didn't get a mandatory parameter (backup-scheme).\
\nTerminating..." | journalThis 2 FolderBackup
    exit 255
  else
    echo -e >&2 "$PNAME : I didn't get a mandatory parameter.\
.. Enter: \"$PNAME -h\" for help.\nTerminating..."
  exit 2
  fi
fi

dieIfMandatoryVariableNotSet FB "$MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_DATA_HOME "$MODE" "$CURSCHEME"


dieIfNotDirectoryExist "$XDG_BIN_HOME"
dieIfNotDirectoryExist "$XDG_BIN_HOME/fb"
dieIfNotDirectoryExist "$XDG_DATA_HOME"

if [[ $DEBUG -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/shared_functions.sh
fi


consoleHasInternet "$CURSCHEME"
consoleFBfolderIsMounted "$CURSCHEME"

BACKUP_SCHEME=$1

JOBS_FOLDER=$HOME/.local/share/fbjobs/$BACKUP_SCHEME

dieIfJobsFolderDontExist "$JOBS_FOLDER" "$BACKUP_SCHEME" "$MODE"
# We should check if the job folder exist

# And the bin folder.

dieIfNotBinFolderExist "$BACKUP_SCHEME"

SCHEME_BIN_FOLDER=$XDG_BIN_HOME/fb/$BACKUP_SCHEME


# JOB_LIST=$(ls -1 $JOBS_FOLDER | sed -n '/.pause/ !p')
JOB_LIST="$(find "$JOBS_FOLDER" -mindepth 1 -maxdepth 1 | sed -ne 's,^.*[/],,' -e '/.pause/ !p')"
# TODO: implement all over.

if [[ -z "$JOB_LIST" ]] ; then
  # We have nothing to  do, and die silently.
  if [[ $DEBUG -eq 0 ]] ; then
    echo "No symlinks, nothing to do."
  fi
  # TODO:, Her sender vi notification om at bør sjekke journal ctl, og stoppe service.
  # Det som hendt er at sikkert slettet symlink, manuellt.
  # As Critical Error, if no tty. or just give a shit, and send the error anyway.
  exit 0
fi

# TODO: giving up after two times, with critical error?

# we had something an need to continue testing.
# The $FB variable is the mounting point for the google drive is mandatory.

# The thing is, is if we are executed after boot, will I then be able to
# exit in a way, that makes the service re-run it, or will I have to take care of that on
# my own, with maybe even an extra layer of service for those kinds of events.
# the thing is, is that I'm waiting for a copy of the parent environment to be read in.


source /home/mcusr/.local/bin/fb/shared_functions.sh

# We need to check the internet


# Absolutely first time, or something removed?
# we rest/Assured.

mkdir -p "$FB/Periodic"
# just in case, no harm, no foul.

mkdir -p $FB/Periodic/$BACKUP_SCHEME

DEST_SCHEME_FOLDER="$FB/Periodic/$BACKUP_SCHEME"
if [[ ! -d "$DEST_SCHEME_FOLDER" ]] ; then
  mkdir -p "$DEST_SCHEME_FOLDER"
  # we can go silent about this, or we can just send a message.
  if [[ $DEBUG -eq 0 ]] ; then
    echo "$DEST_SCHEME_FOLDER didn't exist, que to make backup"
  fi
else
  if [[ $DEBUG -eq 0 ]] ; then
    echo "$DEST_SCHEME_FOLDER exists, NO que to make backup"
  fi
fi
# Todo: dette skal ut!

# We check if the $FB folder is  mounted.


#check if any jobs are still active, otherwise bail.


for symlink in $JOB_LIST ; do
  if isASymlink $JOBS_FOLDER/$symlink ; then
    if [[ $DEBUG -eq 0 ]] ; then
      echo $symlink is a symlink
    fi
    if isUnbrokenSymlink $JOBS_FOLDER/$symlink ; then
      if [[ $DEBUG -eq 0 ]] ; then
        echo the symlink $symlink is unbroken
      fi
      # we need the real path
      target_folder=`realpath $JOBS_FOLDER/$symlink`
      if [[ $DEBUG -eq 0 ]] ; then
        echo Realpath is $target_folder
      fi
      # exists, when unbroken link. maybe want to backup a mysql file,
      #  so no test on dir?
      # Database-files,  is something else, another kind of backup.

      # check if DEST_CONTAINER exists, if it doesn`t, then no need to run
      #  find but execute the backup directly.
      # We might manually have put a symlink into the JOBS_FOLDER, so this is
      # warranted.???

      # if this job/symlink has been  started, the normal way, then  the
       #  folder DEST_CONTAINER exists, but if we  dropped a symlink into the
      #  JOBS_FOLDER for the first  time, then started the correct service
      # with systemd,then we need this.
      # Also, if the DEST_CONTAINER doesn't exist, then we may have changed the
      # place for the backup (The folder mounted, or GoogleDrive maybe,
       #  or we have  deleted everything and started afresh.
      # So, we create the DEST_CONTAINER silently if it doesn't exist for the
      # sake of robustness.

      # The last test before we actually do something is to check if
      # if there is an accompanying **$symlink.pause** file, which means
      # that the backup-job for this folder is temporarily paused.
      if [[ ! -f $JOBS_FOLDER/$symlink.pause ]] ; then
        DEST_CONTAINER=$DEST_SCHEME_FOLDER/$symlink
        # Alt med DEST_CONTAINER skal over i fbinst e.l fbctl
        if [[ ! -d $DEST_CONTAINER ]] ; then
          mkdir -p $DEST_CONTAINER
          # we can go silent about this, or we can just send a message.
          if [[ $DEBUG -eq 0 ]] ; then
            echo "$DEST_CONTAINER didn't exist, que to make backup"
          fi
        else
          if [[ $DEBUG -eq 0 ]] ; then
            echo "$DEST_CONTAINER exists, NO que to make backup"
          fi
        fi

# Manager level:

        dropin_script=$SCHEME_BIN_FOLDER/$symlink.d/dropinBackup.sh
        if [[ $DEBUG -eq 0 ]] ; then
          echo "dropin_script:>$dropin_script<is this"
          echo "SCHEME_BIN_FOLDER: $SCHEME_BIN_FOLDER: is the value"
          echo "BACKUP_SCHEME: $BACKUP_SCHEME: is the value!"
        fi
        regular_script="$SCHEME_BIN_FOLDER/$BACKUP_SCHEME.Backup.sh

        if [[ $DEBUG -eq 0 ]] ; then
          echo "regular_script:>$regular_script<is this"
        fi

        if [[  -x $dropin_script ]] ; then
            $dropin_script $BACKUP_SCHEME $symlink
        elif [[ -x $regular_script ]] ; then
          if [[ $DEBUG -eq 0 ]] ; then
            echo $regular_script $BACKUP_SCHEME $symlink
           echo running....
          fi
           $regular_script $BACKUP_SCHEME $symlink
        else
          notify-send "Folder Backup: ${0##*/}" "The script $regular_script doesn't exist. You should really review the system. \"journalctl --user -xe\" is your friend!"
          # Critical error notification here!
          exit 9
        fi
        # echo touch $DEST_CONTAINER
        # denne går inn i executor, ved behov? eller alltid, slik at
        # vi er sikre på at oppdatering blir regsitrert gjennom modification time.
      else
        echo "I found a $JOBS_FOLDER/$symlink.pause file and skips this job ... for now."
      fi
    else
      if [[ $DEBUG -eq 0 ]] ; then
        echo the symlink $symlink is broken
      fi
      # this goes to the journal land a notification is sent.
      brokenSymlink "$JOBS_FOLDER" "$symlink" "$BACKUP_SCHEME:${0##*/}"
      # TODO: Maybe "$BACKUP_SCHEME:${0##*/}" isn't a great idea after all.
      # ... or maybe not
    fi
  # else NOT A SYMLINK, we just ignore.
  fi
done

# 3 bad symlinks kanskje notiyf send, men helt sikkert melding
# i  journal.

# // kommandoer for å se meldinger for jobb i logg.
# forexample : DailyDifflog.

echo passed tests!
