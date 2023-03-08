#!/bin/bash
# HourlySnapshot.backup.sh
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

err_report() {
  echo >&2 "$PNAME : Error on line $1"
  echo >&2 "$PNAME : Please report this issue at \
'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR

# CONFIG VARIABLES ONLY AVAILABLE IN THE SCRIPT

DAYS_TO_KEEP_BACKUPS=14 # set to 0 to disable backup rotation.

ARCHIVE_OUTPUT=1 # only controls ouput during  DRY_RUN

#   Controls whether the  output (file listing) from tar will be sent to the
#   journal when the script is run as a service.  output is not normally sent
#   to the journal from the CONSOLE/debug mode, ONLY when we simulate a "real"
#   run of a service.  Then output will be sent to the journal anyway, when the
#   script is run implicitly by a daemon. But not the ARCHIVE output, that is a
#   choice.  And it is maybe best to have it on, so tha the user can turn it
#   off.  The level of VERBOSITY is another option that will kick in, once
#   ARCHIVE_OUPUT is true (-1).

TERSE_OUTPUT=${TERSE_OUTPUT:=1}
# If we are called from the command line and not by governor.sh, then 
# TERSE_OUTPUT wasn't set, so we set it false.

SILENT=1
# Controls whether to send success message
# when verbose = false, upon completed backup.

DEBUG=1 # controls output during debugging.


# CONFIG VARIABLES you can set to mostly control output. You can  use, them
# especially when invoking the DELEGATE (this script) indirectly by the
# governor, as a service, (in SERVICE_MODE) otherwise, I think it would be
# easier in most cases to specify options, when run from the command line in
# CONSOLE_MODE,the configuration variables, doesn't override  options set on
# the command line, on the contrary. Any command line options will override,
# any value set for that variable in the script.


# TODO: check if it only touches folders of correct form when
# performing backup rotation.

DRY_RUN=false

VERBOSE=false # controls output during normal runs.


# dieIfCantSourceShellLibrary()
# sources the ShellLibraries
# so we can perform the rest of the tests.
dieIfCantSourceShellLibrary() {
# TODO:
# Can't Think of modus here, (routDebugMsg/notifyError, as the source libs aren't
# loaded yet, but I can hardcode it.
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


# PROGRAM VARIABLES, read only, 

PNAME=${0##*/}
VERSION='v0.0.4'
curscheme="${PNAME%%.*}"


if [[ -t 1 ]] ; then
  RUNTIME_MODE="CONSOLE"
else
  RUNTIME_MODE="SERVICE"
fi

fbBinDir="$(pathToSourcedFiles)"
through_shellcheck=0
if [[ $through_shellcheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/../service_functions.sh
fi


# asserting system/configuration context.
dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$curscheme"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$curscheme"
dieIfMandatoryVariableNotSet XDG_DATA_HOME "$RUNTIME_MODE" "$curscheme"

dieIfNotDirectoryExist "$XDG_BIN_HOME"
dieIfNotDirectoryExist "$XDG_DATA_HOME"
dieIfNotDirectoryExist "$XDG_DATA_HOME/fbjobs"

if [[ $through_shellcheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/../shared_functions.sh
fi

dieIfNotOkBashVersion
consoleHasInternet "$curscheme"
consoleFBfolderIsMounted "$curscheme"


if [[ $# -lt 2 ]] ; then
  if [[ $RUNTIME_MODE == "SERVICE" ]] ; then
# As a service, we need at least two parameters.
    notifyErr "$PNAME/${FUNCNAME[0]}" "Too few parameters for us to run propely. Terminating..." \
      | journalThis 3 FolderBackup
    exit 255
  fi
fi


if [[ "$RUNTIME_MODE" == "CONSOLE" ]] ; then
# Normal argument parsing happens here as cli invoked here.

  if [[ $# -lt 1 ]] ; then
    echo -e "$PNAME : Too few arguments. At least I need a backup-scheme\
and a full-symlink to the source for the backup.\nExecute \"$PNAME -h\" for \
help. Terminating..." >&2
   exit 2
  # else If RUNTIME_MODE=CONSOLE && $# -eq 1 -> maybe -h.
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
        -n | --dry-run ) DRY_RUN=true; shift ;;
        -v | --verbose ) VERBOSE=true; shift ;;
        -V | --version ) echo "$PNAME" : $VERSION ; exit 0 ;;
        -- ) shift; break ;;
      esac
  done

  if [[ $# -ne 2 ]] ; then
    echo -e >&2 "I didn't get two mandatory  parameters: A backup scheme, and a job-folder. Terminating..."
    exit 2
  fi

fi
# End of command line parsing.

# Getting and validating parameters
backup_scheme="${1}"

symlink_name="${2}"

# Qualify the jobs folder


jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"
dieIfJobsFolderDontExist "$jobs_folder" "$backup_scheme" "$RUNTIME_MODE"

if [[ $DEBUG -eq 0 ]] ; then
  routDebugMsg " : jobs_folder: $jobs_folder" "$backup_scheme"
fi

#  Qualify the source folder

dieIfBrokenSymlink "$jobs_folder" "$symlink_name" "$backup_scheme"

if [[ $DEBUG -eq 0 ]] ; then
  echo >&2 "realpath $jobs_folder/$symlink_name"
fi

source_folder=$(realpath "$jobs_folder"/"$symlink_name")
if [[ $DEBUG -eq 0 ]] ; then
  routDebugMsg " : source_folder: $source_folder" "$backup_scheme"
fi

dieIfSourceIsWithinFBTree "$source_folder" "$backup_scheme"

if [[ $DEBUG -eq 0 || $DRY_RUN == true ]] ;  then
  routDebugMsg " : The target folder is NOT inside $FB. ($1)." "$backup_scheme"
fi

backup_container=$FB/Periodic/$backup_scheme/$symlink_name

assertBackupContainer "$backup_container"

if [[ $DEBUG -eq 0 ]] ; then
  routDebugMsg " : the backups of $source_folder are stored in:\
$backup_container" "$backup_scheme"
fi

MUST_MAKE_TODAYS_FOLDER=1
MUST_MAKE_BACKUP=1

todays_backup_folder_name=\
"$backup_container"/$(baseNameDateStamped "$symlink_name")
emptyBackupFolder=false

if [[ ! -d "$todays_backup_folder_name"  ]] ; then
  if [[  $DEBUG -eq 0  ]] ; then

    routDebugMsg " : qualification:  todays_backup_folder_name : \
$todays_backup_folder_name  didn't exist!" "$backup_scheme"
  fi
  probeDir="$(newestDirectory "$backup_container")"

  if [[  $DEBUG -eq 0 ]] ; then
    routDebugMsg " : qualification probeDir =>$probeDir<=" "$backup_scheme"
  fi

  if [[ "$probeDir" == "$backup_container" ]] ; then
      probeDir=""
  fi
else
  probeDir="$todays_backup_folder_name"
  if [[  $DEBUG -eq 0 ]] ; then
    routDebugMsg " : qualification: Todays backup folder existed : \
$probeDir" "$backup_scheme"
  fi

  if  find "$probeDir" -maxdepth 0  -empty  -print | grep '.*' >/dev/null ; then
    emptyBackupFolder=true
  fi
fi
if [[ $DEBUG -eq 0  ]] ; then
  routDebugMsg " : probeDir AFTER qualification  = : $probeDir" "$backup_scheme"
fi

if [[ -z "$probeDir" || $emptyBackupFolder == true  ]] ; then
  # echo "newest dir doesn't exist." Means we have no folders to compare with.
  # so this is the first backup!
  if [[  $DEBUG -eq 0 ]] ; then
    routDebugMsg " : no files in probedir, it's empty and we need  to take a \
backup." "$backup_scheme"
  fi
  MUST_MAKE_TODAYS_FOLDER=0
  MUST_MAKE_BACKUP=0
else

  if [[  $DEBUG -eq 0 ]] ; then
    routDebugMsg " : we might have  modified files probedir = $probeDir" \
      "$backup_scheme"
  fi

  # we need to compare timestamps.
  modfiles=$(find -H "$jobs_folder"/"$symlink_name" -cnewer "$probeDir" 2>&1)
  if [[ -n "$modfiles"  ]] ; then
      routNotification " : There are modified or added files since last backup. \
        We will take a backup of $(realpath $jobs_folder/$symlink_name)."  "$backup_scheme"
    # there are files to back up.
    MUST_MAKE_BACKUP=0
    if [[ "$probeDir" != "$todays_backup_folder_name" ]] ; then
      MUST_MAKE_TODAYS_FOLDER=0
    fi
  else
      routNotification " : No new or modified files, since last backup of \
$(realpath $jobs_folder/$symlink_name)."  "$BACKUP_SCHEME"
    # But, maybe the reason is, there are no files there?
  fi
fi

if [[ $MUST_MAKE_BACKUP -eq 0 ]] ; then

  if [[ $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then
    mkdir -p "$todays_backup_folder_name"
  fi

  if hasExcludeFile "$backup_scheme" "$symlink_name" ; then
    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then

      routDebugMsg " : I have an exclude file : $EXCLUDE_FILE " "$backup_scheme"
      if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
        cat "$EXCLUDE_FILE" | systemd-cat -p 7 -t "$backup_scheme"
      else
        cat "$EXCLUDE_FILE" 1>&2
      fi
    fi
    exclude_options="--exclude-from=$EXCLUDE_FILE"
  else
    exclude_options=
  fi

  if [[ $VERBOSE = true ]] ; then
    verbose_options="-v -v"
  else
    verbose_options="-v"
  fi

  exit_code=0

  if [[ $DRY_RUN == true  ]] ; then

    if [[ $RUNTIME_MODE != "SERVICE"  ]] ; then
      trap "ctrl_c" INT
      ctrl_c() {
        echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
        echo >&2 "$PNAME : We: rm -fr $dry_run_folder."
        rm -fr "$dry_run_folder"
      }
    fi

    dry_run_folder=$(mktemp -d "/tmp/$backup_scheme.backup.sh.XXX")

    tar_ball_name=\
"$dry_run_folder"/"$(baseNameTimeStamped "$symlink_name" )"-backup.tar.gz

    if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
       notifyErr  "$PNAME" ": sudo tar -z $verbose_options -c -f \
$tar_ball_name $exclude_options -C $source_folder ." \
| journalThis 7 "$backup_scheme"

      if [[ $ARCHIVE_OUTPUT -eq 0 ]] ; then
        if [[ -z "$exclude_options"  ]] ; then
          sudo tar -z  -c $verbose_options -f "$tar_ball_name" \
-C "$source_folder" . | journalThis 7 "$backup_scheme"
        else
          sudo tar -z  -c $verbose_options -f "$tar_ball_name" \
"$exclude_options" -C "$source_folder" . | journalThis 7 "$backup_scheme"
        fi
      else
        if [[ -z "$exclude_options"  ]] ; then
          sudo tar -z  -c $verbose_options -f "$tar_ball_name" \
-C "$source_folder" "."
        else
          sudo tar -z  -c $verbose_options -f "$tar_ball_name" \
"$exclude_options" -C "$source_folder" . >/dev/null
        fi
      fi

    else
      # CONSOLE
       echo >&2 "$PNAME : sudo tar -z $verbose_options -c -f \
$tar_ball_name $exclude_options -C $source_folder . "

      if [[ -z "$exclude_options"  ]] ; then
        sudo tar -z   $verbose_options -c -f "$tar_ball_name"  \
-C "$source_folder" "."
      else
        sudo tar -z   $verbose_options -c -f "$tar_ball_name" \
"$exclude_options" -C "$source_folder" "."
      fi

    fi

    exit_code=$?

    if [[ $exit_code -gt 1 ]] ; then
      if [[ "$RUNTIME_MODE" == "SERVICE" ]] ; then 
        notifyErr "$PNAME : exit status after tar commmand = $exit_code" \
| journalThis 5 "$backup_scheme"
      else
        echo >&2 "$PNAME : exit status after tar commmand = $exit_code"
      fi
    fi

    if [[ -d "$dry_run_folder" ]] ; then
        rm -fr "$dry_run_folder"
    fi
    if [[ $RUNTIME_MODE == "SERVICE"  ]] ; then
      if [[  $DEBUG -eq 0 ]] ; then
        routDebugMsg "$PNAME" " : rm -fr $dry_run_folder" \
| journalThis 7 "$backup_scheme"
      fi
    else
      if [[  $DEBUG -eq 0 ]] ; then
        echo >&2 "$PNAME : rm -fr $dry_run_folder"
      fi
    fi

  else  # DRY_RUN == false

    if [[ $RUNTIME_MODE != "SERVICE"  ]] ; then
      trap "trl_c" INT
      ctrl_c() {
        echo trapped ctrl-c
        echo rm -f "$tar_ball_name"
        rm -f "$tar_ball_name"
      }
    fi

    tar_ball_name=\
"$todays_backup_folder_name"/"$(baseNameTimeStamped "$symlink_name" )"-backup.tar.gz

    if [[ -z "$exclude_options"  ]] ; then
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        routDebugMsg " : sudo tar -z -c $verbose_options -c  \
          -f $tar_ball_name  -C $source_folder ." "$backup_scheme"
      fi
      sudo tar -z $verbose_options -c -f "$tar_ball_name" \
-C "$source_folder" .
    else
      # TODO: MAYBE  put in a block, testing for CONSOLE and adding setbuf
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        routDebugMsg " : sudo tar -z -c $verbose_options -c  $exclude_options\
          -f $tar_ball_name  -C $source_folder" .
      fi
      sudo tar -z $verbose_options -c "$exclude_options" -f \
"$tar_ball_name" -C "$source_folder" .
    fi
    exit_code=$?
    if [[ $exit_code -gt 1 ]] ; then

      if [[ $RUNTIME_MODE == "SERVICE"   ]] ; then
        notifyErr "$PNAME" " : exit status after tar commmand (fatal error)\
= $exit_code" | journalThis 3 "$backup_scheme"
      else
        echo >&2 "$PNAME : exit status after tar commmand (fatal error)\
= $exit_code"
      fi

      if [[ -f "$tar_ball_name" ]] ; then
        if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg "$PNAME" " : A tarball was made, probably full of \
errors rm -f $tar_ball_name" "$backup_scheme"
        fi

        rm -f "$tar_ball_name"

        if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg " : Removing the tar ball we  made: \
$tar_ball_name " "$backup_scheme"
        fi
        if [[ $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then
          if [[  $DEBUG -eq 0 ]] ; then
              routDebugMsg " : Removing the backup folder made: \
$todays_backup_folder_name " "$backup_scheme"
            fi
          fi
          rmdir -fr "$todays_backup_folder_name"
          MUST_MAKE_TODAYS_FOLDER=1
        fi
    elif [[ $exit_code -eq 0 ]] ; then

      if [[ $SILENT -ne 0 && $TERSE_OUTPUT -ne 0 ]] ; then
        notifyErr "$PNAME" " : Successful backup: ($tar_ball_name) " \
        | journalThis 5 "$backup_scheme"
      fi
    fi
  fi
else
  if [[ $DEBUG -ne 0 && $SILENT -ne 0 && $TERSE_OUTPUT -ne 0 ]] ; then
    if [[ "$MODE" == "SERVICE" ]] ; then
      notifyErr "$PNAME" " : No need to  backup $symlink_name: No files \
changed or added since last backup. "  | journalThis 5 "$backup_scheme"
    else
      echo >&2 "$PNAME" " : No need to  backup $symlink_name: No files \
changed or added since last backup. " 
    fi
  fi
  exit_code=1
fi

if [[ $exit_code -ne 0 ]] ; then
  exit $exit_code ;
fi

if [[ $DRY_RUN == false && $MUST_MAKE_BACKUP -eq 0 \
  && $MUST_MAKE_TODAYS_FOLDER -eq 0 ]] ; then

  # Is the number of backups we have bigger than  $DAYS_TO_KEEP_BACKUPS?
  while true ; do

  folderCount="$(backupDirectoryCount "$backup_container")"

    if [[ $folderCount -gt $DAYS_TO_KEEP_BACKUPS  ]] ; then
      # we need to remove the oldest one.
      dirToRemove="$(oldestDirectory "$backup_container")"
      if [[ -z "$dirToRemove" ]] ; then
        #  idk if this even is possible.
        if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
          routDebugMsg  " : The backup  container ${backup_container} doesn't \
have any older folders than itself!  You need to investigate the situation, \
to remedy it!"  "$backup_scheme"
        fi
      else
        if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
            routDebugMsg " : Removing the old backup ${dirToRemove} by \
rotation." "$backup_scheme"
        fi

        if !  rm -fr "$dirToRemove" ; then
          if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
            routDebugMsg "E[0]}" "Removing the  old backup ${dirToRemove} by \
rotation FAILED Terminates..." "$backup_scheme"
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
