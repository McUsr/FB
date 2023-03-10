#!/bin/bash

source ~/.local/bin/fb/shared_functions.sh

# symlinkInJobsFolder()
# We figure out if whatever is passed as the location represents a symlink
# in the current jobs folder.
# PARAMETERS: backupscheme location parameter:
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

  if [[ $# -ne 2   ]] ; then
    echo -e >&2 "I need two parameters!\nTerminating..."
    exit 2
  fi

  backup_scheme="${1}"
  loc_param="${2}"
  jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

  echo BackupScheme : "$backup_scheme"
  echo JobsFolder : "$jobs_folder"

  if [[ ! -r "$loc_param" ]] ; then
    echo "$loc_param" : not found.
   candidate="$jobs_folder"/"$loc_param"
   echo "and the candidate is: $candidate"

    if [[ ! -r "$candidate" ]] ; then
        echo -e >&2 "$PNAME : $candidate doesn't exist, unresolvable conflict.\n\
  Please specify another parameter.\nTerminating"
        exit 2
    else
      echo "found $candidate"
      if ! isASymlink "$candidate" ; then
        echo -e >&2 "$PNAME : $candidate isn't a symlink, unresolvable conflict.\n\
  Please specify another parameter.\nTerminating"
        exit 2
      else
        echo "$candidate"
      fi
    fi
  else
    echo >&2 " the parameter existed"

    #  we get the real path
    full_path="$(realpath "$loc_param")"
    # we create a symlink of it.
    if ! isASymlink "$full_path" ; then
      # we need to create its symlink
      symlinkName="$(fullPathSymlinkName "$full_path")"
      echo >&2 "Da symlinkname: $symlinkName"
      candidate="$jobs_folder"/"$symlinkName"
      if [[ ! -r "$candidate" ]] ; then
        echo >&2 "$loc_param  isn't a backup job"
        exit 2
      else
        echo "$candidate"
      fi
    else
      candidate="$full_path"
      probe=${candidate/$jobs_folder/}
      echo >&2 Probe : $probe
      if [[ "$probe" !=  "$candidate" ]] ; then
        # its within, and a valid symlink
        echo $candidate
      else
        echo >&2 "the symlink given is not the correct one for the path given"
      fi
    fi
  fi
}
symlinkInJobsFolder $*
