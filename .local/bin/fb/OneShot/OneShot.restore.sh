#!/bin/bash
# shellcheck disable=SC2089
VERSION="\"v0.0.4\""
CURSCHEME="OneShot"

err_report() {
  echo >&2 "$PNAME : Error on line $1"
  echo >&2 "$PNAME : Please report this issue at \
    'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR

VERBOSE=false
DEBUG=1
DRYRUN=false

# dieIfCantSourceShellLibrary()
# sources the ShellLibraries
# so we can perform the rest of the tests.
dieIfCantSourceShellLibrary() {
  if [[ $# -ne 1 ]] ; then
    echo -e >&2 "$PNAME/${FUNCNAME[0]} : Need an\
    argument, an existing fb shell library file!\nTerminates..."
    exit 5
  fi
  if [[ -r "${1}" ]] ; then
    source "${1}"
  #  source "$fpth"/service_functions.sh
  else
    echo -e >&2 "$PNAME/${FUNCNAME[0]} : Can't find/source: ${1}\
      \nTerminates... "
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

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../service_functions.sh
else
# bootstrapping libraries before figuring system paths.
# shellcheck source=service_functions.sh
  source "$fbBinDir"/../service_functions.sh
fi

# Configuration variables that will be overruled by options.
DRYRUN=false
VERBOSE=false
FORCE=false
# controls whether we are going to print the backup command to the
# console/journal, (when DRYRUN=0) or if were actually going to perform.
DEBUG=0
#
# prints out debug messages to the console/journal if its on when instigated\
# systemd --user.

# asserting system/configuration context.
dieIfMandatoryVariableNotSet FB "$RUNTIME_MODE" "$CURSCHEME"
dieIfMandatoryVariableNotSet XDG_BIN_HOME "$RUNTIME_MODE" "$CURSCHEME"


dieIfNotDirectoryExist "$XDG_BIN_HOME"

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/../shared_functions.sh
fi


consoleHasInternet OneShot
consoleFBfolderIsMounted OneShot


if [[ $# -eq 0 ]] ; then
  echo -e >&2 "$PNAME : Too few arguments. At least I need a backup source to \
    restore from.\nExecute \"$PNAME -h\" for help. Terminating..."
 exit 2
fi
DEBUG=1

help() {
cat  << EOF

$PNAME:  Restores a previous folder backup, made with the fb system.

syntax:

  $PNAME [options] <source folder/file>  <destination>
  It is meant to be executed by *fbrestore* and not individually.

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
TEMP=$(getopt -o hnvFV --longoptions help,verbose,dry-run,force,version \
              -n 'OneShot.restore.sh' -- "$@")

# shellcheck disable=SC2181 # It's too long to put in  an if test, I feel!
if [[ $? != 0 ]] ; then echo "Terminating..." >&2 ; exit 2 ; fi

# Note the quotes around '$TEMP': they are essential!
eval set -- "$TEMP"
# echo TEMP : "$TEMP"

# echo NARG1 : $#

while true; do
  case "$1" in
    -h | --help )  help ; exit 0 ;;
    -n | --dry-run ) DRYRUN=true; shift ;;
    -v | --verbose ) VERBOSE=true; shift ;;
    -F | --force )  FORCE=true; shift ;;
    -V | --version ) echo "$PNAME" : "$VERSION" ; exit 0 ;;
    -- ) shift; break ;;
#    * ) break ;;
  esac
done
HAVING_ERRORS=false

if [[ $# -ne 2 ]] ; then
  echo -e "$PNAME : Wrong number of  few arguments. I need one argument for \
at least the path to a  backup source.\nand a path to a a destination folder \
for the restore operation.\nExecute \"$PNAME -h\" \
for help. Terminating..." >&2
  exit 2
fi

# Can we use the submitted destination folder?
if [[ -r "$2" ]] ; then
  DEST_TEST="${2/$FB/}"
  if [[ "$DEST_TEST" != "$2" ]] ; then
    # same whether dry-run, verbose, or not.
    echo -e >&2 "$PNAME : The destination folder are not allowed to be inside \
\$FB: $FB.\nTerminating..."
    exit 2
  elif [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder is NOT inside $FB.\n($2)."
    HAVING_ERRORS=true
  fi
elif [[ ! -d "$2" ]] ;then
  ## Error : we ignore this further down 'e
  if [[ $DRYRUN = false ]] ; then
    echo -e >&2 "$PNAME : The destination folder $2 does not exist.\
\nTerminating..."
    exit 2
  else
    HAVING_ERRORS=true
    echo -e >&2 "$PNAME : The destination folder $2 does not exist."
  fi
fi

DEST_FOLDER="$2"
#  Does the backup at least seem to exist?
if [[ -r "$1" ]] ; then
  if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The backup source (candidate) exists!"
  fi
  DEST_TEST="${1/$FB/}"
  if [[  "$DEST_TEST" = "$1" ]] ; then
      echo -e >&2 "$PNAME : The backup source to restore  are not allowed to \
be outside $FB.\nTerminating..."
      exit 2
  fi
else
    echo -e >&2 "$PNAME : The backup source \"$1\" doesn't exist!\
\nTerminating..."
    exit 2
fi

# We need to sort out which backup to restore.
BACKUP_SOURCE_TYPE=
# is it a file or a directory we got?
if [[ -f "$1" ]] ;then
  BACKUP_SOURCE_TYPE="file"
  if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The backup source is a file!"
  fi
  # TODO: check if it ends with tar.gz!
  TAR_PROBE="${1/.tar.gz/}"
  if [[ "$TAR_PROBE" = "$1" ]] ; then
    if [[ $DRYRUN = false ]] ; then
      echo -e >&2 "$PNAME : The file  specified:\n \"$1\":\n isn't a .tar.gz \
file. Terminating..."
      exit 2
    else
      HAVING_ERRORS=true
      echo -e >&2 "$PNAME : The file  specified:\n \"$1\":\n isn't a .tar.gz \
file."
    fi
  elif [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The file  specified:\n \"$1\":\n IS a .tar.gz file."
  fi
elif [[ -d "$1" ]] ;then
  BACKUP_SOURCE_TYPE=folder
  if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The backup source is a folder!"
  fi
else
  if [[ $DRYRUN = false ]] ; then
    echo -e >&2 "$PNAME : The backup source to restore:\n\t \"$1\"\nis \
neither a file, nor a folder\nTerminating..."
    exit 2
  else
    HAVING_ERRORS=true
    echo -e >&2 "$PNAME : The backup source to restore:\n\t \"$1\"\nis \
neither a file, nor a folder."
  fi
fi

BACKUP_SOURCE=
if [[ "$BACKUP_SOURCE_TYPE" = "folder" ]] ; then
# Find the newest backup by convention.
# As the design is per today, if we should just be able to
# retrieve the latest by specifying the Container, then we should probably
# find the newest folder, if the container was the latest element we found.
# if THAT is done at THAT level, the we should add on THAT folder we found to
# the destination folder we passed along, as well as on the Source for the
# backup.

  BACKUP_CANDIDATE="$( find "$1" -name "*.tar.gz")"
  EXIT_STATUS=$?
  if [[ $DRYRUN = false &&  $EXIT_STATUS -ne 0 ]] ; then
     exit $EXIT_STATUS
  fi

  if [[ ${#BACKUP_CANDIDATE[@]} -eq 0 ]] ; then
    if [[ $DRYRUN = false ]] ; then
      echo -e >&2 "$PNAME : The backup source folder to restore from:\n\t \
\"${1}\"\ndoesn't have any content.\nTerminating..."
      exit 1
    else
      HAVING_ERRORS=true
      echo -e >&2 "$PNAME : The backup source folder to restore from:\n\t \
\"${1}\"\ndoesn't have any content."
    fi
  else
    BACKUP_SOURCE="${BACKUP_CANDIDATE[0]}"
    if [[ $DEBUG -eq  0 || $VERBOSE = true  ]] ;  then
      echo -e >&2 "$PNAME : We found the latest file within the folder:\
\n$BACKUP_SOURCE"
    fi
  fi
elif [[ "$BACKUP_SOURCE_TYPE" = "file" ]] ; then
  BACKUP_SOURCE="$1"
fi


# Preparing the folder name we shall append, or not.
FOLDER_BASE_NAME="${BACKUP_SOURCE##*/}"
if [[ $VERBOSE = true  || $DEBUG -eq 0 ]] ;  then
  echo -e >&2 "$PNAME : The folder base name we will use for basis for the \
tar-dump in is:\n$FOLDER_BASE_NAME"
fi
FOLDER_STEM_NAME="$( baseNameFromBackupFile "$FOLDER_BASE_NAME")"
# FOLDER_STEM_NAME="${FOLDER_BASE_NAME%%.*}"

if [[ $VERBOSE = true  || $DEBUG -eq 0 ]] ;  then
  echo -e >&2 "$PNAME : The folder stem name we will use for storing the \
tar-dump in is:\n$FOLDER_STEM_NAME"
fi

# TWO MAIN CASES HERE:
# Either the folder exists, or it is not submitted, Then it is generated in
#the temp, but it is generated by 'fbrestore'# routine and submitted, by.
# This routine is really not intended to be executed from
# the commandline.

WITHIN_TMP=true
MADE_FOLDER=false
# Is the destination folder within /tmp?
PROBE=${DEST_FOLDER/\/tmp/}
if [[ "$PROBE" = "$DEST_FOLDER" ]] ; then
  WITHIN_TMP=false
  if [[ $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder isn't within /tmp."
  fi
  # We want to create a folder for this particular backup
  # even if it isn't inside the tmp folder.
  if [[ $FORCE = false ]] ; then
    # and we will since $FORCE is false
    DEST_FOLDER=$DEST_FOLDER/${FOLDER_STEM_NAME}

    if [[ $DRYRUN = false ]] ; then
      if [[ ! -d "$DEST_FOLDER" ]] ; then
        if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
          echo >&2 "$PNAME : $DEST_FOLDER didn't exist: mkdir -p $DEST_FOLDER."
        fi
        mkdir -p "$DEST_FOLDER"
        MADE_FOLDER=true
      else
        # the folder we should dump into already exists.
          echo >&2 "$PNAME : $DEST_FOLDER already exist and --force isn't \
used : bailing out"
          if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
            ls -ld "$DEST_FOLDER"
          fi
          exit 2
      fi
    else
# Because we don't mess with making folder under dry-run when FORCE is false?
# NO: because we-re not really making a restore when dryrun is on,
# we do restore to a temp folder that we subsequently delete.
      if [[ ! -d "$DEST_FOLDER" ]] ; then
        echo >&2 "$PNAME : WOULD have made destination folder: mkdir -p \
$DEST_FOLDER"
       else
         echo >&2 "$PNAME : $DEST_FOLDER already exist and --force isn't \
used : bailing out"
         ls -ld "$DEST_FOLDER"
         exit 2
      fi
    fi
  else
    # FORCE=true : we will dump the  the restore where specified.
    if [[ $DRYRUN = true ]] ; then
      # it can't happen that the folder doesn't exist, because
      # then we would have terminated when we tested for it's existence!
      echo >&2 "$PNAME : Destination folder exists : $DEST_FOLDER"
    fi
  fi
else
  # within the /tmp folder;
  if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder IS within /tmp."
  fi
# The folder is within /tmp, and we just make the folder
# to put the backup in.
  DEST_FOLDER="$DEST_FOLDER/${FOLDER_STEM_NAME}"
# This is the full folder name, that will contain the files of the tar backup.
  if [[ $DRYRUN = false ]] ; then
    MADE_FOLDER=true
    if [[  -d "$DEST_FOLDER" ]] ; then
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
          ls -ld "$DEST_FOLDER"
          echo >&2 "$PNAME : $DEST_FOLDER did exist: rm -fr $DEST_FOLDER."
        fi
        mkdir -p "$DEST_FOLDER"
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
          echo >&2 "$PNAME : remade $DEST_FOLDER : mkdir -p $DEST_FOLDER."
        fi
    else
      mkdir -p "$DEST_FOLDER"
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
        echo >&2 "$PNAME : $DEST_FOLDER didn't exist: mkdir -p $DEST_FOLDER."
        ls -ld "$DEST_FOLDER"
      fi
    fi
  else
    echo >&2 "$PNAME : Making destination folder: mkdir -p $DEST_FOLDER."
  fi
fi


if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = false ]] ; then
  VERBOSE_OPTIONS="-v -v"
else
  VERBOSE_OPTIONS="-v"
fi


EXIT_STATUS=0
if [[ $DRYRUN = true ]] ; then
trap "ctrl_c" INT

ctrl_c() {
  echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
  echo >&2 "$PNAME : We: rm -fr $DRY_RUN_FOLDER."
  rm -fr "$DRY_RUN_FOLDER"
}
  if [[ $HAVING_ERRORS = false ]] ; then
    DRY_RUN_FOLDER=$(mktemp -d "/tmp/OneShot.restore.sh.XXX")
    sudo tar -x -z $VERBOSE_OPTIONS -f  "$BACKUP_SOURCE" -C "$DRY_RUN_FOLDER"
    if [[ $? -lt 130 ]] ; then
      rm -fr "$DRY_RUN_FOLDER"
    fi
  else
    echo -e >&2 "$PNAME : DRY_RUN_FOLDER=\$(mktemp -d \
\"/tmp/OneShot.restore.sh.XXX\")"
    echo -e >&2 "$PNAME : tar -x -z $VERBOSE_OPTIONS -f  \"$BACKUP_SOURCE\" \
-C $DRY_RUN_FOLDER"
    echo -e >&2 "$PNAME : rm -fr $DRY_RUN_FOLDER"
  fi

else

  trap "ctrl_c" INT

ctrl_c() {
  if [[ $VERBOSE = true || $DEBUG -eq 0  ]] ; then
    echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
    echo >&2 "$PNAME : We: rm -fr $DEST_FOLDER ."
  fi
  if [[ $MADE_FOLDER = true || $WITHIN_TMP = true ]] ; then
    rm -fr "$DEST_FOLDER"
  fi
}

  if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
    echo -e >&2 "$PNAME : sudo tar -x -z $VERBOSE_OPTIONS -f  $BACKUP_SOURCE \
-C $DEST_FOLDER"
  fi
  sudo tar -x -z $VERBOSE_OPTIONS -f  "$BACKUP_SOURCE" -C "$DEST_FOLDER"
  EXIT_STATUS=$?
   #   | journalThis 7 OneShot

  if [[ $EXIT_STATUS -gt 1 ]] ; then
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        echo >&2 "$PNAME : exit status after tar commmand (fatal error) \
= $EXIT_STATUS"
      fi

    if [[ $EXIT_STATUS -ne 130 ]] ; then
      if [[ $MADE_FOLDER = true || $WITHIN_TMP = true ]] ; then
        rm -fr "$DEST_FOLDER"
      fi
    fi
  elif [[ $EXIT_STATUS -eq 0 ]] ; then
      echo -e  >&2 "\n($DEST_FOLDER)\n"
      # This only looks like this here, not when the script is implicitly
      # initiated from a daemon.
  fi
fi
exit $EXIT_STATUS
