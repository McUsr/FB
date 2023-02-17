#!/bin/bash
# DailySnapshotBackup.
# hourly_backup;(c) 2022 Mcusr -- Vim license.
# This script serves as a template for dropin scripts.
# TODO: document that!
# This script gets executed every time the timer interval specified in this
# case DailySnapshot.timer fires and is made for  being  started by
# the ../governor.sh
# the name of the script should give an idea as to what you are backing up.

# You need to edit it to align with the folder you share with Linux for backup
# purposes, and with the folder you want to make an hourly backup of.
# you also
# need to install notify-send.
# https://www.reddit.com/r/Crostini/comments/zl5nte/sending_notifications_to_chromeos_desktop_from/
#

# pathToSourcedFiles()
# A staple from now on, can't source this one.
# Does as it says.

# Whats new. EXCLUDE_OPTIONS: because of spaces that might be in filenames, we 
# need quotes when it is in use, because quooting the empty variable when there
# are no exclude file, makes tar err, we need to remove the variable when not in
# use.

# the variables below are configuration variables you can
# use, especially when invoking indirectly by the governor,
# as a service.

# Config vars you can set to mostly control output.
# they don't override  options set on the command line,
# just an alternative. Command line options override.

DAYS_TO_KEEP_BACKUPS=14 # set to 0 to disable backup rotation.

# TODO: check if it only touches folders of correct form when
# performing backup rotation.

DRYRUN=false
ARCHIVE_OUTPUT=1 # only controls ouput during  DRYRUN

DEBUG=1 # controls output during debugging.
VERBOSE=true # controls output during normal runs.


# dieIfCantSourceShellLibrary()
# sources the ShellLibraries
# so we can perform the rest of the tests.
# TODO: Think of modus.
dieIfCantSourceShellLibrary() {
  if [[ $# -ne 1 ]] ; then
    echo -e "$PNAME/${FUNCNAME[0]} : Need an\
    argument, an existing fb shell library file!\nTerminates..." >&2
    exit 5
  fi
  if [[ -r "${1}" ]] ; then
    source "${1}"
  #  source "$fpth"/service_functions.sh
  else
    echo -e  "$PNAME/${FUNCNAME[0]} : Can't find/source: ${1}\
      \nTerminates... " >&2
    exit 255
  fi
}

pathToSourcedFiles() {
  # shellcheck disable=SC2001,SC2086  # Escaped by sed
  pthname="$( echo $0  | sed 's/ /\\ /g' )"
  # We do escape any spaces, in the file name, 
  #  knew it could never happen, just in case.
  # shellcheck disable=SC2086  # Escaped by sed
  fpth="$(realpath $pthname)"; fpth="${fpth%/*}"
  echo "$fpth"
}


# Program vars, read only, 

PNAME=${0##*/}
VERSION='v0.0.4'
CURSCHEME="${PNAME%%.*}"


if [[ -t 1 ]] ; then
  RUNTIME_MODE="CONSOLE"
else
  RUNTIME_MODE="SERVICE"
fi

fbBinDir="$(pathToSourcedFiles)"

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/../service_functions.sh
fi

# asserting system/configuration context.
dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_DATA_HOME "$RUNTIME_MODE" "$CURSCHEME"


dieIfNotDirectoryExist "$XDG_BIN_HOME"
dieIfNotDirectoryExist "$XDG_DATA_HOME"

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/../shared_functions.sh
fi


consoleHasInternet "$CURSCHEME"
consoleFBfolderIsMounted "$CURSCHEME"

# Whatever the context, we need at least two parameters.

if [[ $# -lt 2 ]] ; then
  if [[ $RUNTIME_MODE == "SERVICE" ]] ; then
    notifyErr "${PNAME}/${FUNCNAME[0]}" "Too few parameters for us to \
run propely. Terminating..."

    exit 255
  elif [[ $# -eq 0 ]] ; then 
    echo -e "$PNAME : I need at least one argument \
to backup.\nExecute \"$PNAME -h\" for help. Terminating..." >&2
    exit 2
  # else If RUNTIME_MODE=DEBUG && $# -eq 1 -> maybe -h.
  fi
fi

# Vars below up here, to work globally and just not in the if block..
DEBUG=0
# controls whether we are going to print the backup command to the
# console/journal, (when DRYRUN=0) or if were actually going to perform.

if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then
# https://serverfault.com/questions/573946/how-can-i-send-a-message-to-the-systemd-journal-from-the-command-line
  exec 4>&2 2> >(while read -r REPLY; do printf >&4 '<3>%s\n' "$REPLY"; done)
  trap 'exec >&2-' EXIT

# Normal argument parsing happens here!
# TODO: Normal argument parsing.

else

  if [[ $# -lt 2 ]] ; then
    echo -e "$PNAME : Too few arguments. At least I need a backup-scheme\
and a full-symlink to the source for the backup.\nExecute \"$PNAME -h\" for \
help. Terminating..." >&2
   exit 2
  fi


help() {
cat  << EOF

$PNAME:  Creates a periodic  backup, made with the fb system services.

syntax:

  From cli during testing:
  $PNAME [options] <backup scheme>  <full-symlink-name>

  In production:
  $PNAME [options] <backup scheme>  <full-symlink-name>
  It is meant to be executed through *fbgovernor* and not individually,
  in production..

  Options:

  -h| --help.    Shows this help.
  -n| --dry-run  Shows what would have happened
  -v| --verbose  Shows more detailed output.
  -V| --version  Shows the version of $PNAME ($VERSION).

EOF
}

# shellcheck disable=SC2034
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
# End of command line parsing.

if [[ $# -ne 2 ]] ; then
    if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then
      notify-send "Folder Backup: ${0##*/}" "I didn't get two mandatory \
parameters: A backup scheme, and a job-folder, Hopefully you are \
executing from the commandline. Exiting hard."

      echo >&4 "<2>${0##*/} : I didn't get two mandatory parameters: A backup \
scheme, and a job-folder, Hopefully you are executing from the \
commandline. Exiting hard."
   else
      echo "${0##*/} : I didn't get two mandatory parameters: A backup \
scheme, and a job-folder, Hopefully you are executing from the \
commandline. Exiting hard."
  fi
  exit 255
fi

# Getting and validating parameters

BACKUP_SCHEME="${1}"

SYMLINK_NAME="${2}"


# shellcheck disable=SC2034
HAVING_ERRORS=false
# For the dry-run.

# Controls whether the  output (file listing) from tar will be sent to the
# journal when the script is run as a service.
# output is not normally sent to the journal from the CONSOLE/debug mode, ONLY
# when we simulate a "real" run of a service.  Then output will be sent to the
# journal anyway, when the script is run implicitly by a daemon. But not the
# ARCHIVE output, that is a choice.  And it is maybe best to have it on, so tha
# the user can turn it off.  The level of VERBOSITY is another option that will
# kick in, once ARCHIVE_OUPUT is true (0).



##### Qualify the jobs folder

JOBSFOLDER="$XDG_DATA_HOME"/fbjobs/"$BACKUP_SCHEME"

# we regenerate the folder where the symlinks are
# In the install script.

dieIfJobsFolderDontExist "$JOBSFOLDER" "$BACKUP_SCHEME" "$RUNTIME_MODE"

if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
  if [[ $RUNTIME_MODE == "SERVICE" ]] ; then
    echo >&4 "<7>${PNAME}: JOBSFOLDER: $JOBSFOLDER"
  else
    echo >&2 "${PNAME}: JOBSFOLDER: $JOBSFOLDER"
  fi
  # a debug message
fi

#####  Qualify the targets folder

# TODO: sjekk om innenfor FB som i OneShot.backup.
# TARGET FOLDER er et dårlig navn. SOURCE FOLDER bedre.
# må sjekke at ikke er innefor, fordi det er galt!

# TODO: I need to check if the symlink is all right!

dieIfBrokenSymlink "$JOBSFOLDER" "$SYMLINK_NAME" "$BACKUP_SCHEME"

TARGET_FOLDER=$(realpath "$JOBSFOLDER"/"$SYMLINK_NAME")
if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
  echo >&2 "${PNAME} TARGET_FOLDER: $TARGET_FOLDER"
  # debug message
fi

dieIfSourceIsWithinFBTree "$TARGET_FOLDER" "$BACKUP_SCHEME"

if [[ $VERBOSE = true || $DEBUG -eq 0  ]] ;  then
  echo -e >&2 "$PNAME : The target folder is NOT inside $FB.\n($1)."
elif [[ $DRYRUN = true ]] ; then
  echo -e >&2 "$PNAME : The target folder is NOT inside $FB.\n($1)."
# else we're passing through further down the road.
fi


# TODO: In theory we should check if the Periodic,
# and the backup scheme exists.

BACKUP_CONTAINER=$FB/Periodic/$BACKUP_SCHEME/$SYMLINK_NAME
# This is done in the fbsnapshot utility, and not in the
# OneShot.backup.sh, The "architecture" is "twisted".

assertBackupContainer "$BACKUP_CONTAINER"

# TODO: Maybe have a dbg_msg, ala fatal_error, that takes care of
# all the stuff that we otherwise have to litter our code with?
if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
  if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
    echo >&4 "<7>${PNAME} : the backups of $TARGET_FOLDER are stored in:\
$BACKUP_CONTAINER"
  else
    echo >&2 "${PNAME} : the backups of $TARGET_FOLDER are stored in:\
$BACKUP_CONTAINER"
  fi
  # TODO: Maybe raise this to notice.
fi

# its time to get the latest directory from the backup container and
# check the time stamp.


MUST_MAKE_TODAYS_FOLDER=1
MUST_MAKE_BACKUP=1
# we generate todays folder name.

TODAYS_BACKUP_FOLDER_NAME=\
"$BACKUP_CONTAINER"/$(baseNameDateStamped "$SYMLINK_NAME")
emptyBackupFolder=false

if [[ ! -d "$TODAYS_BACKUP_FOLDER_NAME"  ]] ; then
  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME : TODAYS_BACKUP_FOLDER_NAME : $TODAYS_BACKUP_FOLDER_NAME \
didn't exist!"
  fi
  probeDir="$(newestDirectory "$BACKUP_CONTAINER")"

  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME : probeDir =>$probeDir<="
  fi

  if [[ "$probeDir" == "$BACKUP_CONTAINER" ]] ; then 
      probeDir=""
  fi
else
  probeDir="$TODAYS_BACKUP_FOLDER_NAME"
  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME : dt: $probeDir"
  fi

  if  find "$probeDir" -maxdepth 0  -empty  -print | grep '.*' >/dev/null ; then
    emptyBackupFolder=true
  fi
fi
if [[ $DEBUG -eq 0 || "$VERBOSE" == true  ]] ; then

  echo >&2 "$PNAME : probeDir AFTER qualification  = : $probeDir"

fi

if [[ -z "$probeDir" || $emptyBackupFolder == true  ]] ; then
  # echo "newest dir doesn't exist." Means we have no folders to compare with.
  # so this is the first backup!
  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME : no files in probedir"
  fi
  MUST_MAKE_TODAYS_FOLDER=0
  MUST_MAKE_BACKUP=0
else

  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME: we might have  modified files"
    echo >&2 "$PNAME probedir = $probeDir"
  fi
  # we need to compare timestamps.
  find -H "$JOBSFOLDER"/"$SYMLINK_NAME" -cnewer "$probeDir" >&2
  echo >&2 "$PNAME : ERROR CODE AFTER FIND COMMAND: $? "
  if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
    echo >&2 "$PNAME modfiles = $modfiles"
  fi
  modfiles=$(find -H "$JOBSFOLDER"/"$SYMLINK_NAME" -cnewer "$probeDir")
  if [[ -n "$modfiles"  ]] ; then
    if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
      echo >&2 "$PNAME : Must make backup"
    fi
    # there are files to back up.
    MUST_MAKE_BACKUP=0
    if [[ "$probeDir" != "$TODAYS_BACKUP_FOLDER_NAME" ]] ; then
      MUST_MAKE_TODAYS_FOLDER=0
    fi
  else
    if [[  $DEBUG -eq 0 || "$VERBOSE" == true ]] ; then
      echo >&2 "$PNAME: no new files"
    fi
    # But, maybe the reason is, there are no files there?

  fi
fi

if [[ $MUST_MAKE_BACKUP -eq 0 ]] ; then

  if [[ $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then
    mkdir -p "$TODAYS_BACKUP_FOLDER_NAME"
  fi

  if hasExcludeFile "$BACKUP_SCHEME" "$SYMLINK_NAME" ; then
    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then

      if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
        :
      else
        echo >&2 "$PNAME : I have an exclude file : $EXCLUDE_FILE "
        cat "$EXCLUDE_FILE"
      fi
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

  if [[ $DRYRUN == true  ]] ; then

    if [[ $RUNTIME_MODE != "SERVICE"  ]] ; then
      trap "HAVING_ERRORS=true;ctrl_c" INT
      ctrl_c() {
        echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
        echo >&2 "$PNAME : We: rm -fr $DRY_RUN_FOLDER."
        rm -fr "$DRY_RUN_FOLDER"
      }
    fi

    DRY_RUN_FOLDER=$(mktemp -d "/tmp/$BACKUP_SCHEME.backup.sh.XXX")

    TAR_BALL_NAME=\
"$DRY_RUN_FOLDER"/"$(baseNameTimeStamped "$SYMLINK_NAME" )"-backup.tar.gz

    if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
       notifyErr  "$PNAME" ": sudo tar -z $VERBOSE_OPTIONS -c -f \
$TAR_BALL_NAME $EXCLUDE_OPTIONS -C $TARGET_FOLDER ."   | journalThis 7 "$BACKUP_SCHEME"

      if [[ $ARCHIVE_OUTPUT -eq 0 ]] ; then
        if [[ -z "$EXCLUDE_OPTIONS"  ]] ; then
          sudo tar -z  -c $VERBOSE_OPTIONS -f "$TAR_BALL_NAME" \
-C "$TARGET_FOLDER" . | journalThis 7 "$BACKUP_SCHEME"
        else
          sudo tar -z  -c $VERBOSE_OPTIONS -f "$TAR_BALL_NAME" \
"$EXCLUDE_OPTIONS" -C "$TARGET_FOLDER" . | journalThis 7 "$BACKUP_SCHEME"
        fi
      else
        if [[ -z "$EXCLUDE_OPTIONS"  ]] ; then
          sudo tar -z  -c $VERBOSE_OPTIONS -f "$TAR_BALL_NAME" \
-C "$TARGET_FOLDER" "."
        else
          sudo tar -z  -c $VERBOSE_OPTIONS -f "$TAR_BALL_NAME" \
"$EXCLUDE_OPTIONS" -C "$TARGET_FOLDER" . >/dev/null
        fi
      fi

    else

       echo >&2 "$PNAME : sudo tar -z $VERBOSE_OPTIONS -c -f \
$TAR_BALL_NAME $EXCLUDE_OPTIONS -C $TARGET_FOLDER . "

      if [[ -z "$EXCLUDE_OPTIONS"  ]] ; then
        sudo tar -z   $VERBOSE_OPTIONS -c -f "$TAR_BALL_NAME"  \
-C "$TARGET_FOLDER" "."
      else
        sudo tar -z   $VERBOSE_OPTIONS -c -f "$TAR_BALL_NAME" \
"$EXCLUDE_OPTIONS" -C "$TARGET_FOLDER" "."
      fi

    fi

    EXIT_STATUS=$?

    if [[ $EXIT_STATUS -gt 1 ]] ; then
      echo >&2 "$PNAME : exit status after tar commmand = $EXIT_STATUS"
    fi
   #   | journalThis 7 $BACKUP_SCHEME
    if [[ -d "$DRY_RUN_FOLDER" ]] ; then
        rm -fr "$DRY_RUN_FOLDER"
    fi
    if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
      notifyErr "$PNAME" " : rm -fr $DRY_RUN_FOLDER" | journalThis 7 "$BACKUP_SCHEME"
    else
      echo >&2 "$PNAME : rm -fr $DRY_RUN_FOLDER"
    fi

  else  # DRYRUN == false

    if [[ $RUNTIME_MODE != "SERVICE"  ]] ; then
      trap "HAVING_ERRORS=true;ctrl_c" INT
      ctrl_c() {
        echo trapped ctrl-c
        echo rm -f "$TAR_BALL_NAME"
        rm -f "$TAR_BALL_NAME"
      }
    fi

    TAR_BALL_NAME=\
"$TODAYS_BACKUP_FOLDER_NAME"/"$(baseNameTimeStamped "$SYMLINK_NAME" )"-backup.tar.gz

    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
      echo -e >&2 "$PNAME : sudo tar -z -c $VERBOSE_OPTIONS -c  $EXCLUDE_OPTIONS\
        -f $TAR_BALL_NAME  -C $TARGET_FOLDER" .
    fi
      if [[ -z "$EXCLUDE_OPTIONS"  ]] ; then
        sudo tar -z $VERBOSE_OPTIONS -c -f "$TAR_BALL_NAME" \
-C "$TARGET_FOLDER" .
      else
        sudo tar -z $VERBOSE_OPTIONS -c "$EXCLUDE_OPTIONS" -f \
"$TAR_BALL_NAME" -C "$TARGET_FOLDER" .
      fi
    EXIT_STATUS=$?
   #   | journalThis 7 $BACKUP_SCHEME
    if [[ $EXIT_STATUS -gt 1 ]] ; then

      if [[ $RUNTIME_MODE == "SERVICE"   ]] ; then
        notifyErr "$PNAME" " : exit status after tar commmand (fatal error)\
= $EXIT_STATUS" | journalThis 3 "$BACKUP_SCHEME"
      else
        echo >&2 "$PNAME : exit status after tar commmand (fatal error)\
= $EXIT_STATUS"
      fi

      if [[ -f "$TAR_BALL_NAME" ]] ; then
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
          if [[ "$RUNTIME_MODE" == "SERVICE"  ]] ; then
            notifyErr "$PNAME" " : A tarball was made, probably full of errors\
\n rm -f $TAR_BALL_NAME" | journalThis 7 "$BACKUP_SCHEME"
          else
            echo -e  >&2 "$PNAME : A tarball was made, probably full of errors\
\n rm -f $TAR_BALL_NAME"

          fi
        fi

        rm -f "$TAR_BALL_NAME"

        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
          if [[ "$RUNTIME_MODE" == "SERVICE"  ]] ; then
            notifyErr "$PNAME" " : Removing the tar ball we  made: \
$TAR_BALL_NAME "| journalThis 3 "$BACKUP_SCHEME"
          else
            echo >&2 "$PNAME" " : Removing the tar ball we  made: \
$TAR_BALL_NAME "
          fi
        fi
        if [[ $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then
          if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
            if [[ "$RUNTIME_MODE" == "SERVICE"  ]] ; then
              notifyErr "$PNAME" " : Removing the backup folder made: \
$TODAYS_BACKUP_FOLDER_NAME "| journalThis 3 "$BACKUP_SCHEME"
            else
              echo >&2 "$PNAME" " : Removing the backup folder made: \
$TODAYS_BACKUP_FOLDER_NAME "
            fi
          fi
          rmdir -fr "$TODAYS_BACKUP_FOLDER_NAME"
          MUST_MAKE_TODAYS_FOLDER=1
          # TODO: fylle inn med verbose/debug messages på steder som dette
          # teste ut hva vi har så langt med dryrun.
        fi
      fi
    elif [[ $EXIT_STATUS -eq 0 ]] ; then
      # TODO: denne bare ut hvis CONSOLE , og da litt bedre melding.
      echo -e "\n($TAR_BALL_NAME)\n"
    fi
  fi
fi


if [[ $DRYRUN == false && $MUST_MAKE_BACKUP -eq 0 \
  && $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then

  # Is the number of backups we have bigger than  $DAYS_TO_KEEP_BACKUPS?


  echo "\$TODAYS_BACKUP_FOLDER_NAME : $TODAYS_BACKUP_FOLDER_NAME"
  while true ; do

  folderCount="$(backupDirectoryCount "$BACKUP_CONTAINER")"

    if [[ $folderCount -gt $DAYS_TO_KEEP_BACKUPS  ]] ; then
      # we need to remove the oldest one.
      dirToRemove="$(oldestDirectory "$BACKUP_CONTAINER")"
      if [[ -z "$dirToRemove" ]] ; then
        #  idk if this even is possible.
        if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then
          notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "The backup \
  container ${BACKUP_CONTAINER} doesn't have any older folders than itself! \
  You need to investigate the situation, to remedy it!"
          echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: The backup \
  container ${BACKUP_CONTAINER} doesn't have any older folders than itself! \
  You need to investigate the situation, to remedy it."
        else
          echo >&2 "${0##*/}/${FUNCNAME[0]}: The backup \
  container ${BACKUP_CONTAINER} doesn't have any older folders than itself! \
  You need to investigate the situation, to remedy it!"
        fi
      else
        if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
          if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then
            notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "Removing the \
  old backup ${dirToRemove} by rotation."
            echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: Removing the \
  old backup ${dirToRemove} by rotation."
          else
            echo >&2 "${0##*/}/${FUNCNAME[0]}: Removing the \
  old backup ${dirToRemove} by rotation."
          fi
        fi
 
        if !  rm -fr "$dirToRemove" ; then
          if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
            if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then
              notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "Removing the \
    old backup ${dirToRemove} by rotation FAILED\nTerminates..."
              echo -e >&4 "<0>${0##*/}/${FUNCNAME[0]}: Removing the \
    old backup ${dirToRemove} by rotation FAILED\nTerminates..."
            else
              echo -e >&2 "${0##*/}/${FUNCNAME[0]}: Removing the \
    old backup ${dirToRemove} by rotation FAILED\nTerminates..."
            fi
          fi

          exit 1
        else
          folderCount=$((folderCount - 1))
        fi
      fi

    fi
    if [[ $folderCount -le $DAYS_TO_KEEP_BACKUPS ]] ; then
        break
    fi
  done
fi
