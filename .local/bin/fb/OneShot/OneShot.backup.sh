#!/bin/bash
# The version at a8de2b1 contains the scaffolding.
# shellcheck disable=SC2089
VERSION="\"v0.0.4\""


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
    echo -e >&2 "$PNAME/${FUNCNAME[0]} : Need an\
    argument, an existing fb shell library file!\nTerminates..." >&2
    exit 5
  fi
  if [[ -r "${1}" ]] ; then
    source "${1}"
  #  source "$fpth"/service_functions.sh
  else
    echo -e >&2 "$PNAME/${FUNCNAME[0]} : Can't find/source: ${1}\
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

MODE="CONSOLE"

fbBinDir="$(pathToSourcedFiles)"
through_shellcheck=1
if [[ $through_shellcheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/../service_functions.sh
fi

# Configuration variables that will be overruled by options.
DRY_RUN=false
# controls whether we are going to print the backup command to the
# console/journal, (when DRY_RUN=0) or if were actually going to perform.
DEBUG=0
#
# prints out debug messages to the console/journal if its on when instigated\
# systemd --user.

# asserting system/configuration context.
dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$curscheme"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$curscheme"


dieIfNotDirectoryExist "$XDG_BIN_HOME"

if [[ $through_shellcheck -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/../shared_functions.sh
fi

dieIfNotOkBashVersion
consoleHasInternet OneShot
consoleFBfolderIsMounted OneShot

if [[ $# -eq 0 ]] ; then
  echo -e >&2 "$PNAME : Too few arguments. At least I need a folder target \
to backup.\nExecute \"$PNAME -h\" for help. Terminating..." >&2
 exit 2
fi

help() {
cat  << EOF

$PNAME:  Makes  a folder backup, part of the FB system.

syntax:

  $PNAME [options] <source folder> <destination> <full-symlink-name>
  It is meant to be executed by *fboneshot* and not individually.

  Options:

  -h| --help.    Shows this help.
  -n| --dry-run  Shows what would have happened
  -v| --verbose  Shows more detailed output.
  -V| --version  Shows the version of $PNAME ($VERSION).

EOF
}
# shellcheck disable=SC2034  # warning not relevant, var read by getopt(3)
GETOPT_COMPATIBLE=true
# set -x
# https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options
TEMP=$(getopt -o hnvV --longoptions help,verbose,dry-run,version \
              -n "$PNAME" -- "$@")
# shellcheck disable=SC2181 # It's too long to put in  an if test, I feel!
if [[ $? != 0 ]] ; then echo "Terminating..." >&2 ; exit 2 ; fi

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

HAVING_ERRORS=false

if [[ $# -ne 3 ]] ; then
  echo -e >&2 "$PNAME : Wrong number of  arguments. I need:\nOne argument for \
the folder to backup,\nThe full symlink name, and:\nThe  path to the \
destination folder of the backup operation. \
\nExecute \"$PNAME -h\" for help. Terminating..." >&2
  exit 2
fi

# we do check if the source folder exists. and that it doesn't exist
# within the FB-backup tree.


dieIfNotDirectoryExist "${1}"
source_folder="$1"
dieIfSourceIsWithinFBTree "$source_folder" OneShot


# we check if the destination path exists, and within the FB-backup tree.
dieIfNotDirectoryExist "${2}"
if ! isWithinPath "${2}" "$FB"; then
  echo -e  >&2 "$PNAME : The destination folder is NOT inside\n$FB\n which it\
        must be. Terminating..."
  exit 2
else
  if [[  $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder is inside $FB.\n($2)."
  fi
fi

todays_backup_folder="$2"
# we need to check if the full symlink name is within the destination path.


if ! isWithinPath "$todays_backup_folder" "${3}" ; then
  # same whether dry-run, verbose, or not.
  echo -e >&2 "$PNAME : The full symlink name is not the correct one.\nIt is \
not the name of the root folder of the backup.\nTerminating..."
  exit 2
else
  if [[ $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The full symlink name: $3 is the same as the name \
of the root folder of the backup:\n$todays_backup_folder"
  fi
  # else .. silently moving on ...
fi
symlink_name="${3}"

# time to look for any exclude files

if hasExcludeFile OneShot "$symlink_name" ; then
 if [[  $DEBUG -eq 0 ]] ; then
   echo >&2 "$PNAME : I have an exclude file : $EXCLUDE_FILE "
   cat  >&2 "$EXCLUDE_FILE"
 fi
 exclude_options="--exclude-from=$EXCLUDE_FILE"
else
  exclude_options=
fi

if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
  verbose_options="-v -v"
else
  verbose_options="-v"
fi
exit_code=0
if [[ $DRY_RUN = true  ]] ; then

  dry_run_folder=$(mktemp -d "/tmp/OneShot.backup.sh.XXX")
  trap "HAVING_ERRORS=true;ctrl_c" INT

ctrl_c() {
  echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
  echo >&2  "$PNAME : We: rm -fr $dry_run_folder."
  rm -fr "$dry_run_folder"
}

  tar_ball_name=\
"$dry_run_folder"/"$(baseNameTimeStamped "$symlink_name" )"-backup.tar.gz
  if [[ $HAVING_ERRORS = false ]] ; then

    echo >&2 "$PNAME : sudo tar -z $verbose_options -c -f \
$tar_ball_name $exclude_options -C $source_folder . "

    if [[ -n "$exclude_options" ]] ; then
      sudo stdbuf -o0 -e0 tar -z  -c $verbose_options -f "$tar_ball_name" "$exclude_options" \
-C "$source_folder" .
    else
      sudo stdbuf -o0 -e0 tar -z  -c $verbose_options -f "$tar_ball_name" -C "$source_folder" .
    fi

    if [[ -d "$dry_run_folder" ]] ; then
        rm -fr "$dry_run_folder"
    fi
    exit_code=$?
    if [[ $exit_code -gt 1 ]] ; then
      echo >&2 "$PNAME : exit status after tar commmand = $exit_code"
      echo ">&2 $PNAME : rm -fr $dry_run_folder"
    fi
  else
    echo -e >&2 "$PNAME \
: dry_run_folder=\$(mktemp -d \"/tmp/OneShot.restore.sh.XXX\")"
    echo -e "$PNAME : sudo tar -z -c $verbose_options -c  $exclude_options -f \
$tar_ball_name  -C $source_folder . "
    echo -e >&2 "$PNAME : rm -fr $dry_run_folder"
  fi
else
# DRY_RUN == false
  tar_ball_name=\
"$todays_backup_folder"/$(baseNameTimeStamped "$symlink_name" )-backup.tar.gz

  trap "HAVING_ERRORS=true;ctrl_c" INT
ctrl_c() {
  echo >&2 trapped ctrl-c
  echo >&2 rm -f "$tar_ball_name"
  rm -f "$tar_ball_name"
}
    if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
      echo -e >&2 "$PNAME : sudo tar -z -c $verbose_options -c  $exclude_options\
        -f $tar_ball_name  -C $source_folder" .
    fi
    if [[ -n "$exclude_options" ]] ; then 
      sudo tar -z $verbose_options -c "$exclude_options" -f "$tar_ball_name" -C\
"$source_folder" .
    else
      sudo tar -z $verbose_options -c -f "$tar_ball_name" -C "$source_folder" .
    fi
    exit_code=$?

    if [[ $exit_code -gt 1 ]] ; then

      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        echo >&2 "$PNAME : exit status after tar commmand (fatal error)\
          = $exit_code"
      fi

      if [[ -f "$tar_ball_name" ]] ; then
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
          echo >&2 "$PNAME : rm -f $tar_ball_name"
        fi
        rm -f "$tar_ball_name"
      fi
    elif [[ $exit_code -eq 0 ]] ; then
      echo -e >&2 "\n($tar_ball_name)\n"
    fi
fi

exit $exit_code
