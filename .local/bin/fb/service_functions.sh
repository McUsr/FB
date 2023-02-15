#!/bin/bash

# All services script have the following global variables:



err_report() {
  echo "$PNAME : Error on line $1"
  echo "$PNAME : Please report this issue at\
    'https://github.com/McUsr/FB/issues'"
}


trap 'err_report $LINENO' ERR

# notifyErr()
# PARAMETERS: prog/funcstr errstring.
# Sends an error notification and  a journal entry .
# USAGE: notifyErr "error message " |  journalThis 5 FolderBackup
notifyErr() {
    if [[ $# -ne 2 ]] ; then
      echo -e >/dev/tty "${0##*/}/${FUNCNAME[0]} : I really need two arguments.\
  \nTerminating..."
      exit 5
    fi
  notify-send "${1} ${2}\nTerminating... "
  echo -e "${1}} ${2}\nTerminating... " 
}

# TODO: Descriptin.
fatal_err() {
  if [[ $# -le 2 ]] ; then
    if [ -t 1 ] ; then
      echo -e "${0##*/}/${FUNCNAME[0]}  I need at least three parameters:\
        the variable ERROR_MESSAGE MODUS BACKUP-SCHEME\nTerminating... " 1>&2
    else
      echo -e "${0##*/}/${FUNCNAME[0]}  I need at least three parameters:\
        the variable ERROR_MESSAGE MODUS BACKUP-SCHEME\nTerminating... "\
        | systemd-cat -t FolderBackup -p crit
    fi
    exit 5
  fi
  if [[ $# -eq 3 ]] ; then
    local err_msg="${1}"
    local modus="${2}"
    local scheme="${3}"

    if [[ "$modus" == "SERVICE" ]] ; then
      echo >"$PNAME : ${err_msg}\
      Terminating..."| systemd-cat -t "${scheme}" -p err
    else
      echo -e "$PNAME : ${err_msg}\
        \nTerminating..." >/dev/tty
    fi

  else
    local funcname="${1}"
    local err_msg="${2}"
    local modus="${3}"
    local scheme="${4}"

    if [[ "$modus" == "SERVICE" ]] ; then
      echo >"$PNAME/$funcname : ${err_msg}\
      Terminating..."| systemd-cat -t "${scheme}" -p err
    else
      echo -e "$PNAME/$funcname ${err_msg}\
        \nTerminating..." >/dev/tty
    fi
  fi
}


# dieIfSourceIsWithinFBTree()
# PARAMETERS: path1: curent schem
# GLOBALS: FB, MODE, VERBOSE
# This will end the same way,if DRYRUN, so not considering.

dieIfSourceIsWithinFBTree() {

  if [[ $# -ne 2 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need two  arguments: \
A backup source folder to check If is within \$FB\n\n
And the current scheme\nTerminates" >&2 ;
    exit 5
  fi
  if isWithinPath "${1}" "$FB" ; then

    if [[ $MODE == "SERVICE"  ]] ; then
      notifyErr "$PNAME/${FUNCNAME[0]}" " : The target of the backup is not \
allowed to be inside  $FB." |  journalThis 5 "${2}" -p crit
      exit 255
    else
      echo -e "$PNAME/${FUNCNAME[0]} : The target of the backup is not \
allowed to be inside \ $FB.\nTerminating..."
      exit 5
    fi
  fi
}

# dieIfNotDirectoryExist()
# dies if a fb system directory doesn't exist,
dieIfNotDirectoryExist() {
  if [[ $# -ne 1 ]] ; then
    echo -e "$PNAME/${FUNCNAME[0]} : Need  one \
argument, a directory to test if exists.\nTerminates..." >&2
    exit 5
  fi
if [[ ! -d "${1}" ]] ; then
  fatal_err "the Directory ${1} : doesn't \
exist!" "$MODE" "$CURSCHEME"
  exit 255
fi
}

# dieIfJobsFolderDontExist()
# PARAMETERS: jobsfolder, backupscheme, mode
# The jobs folder is the folder where the symlinks are stored,
# also the full-symlink-name.paused files.
dieIfJobsFolderDontExist(){
  if [[ $# -ne 3 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : I need three parameters.\
      \nTerminating..." >&2
    exit 5
  fi
  local jobsfolder="${1}" backup_scheme="${2}" MODE="${3}"

  if [[ ! -d $jobsfolder ]] ; then
      if [[ "$MODE" == "SERVICE" ]] ; then
        # TODO: use notifyErr
        notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "The folder \
$jobsfolder doesn't exist. Hopefully you are executing from the commandline \
and  misspelled $backup_scheme."
        echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: The folder $jobsfolder doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
$backup_scheme."
      else
        echo >&2 "${0##*/}/${FUNCNAME[0]}: The folder $jobsfolder doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
$backup_scheme."
      fi
      exit 255
  fi
}


# TODO: Descriptin.
# dieIfMandatoryVariableNotSet()
# dies If a variable isn't set.

# TODO: Notification?
dieIfMandatoryVariableNotSet() {
  if [[ $# -ne 3 ]] ; then
    if [ -t 1 ] ; then
      echo -e "${0##*/}/${FUNCNAME[0]}  I need three parameters:\
        the variable NAME MODUS SCHEME\nTerminating... " 1>&2
    else
      echo -e "${0##*/}/${FUNCNAME[0]}  I need three parameters:\
        the variable NAME MODUS SCHEME\nTerminating... "\
        | systemd-cat -t FolderBackup -p crit
    fi
    exit 5
  fi
  local var_name="${1}"
  local modus="${2}"
  local scheme="${3}"

  if [[ !  -v "$var_name" ]] ; then
    if [[ "$modus" == "SERVICE" ]] ; then
      echo >"$PNAME/${FUNCNAME[0]} : The variable $var_name isn't set.\
      Terminating..."| systemd-cat -t "${scheme}" -p crit
    else
      echo -e "$PNAME/${FUNCNAME[0]} : The variable $1 isn't set.\
        \nTerminating..." >/dev/tty
    fi
    exit 255
  fi
}


# isDirectory()
# just returns whether the parameter given is a
# directory, or not.

isDirectory() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
  argument\nTerminates..." >&2 ; exit 5 ; fi
  file "$1" | grep 'directory' >/dev/null
  return $?
}


# newestDirectory()
# RETURNS: then newest directory or "" if no directories were found.
# PARAMETERS: The BACKUP_CONTAINER
# dies if it the BACKUP_CONTAINER doesn't exist
# TODO: TEST!
newestDirectory() {
  if [[ $# -ne 1 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
    argument, an existing directory!\nTerminates..." >&2
    exit 5
  fi
  if [[ ! -d "${1}" ]] ; then
    # The Backup Container doesn't exist!
    if [[ "$MODE" == "SERVICE" ]] ; then
      notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "The backup-container \
${1} doesn't exist. Hopefully you are executing from the commandline \
and  misspelled ${1}."
      echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    else
      echo >&2 "${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    fi
    exit 255
  else
    newest="$(find "${1}" -type d -printf '%T@ %p\n' \
      | sort -n | tail -1 | cut -f2- -d" ")"

    if [[ "$newest" == "." ]] ; then
      echo
    else
# shellcheck disable=SC2091,2005  # will be used!
      echo "$(realpath "$newest")"
      # TODO:  test.
    fi
  fi
}


# oldestDirectory()
# RETURNS: then oldest directory or "" if no directories were found.
# PARAMETERS: The BACKUP_CONTAINER
# dies if it the BACKUP_CONTAINER doesn't exist

# TODO: TEST!
oldestDirectory() {
  if [[ $# -ne 1 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
    argument, an existing directory!\nTerminates..." >&2
    exit 5
  fi
  if [[ ! -d "${1}" ]] ; then
    # The Backup Container doesn't exist!
    if [[ "$MODE" == "SERVICE" ]] ; then
      notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "The backup-container \
${1} doesn't exist. Hopefully you are executing from the commandline \
and  misspelled ${1}."
      echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    else
      echo >&2 "${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    fi
    exit 255
  else
    oldest="$(find "${1}" -type d -printf '%T@ %p\n' \
      | sort -rn | tail -1 | cut -f2- -d" ")"

    if [[ "$oldest" == "." ]] ; then
      echo
    else
# shellcheck disable=SC2091,2005  # will be used!
      echo "$(realpath "$oldest")"
      # TODO:  test.
    fi
  fi
}


# backupDirectoryCount()
# RETURNS: the number of directories.
# PARAMETERS: The BACKUP_CONTAINER
# dies if it the BACKUP_CONTAINER doesn't exist

# TODO: TEST!
backupDirectoryCount() {
  if [[ $# -ne 1 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
    argument, an existing directory!\nTerminates..." >&2
    exit 5
  fi
  if [[ ! -d "${1}" ]] ; then
    # The Backup Container doesn't exist!
    if [[ "$MODE" == "SERVICE" ]] ; then
      notify-send "Folder Backup: ${0##*/}/${FUNCNAME[0]}" "The backup-container \
${1} doesn't exist. Hopefully you are executing from the commandline \
and  misspelled ${1}."
      echo >&4 "<0>${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    else
      echo >&2 "${0##*/}/${FUNCNAME[0]}: The backup-container ${1} doesn't \
exist. Hopefully you are executing from the commandline and misspelled \
${1}."
    fi
    exit 255
  else
# shellcheck disable=SC2091,2005  # will be used!
    echo "$(find "${1}" -type d  | wc -l )"
  fi
}


# assertBackupContainer()
# Just assert it exists before we continue.
# TODO: TEST!
assertBackupContainer() {
  if [[ $# -ne 1 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need an\
    argument, an existing directory!\nTerminates..." >&2
    exit 5
  fi
  if [[ ! -d "${1}" ]] ; then
    mkdir -p "${1}"
    if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
      if [[ "$MODE" == "SERVICE" ]] ; then
        echo >&4 "<7>${PNAME}/${FUNCNAME[0]} : ${1} didn\'t exist"
      else
# shellcheck disable=SC2086  # will be used!
        echo >$2 "${PNAME}/${FUNCNAME[0]} : ${1} didn\'t exist"
      fi
    fi
  else
    if [[ $DEBUG -eq 0 || $VERBOSE == true ]] ; then
      if [[ "$MODE" == "SERVICE" ]] ; then
        echo >&4 "<7>${PNAME}/${FUNCNAME[0]} : ${1} DID  exist"
      else
        echo >&2 "${PNAME}/${FUNCNAME[0]} : ${1} DID  exist"
      fi
    fi
  fi
}

# brokenSymlink()
# Alerts and dies if a symlink in a symlink folder is broken,
# Probably due to the fact that we have moved the directory
# somewhere else, or deleted it.
# Works in SERVICE_MODE and DEBUG_MODE.
# TODO: rename to 'dieIfBrokenSymlink` and die.

brokenSymlink() {
if [[ $# -ne 2 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need two\
  argument\nTerminates" >&2 ; exit 5 ; fi
  if [[ ! -t 1 ]] ; then
    notify-send "$3" "The symlink $1/$2 is broken! No backups are made for $2 \
before it is fixed."
   echo "The symlink $1/$2 is broken! No backups are made for $2 before it \
is fixed."  | systemd-cat -t "$3" -p crit
  else
   echo >&2 "The symlink $1/$2 is broken! No backups are made for $2 before it \
is fixed."
  fi
}


# dieIfBrokenSymlink()
# PARAMETERS: JOBS_FOLDER SYMLINK BACKUP_SCHEME
# terminates if the
dieIfBrokenSymlink() {

  if [[ $# -ne 3 ]] ; then
    echo -e "${0##*/}/${FUNCNAME[0]} : Need three arguments: \
The jobs folder,a symlink to validate, and backupscheme.\nTerminates" >&2 ;
    exit 5
  fi
  if ! isUnbrokenSymlink "${1}/{2}" ; then
    brokenSymlink "${1}" "${2}" "${3}"
    if [ ! -t 1 ] ; then
      # SERVICE MODE
      exit 255
    else
      exit 5
    fi
  fi
}
