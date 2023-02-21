#!/bin/bash
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

# shellcheck disable=SC2034
VERSION='v0.0.4'
CURSCHEME="${PNAME%%.*}"

if [[ -t 1 ]] ; then
  RUNTIME_MODE="CONSOLE"
else
  RUNTIME_MODE="SERVICE"
fi


fbBinDir="$(pathToSourcedFiles)"

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/service_functions.sh
fi

if [[ $# -ne 1 ]] ; then

  if [[ $RUNTIME_MODE == "SERVICE" ]] ; then
    notifyErr "$PNAME" "I didn't get a mandatory parameter (backup-scheme).\
\nTerminating..." | journalThis 2 FolderBackup
    exit 255
  else
    echo -e >&2 "$PNAME : I didn't get a mandatory parameter.\
.. Enter: \"$PNAME -h\" for help.\nTerminating..."
  exit 2
  fi
fi

dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_DATA_HOME "$RUNTIME_MODE" "$CURSCHEME"

dieIfNotDirectoryExist "$XDG_BIN_HOME"
dieIfNotDirectoryExist "$XDG_BIN_HOME/fb"
dieIfNotDirectoryExist "$XDG_DATA_HOME"
dieIfNotDirectoryExist "$XDG_DATA_HOME/fbjobs"

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/shared_functions.sh
fi


consoleHasInternet "$CURSCHEME"
consoleFBfolderIsMounted "$CURSCHEME"

BACKUP_SCHEME=${1}

JOBS_FOLDER="$XDG_DATA_HOME"/fbjobs/"$BACKUP_SCHEME"

dieIfJobsFolderDontExist "$JOBS_FOLDER" "$BACKUP_SCHEME" "$RUNTIME_MODE"



JOBS_LIST="$(find "$JOBS_FOLDER" -mindepth 1 -maxdepth 1 \
  | sed -ne 's,^.*[/],,' -e '/.pause/ !p')"

if [[ -z "$JOBS_LIST" ]] ; then
  # We have nothing to  do, and die silently.
  if [[ $DEBUG -eq 0 ]] ; then
   routDebugMsg " : No symlinks, nothing to do. We are \
shutting down this service." "$BACKUP_SCHEME"
  fi
  exit 0
fi


SCHEME_CONTAINER="$( assertSchemeContainer "$BACKUP_SCHEME" )"

for SYMLINK in $JOBS_LIST ; do
  if isASymlink "$JOBS_FOLDER"/"$SYMLINK" ; then

    if [[ $DEBUG -eq 0 ]] ; then
      routDebugMsg " : $SYMLINK is a  SYMLINK." "$BACKUP_SCHEME"
    fi

    if isUnbrokenSymlink "$JOBS_FOLDER"/"$SYMLINK" ; then
      if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
        routDebugMsg ": currently processing the symlink $SYMLINK\
(unbroken).\n" "$BACKUP_SCHEME"
      fi
      # we need the real path
      target_folder="$(realpath "$JOBS_FOLDER"/"$SYMLINK")"
      if [[ $DEBUG -eq 0 ]] ; then
        routDebugMsg " : Realpath is $target_folder." "$BACKUP_SCHEME"
      fi

      if [[ ! -f $JOBS_FOLDER/$SYMLINK.pause ]] ; then
        BACKUP_CONTAINER=$SCHEME_CONTAINER/$SYMLINK
        # Alt med BACKUP_CONTAINER skal over i fbinst e.l fbctl
        if [[ ! -d $BACKUP_CONTAINER ]] ; then
          mkdir -p "$BACKUP_CONTAINER"
          # we can go silent about this, or we can just send a message.
          if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg " : $BACKUP_CONTAINER didn't exist, que to \
make backup" "$BACKUP_SCHEME"
          fi
        else
          if [[ $DEBUG -eq 0 ]] ; then
            routDebugMsg " :$BACKUP_CONTAINER exists, NO que to make \
backup." "$BACKUP_SCHEME"
          fi
        fi

        manager "$BACKUP_SCHEME"  "$SYMLINK" backup
        exit_code=$?
        if [[ $exit_code  -eq 0 ]] ; then
          BACKUP_SCRIPT="$DELEGATE_SCRIPT"
        else
          exit $exit_code
        fi
        if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then 
          routDebugMsg " : Command line after manager: \
$BACKUP_SCRIPT $BACKUP_SCHEME $SYMLINK" "$BACKUP_SCHEME"
        fi
        "$BACKUP_SCRIPT" "$BACKUP_SCHEME" "$SYMLINK"
      else
        # there was a pause file
        if [[ $DEBUG -eq 0  ]] ; then
          routDebugMsg " : I found a $JOBS_FOLDER/$SYMLINK.pause\
 file and skips this job ... for now." "$BACKUP_SCHEME"
        fi
      fi
    else
      # broken symlink
      if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
        routDebugMsg "$PNAME : The symlink $SYMLINK is broken." \
"$BACKUP_SCHEME"
      fi
      # this goes to the journal land a notification is sent.
      brokenSymlink "$JOBS_FOLDER" "$SYMLINK" "$BACKUP_SCHEME:${0##*/}"
    fi
  # else NOT A SYMLINK, we just ignore.
  fi
done

# // kommandoer for å se meldinger for jobb i logg.
# forexample : DailyDifflog.
if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then 
  echo >&2 "$PNAME passed tests!"
fi
