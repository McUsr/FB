# -- !/bin/bash

err_report() {
  echo "$PNAME : Error on line $1"
  echo "$PNAME : Please report this issue at\
    'https://github.com/McUsr/FB/issues'"
}

trap 'err_report $LINENO' ERR

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
  argument\nTerminates" >&2 ; exit 5 ; fi
  file "$1" | grep 'directory' >/dev/null
  return $?
}
