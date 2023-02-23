#!/bin/bash
# shellcheck disable=SC2034
VERSION="v0.0.4"
# Governor.sh
# We are getting the backup-scheme passed as parameter from the
# <backup-scheme>.service, invoked by <backup-scheme>.timer.

# We check for an empty job folder first of all, and if it is, we shut down the
# whole service, and exits gracefully. Otherwise, we're calling up the
# manager(), to figure out the correct script to execute for that
# scheme/symlink, processes the next one, and so on.

# First we check if there is any jobs to dispatch from the jobs folder.


# Moving forward:
# Using the XDG_DATA_HOME, would give some leeway as to avoiding hard_coding of paths.
# We are still using this with service. SnapShot

# Config vars you can set to mostly control output.
DEBUG=1
VERBOSE=false
# VERBOSE = TRUE is more of a debug option giving the hints as to what is processed
# With what.
export TERSE_OUTPUT=0
# Maybe we want a per scheme handling of  TERSE_OUTPUT
success_jobs=()


err_report() {
  echo >&2 "$PNAME : Error on line $1"
  echo >&2 "$PNAME : Please report this issue at \
'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR



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

curscheme="${PNAME%%.*}"

if [[ -t 1 ]] ; then
  RUNTIME_MODE="CONSOLE"
else
  RUNTIME_MODE="SERVICE"
fi


fbBinDir="$(pathToSourcedFiles)"
through_shellsheck=1
if [[ $through_shellsheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/service_functions.sh
fi

if [[ $# -ne 1 ]] ; then

  if [[ $RUNTIME_MODE == "SERVICE" ]] ; then
    notifyErr "$PNAME" "I didn't get a mandatory parameter (backup-scheme). Terminating..." \
      | journalThis 2 FolderBackup
    exit 255
  else
    echo -e >&2 "$PNAME : I didn't get a mandatory parameter.\
.. Enter: \"$PNAME -h\" for help.\nTerminating..."
  exit 2
  fi
fi


dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$curscheme"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$curscheme"
dieIfMandatoryVariableNotSet XDG_DATA_HOME "$RUNTIME_MODE" "$curscheme"

dieIfNotDirectoryExist "$XDG_BIN_HOME"
dieIfNotDirectoryExist "$XDG_BIN_HOME/fb"
dieIfNotDirectoryExist "$XDG_DATA_HOME"
dieIfNotDirectoryExist "$XDG_DATA_HOME/fbjobs"

if [[ $through_shellsheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/shared_functions.sh
fi


dieIfNotOkBashVersion
consoleHasInternet "$curscheme"
consoleFBfolderIsMounted "$curscheme"

backup_scheme=${1}

jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

dieIfJobsFolderDontExist "$jobs_folder" "$backup_scheme" "$RUNTIME_MODE"
#  the folder we pick up the symlinks we are going to backup.


jobs_list="$(find "$jobs_folder" -mindepth 1 -maxdepth 1 \
  | sed -ne 's,^.*[/],,' -e '/.pause/ !p')"

if [[ -z "$jobs_list" ]] ; then
  # We have nothing to  do, and die silently.
  if [[ $DEBUG -eq 0 ]] ; then
   routDebugMsg " : No symlinks, nothing to do. We are \
shutting down this service." "$backup_scheme"
  fi
  exit 0
fi


scheme_container="$( assertSchemeContainer "$backup_scheme" )"
# the container with backups of that scheme on the GoogleDrive.
# makes the container, and parent! shouldn't one or both exist.

for symlink_name in $jobs_list ; do
  if isASymlink "$jobs_folder"/"$symlink_name" ; then

    if [[ $DEBUG -eq 0 ]] ; then
      routDebugMsg " : $symlink_name is a  symlink_name." "$backup_scheme"
    fi

    if isUnbrokenSymlink "$jobs_folder"/"$symlink_name" ; then
      if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
        routDebugMsg ": currently processing the symlink $symlink_name\
(unbroken).\n" "$backup_scheme"
      fi
      # we need the real path
      target_folder="$(realpath "$jobs_folder"/"$symlink_name")"
      if [[ $DEBUG -eq 0 ]] ; then
        routDebugMsg " : Realpath is $target_folder." "$backup_scheme"
      fi

      if [[ ! -f $jobs_folder/$symlink_name.pause ]] ; then
        backup_container=$scheme_container/$symlink_name
        # Alt med backup_container skal over i fbinst e.l fbctl
        if [[ ! -d $backup_container ]] ; then
          mkdir -p "$backup_container"
          # we can go silent about this, or we can just send a message.
          if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg " : $backup_container didn't exist, que to \
make backup" "$backup_scheme"
          fi
        else
          if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg " :$backup_container exists, NO que to make \
backup." "$backup_scheme"
          fi
        fi

        manager "$backup_scheme"  "$symlink_name" backup
        exit_code=$?
        if [[ $exit_code  -eq 0 ]] ; then
          backup_script="$DELEGATE_SCRIPT"
        else
          exit $exit_code
        fi
        if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then 
          routDebugMsg " : Command line after manager: \
$backup_script $backup_scheme $symlink_name" "$backup_scheme"
        fi
        trap '' ERR
        "$backup_script" "$backup_scheme" "$symlink_name"
        exit_code=$?
        trap 'err_report $LINENO' ERR
        if [[ $exit_code -eq 0 && $TERSE_OUTPUT -eq 0  ]] ; then
          success_jobs+=( "$(pathFromFullSymlinkName "$symlink_name" )" )
        fi
        # TODO:  If exit status ok, put symlink into array,
        # for possible collective message.
      else
        # there was a pause file
        if [[ $DEBUG -eq 0  ]] ; then
          routDebugMsg " : I found a $jobs_folder/$symlink_name.pause\
 file and skips this job ... for now." "$backup_scheme"
        fi
      fi
    else
      # broken symlink
      if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
        routDebugMsg "$PNAME : The symlink $symlink_name is broken." \
"$backup_scheme"
      fi
      # this goes to the journal land a notification is sent.
      brokenSymlink "$jobs_folder" "$symlink_name" "$backup_scheme:${0##*/}"
    fi
  # else NOT A symlink_name, we just ignore.
  fi
done

if [[ $TERSE_OUTPUT -eq 0 ]] ; then

  if [[ ${#success_jobs[@]} -ne 0 ]] ; then
    if [[ "$MODE" == "SERVICE" ]] ; then
      notifyErr "$PNAME" " : Successful backup: of ${success_jobs[@]}." \
        | journalThis 5 "$backup_scheme"
    else
      echo >&2 "$PNAME" " : Successful backup: of ${success_jobs[@]}."
    fi
  else
    if [[ "$MODE" == "SERVICE" ]] ; then
      notifyErr "$PNAME" " : Nothing to backup: at this time. " \
        | journalThis 5 "$backup_scheme"
    else
      echo >&2 "$PNAME" " : Nothing to backup: at this time. "
    fi
  fi
fi

# // kommandoer for å se meldinger for jobb i logg.
# forexample : DailyDifflog.
if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then 
  echo >&2 "$PNAME passed tests!"
fi
