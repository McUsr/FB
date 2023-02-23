#!/bin/bash
# shellcheck disable=SC2089
VERSION="\"v0.0.4\""
curscheme="HourlySnapShot"

err_report() {
  echo >&2 "$PNAME : Error on line $1"
  echo >&2 "$PNAME : Please report this issue at \
    'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR

VERBOSE=false
DEBUG=1
DRY_RUN=false

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
DRY_RUN=false
VERBOSE=false
FORCE=false
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

if [[ $THROUGH_SHELLCHECK -ne 0  ]] ; then
  dieIfCantSourceShellLibrary "$fbBinDir"/../shared_functions.sh
else
# shellcheck source=shared_functions.sh
  source "$fbBinDir"/../shared_functions.sh
fi


dieIfNotOkBashVersion
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
    -n | --dry-run ) DRY_RUN=true; shift ;;
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
  dest_test="${2/$FB/}"
  if [[ "$dest_test" != "$2" ]] ; then
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
  if [[ $DRY_RUN = false ]] ; then
    echo -e >&2 "$PNAME : The destination folder $2 does not exist.\
\nTerminating..."
    exit 2
  else
    HAVING_ERRORS=true
    echo -e >&2 "$PNAME : The destination folder $2 does not exist."
  fi
fi

dest_folder="$2"
#  Does the backup at least seem to exist?
if [[ -r "$1" ]] ; then
  if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The backup source (candidate) exists!"
  fi
  dest_test="${1/$FB/}"
  if [[  "$dest_test" = "$1" ]] ; then
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

  TAR_PROBE="${1/.tar.gz/}"
  if [[ "$TAR_PROBE" = "$1" ]] ; then
    if [[ $DRY_RUN = false ]] ; then
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
  if [[ $DRY_RUN = false ]] ; then
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

  BACKUP_CANDIDATE=($( find "$1" -name "*.tar.gz"))
  exit_code=$?
  if [[ $DRY_RUN = false &&  $exit_code -ne 0 ]] ; then
     exit $exit_code
  fi

  if [[ ${#BACKUP_CANDIDATE[@]} -eq 0 ]] ; then
    if [[ $DRY_RUN = false ]] ; then
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
PROBE=${dest_folder/\/tmp/}
if [[ "$PROBE" = "$dest_folder" ]] ; then
  WITHIN_TMP=false
  if [[ $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder isn't within /tmp."
  fi
  # We want to create a folder for this particular backup
  # even if it isn't inside the tmp folder.
  if [[ $FORCE = false ]] ; then
    # and we will since $FORCE is false
    dest_folder=$dest_folder/${FOLDER_STEM_NAME}

    if [[ $DRY_RUN = false ]] ; then
      if [[ ! -d "$dest_folder" ]] ; then
        if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
          echo >&2 "$PNAME : $dest_folder didn't exist: mkdir -p $dest_folder."
        fi
        mkdir -p "$dest_folder"
        MADE_FOLDER=true
      else
        # the folder we should dump into already exists.
          echo >&2 "$PNAME : $dest_folder already exist and --force isn't \
used : bailing out"
          if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
            ls -ld "$dest_folder"
          fi
          exit 2
      fi
    else
# Because we don't mess with making folder under dry-run when FORCE is false?
# NO: because we-re not really making a restore when dryrun is on,
# we do restore to a temp folder that we subsequently delete.
      if [[ ! -d "$dest_folder" ]] ; then
        echo >&2 "$PNAME : WOULD have made destination folder: mkdir -p \
$dest_folder"
       else
         echo >&2 "$PNAME : $dest_folder already exist and --force isn't \
used : bailing out"
         ls -ld "$dest_folder"
         exit 2
      fi
    fi
  else
    # FORCE=true : we will dump the  the restore where specified.
    if [[ $DRY_RUN = true ]] ; then
      # it can't happen that the folder doesn't exist, because
      # then we would have terminated when we tested for it's existence!
      echo >&2 "$PNAME : Destination folder exists : $dest_folder"
    fi
  fi
else
  # within the /tmp folder;
  if [[ $VERBOSE = true ||  $DEBUG -eq 0 ]] ;  then
    echo -e >&2 "$PNAME : The destination folder IS within /tmp."
  fi
# The folder is within /tmp, and we just make the folder
# to put the backup in.
  dest_folder="$dest_folder/${FOLDER_STEM_NAME}"
# This is the full folder name, that will contain the files of the tar backup.
  if [[ $DRY_RUN = false ]] ; then
    MADE_FOLDER=true
    if [[  -d "$dest_folder" ]] ; then
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
          ls -ld "$dest_folder"
          echo >&2 "$PNAME : $dest_folder did exist: rm -fr $dest_folder."
        fi
        mkdir -p "$dest_folder"
        if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
          echo >&2 "$PNAME : remade $dest_folder : mkdir -p $dest_folder."
        fi
    else
      mkdir -p "$dest_folder"
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ;  then
        echo >&2 "$PNAME : $dest_folder didn't exist: mkdir -p $dest_folder."
        ls -ld "$dest_folder"
      fi
    fi
  else
    echo >&2 "$PNAME : Making destination folder: mkdir -p $dest_folder."
  fi
fi


if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRY_RUN = false ]] ; then
  verbose_options="-v -v"
else
  verbose_options="-v"
fi


exit_code=0
if [[ $DRY_RUN = true ]] ; then
trap "ctrl_c" INT

ctrl_c() {
  echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
  echo >&2 "$PNAME : We: rm -fr $dry_run_folder."
  rm -fr "$dry_run_folder"
}
  if [[ $HAVING_ERRORS = false ]] ; then
    dry_run_folder=$(mktemp -d "/tmp/OneShot.restore.sh.XXX")
    sudo tar -x -z $verbose_options -f  "$BACKUP_SOURCE" -C "$dry_run_folder"
    if [[ $? -lt 130 ]] ; then
      rm -fr "$dry_run_folder"
    fi
  else
    echo -e >&2 "$PNAME : dry_run_folder=\$(mktemp -d \
\"/tmp/OneShot.restore.sh.XXX\")"
    echo -e >&2 "$PNAME : tar -x -z $verbose_options -f  \"$BACKUP_SOURCE\" \
-C $dry_run_folder"
    echo -e >&2 "$PNAME : rm -fr $dry_run_folder"
  fi

else

  trap "ctrl_c" INT

ctrl_c() {
  if [[ $VERBOSE = true || $DEBUG -eq 0  ]] ; then
    echo >&2 "$PNAME : trapped ctrl-c - interrupted tar command!"
    echo >&2 "$PNAME : We: rm -fr $dest_folder ."
  fi
  if [[ $MADE_FOLDER = true || $WITHIN_TMP = true ]] ; then
    rm -fr "$dest_folder"
  fi
}

  if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
    echo -e >&2 "$PNAME : sudo tar -x -z $verbose_options -f  $BACKUP_SOURCE \
-C $dest_folder"
  fi
  sudo tar -x -z $verbose_options -f  "$BACKUP_SOURCE" -C "$dest_folder"
  exit_code=$?
   #   | journalThis 7 OneShot

  if [[ $exit_code -gt 1 ]] ; then
      if [[ $VERBOSE = true || $DEBUG -eq 0 ]] ; then
        echo >&2 "$PNAME : exit status after tar commmand (fatal error) \
= $exit_code"
      fi

    if [[ $exit_code -ne 130 ]] ; then
      if [[ $MADE_FOLDER = true || $WITHIN_TMP = true ]] ; then
        rm -fr "$dest_folder"
      fi
    fi
  elif [[ $exit_code -eq 0 ]] ; then
      echo -e  >&2 "\n($dest_folder)\n"
      # This only looks like this here, not when the script is implicitly
      # initiated from a daemon.
  fi
fi
exit $exit_code
