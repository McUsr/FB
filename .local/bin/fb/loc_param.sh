#         !/bin/bash

source ~/.local/bin/fb/shared_functions.sh

err() {
  if [[ $# -ne 2 ]] ; then 
    echo -e >&2 "$PNAME/${FUNCNAME[0]} : I need two parameters!\nTerminating"
  else
    echo -e >&2 "$PNAME/${FUNCNAME[$1]} : $2\nTerminating"
  fi
}

nrargs() {
  if [[ $# -ne 3 ]] ; then
    err 1 "I really need 3 arguments!"
    return 1
  elif [[ $1 -ne $2 ]] ; then 
    err 2  "$3"
    return 1
  fi
  return 0
}
# symlinkInJobsFolder()
# We figure out if whatever is passed as the location represents a symlink
# in the current jobs folder.
# PARAMETERS: backupscheme, location_parameter
#
# ALGORITHM:
# we check if the given parameter exists
#
#   if it doesn't:
#     does it exist within the job folder?
#       return it, or give error message
#   if it does
#     we get the full path
#     not a symlink?
#       we convert to symlinkname
#       does it exist within jobfolder?
#         return it, or give error message
#     it was a symlink:
#       does it exist within jobsfolder?
#         return it, or give error message
#
# RETURNS: A valid symlink, with full path, if any.

# Does the file exist? if not, we might use the  jobs folder as a second chance
symlinkInJobsFolder() {

LDBG=1
  if ! nrargs 3 $#  "I need three arguments!" ; then
    exit 2
  fi

  backup_scheme="${1}"
  loc_param="${2}"
  jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

  echo >&2 BackupScheme : "$backup_scheme"
  echo >&2 JobsFolder : "$jobs_folder"

  if [[ ! -r "$loc_param" ]] ; then
    echo >&2 "$loc_param" : not found.
   candidate="$jobs_folder"/"$loc_param"
   echo >&2 "and the candidate is: $candidate"

    if [[ ! -r "$candidate" ]] ; then
        err 1 "$candidate doesn't exist, unresolvable conflict.\n\
  Please specify another parameter."
        exit 2
    else
      echo >&2 "found $candidate"
      if ! isASymlink "$candidate" ; then
        err 1 "$candidate isn't a symlink, unresolvable conflict.\n\
  Please specify another parameter."
        exit 2
      else
        echo "$candidate"
      fi
    fi
  else
    if [[ $LDBG -eq 0 ]] ; then echo >&2 " the parameter existed" ; fi

    #  we get the real path
    full_path="$(realpath "$loc_param")"
    # we create a symlink of it.
    if ! isASymlink "$full_path" ; then
      # we need to create its symlink
      symlinkName="$(fullPathSymlinkName "$full_path")"
      if [[ $LDBG -eq 0 ]] ; then echo >&2 "Da symlinkname: $symlinkName" ; fi
      candidate="$jobs_folder"/"$symlinkName"
      if [[ ! -r "$candidate" ]] ; then
        err 1 "$loc_param  isn't a backup job!"
        exit 2
      else
        echo "$candidate"
      fi
    else
      candidate="$full_path"
      probe=${candidate/$jobs_folder/}
      if [[ $LDBG -eq 0 ]] ; then echo >&2 Probe : $probe ; fi
      if [[ "$probe" !=  "$candidate" ]] ; then
        # its within, and a valid symlink
        echo $candidate
      else
        err 1 "the symlink given is not the correct one for the path given"
        exit 2
      fi
    fi
  fi
}
