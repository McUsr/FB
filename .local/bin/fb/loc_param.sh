#!/bin/bash

source shared_functions.sh
# motivasjonen er at uansett hvordan vi spesifiserer lokasjon, så skal vi klare
# å oversette denne til det som ligger i jobsfolder for backup-scheme.
# Vi returnerer symlink, hvis vi har. ellers så returnerer vi ingen ting.
# Vi finner ikke .pause fil som er basert på  symlink her.



# Tanken bak det første forsoeket er å finne ut om er inne i.

# Andre forsøk, om er symlink eller ikke.

# symlink | inne i jobsfolder
# ---------------------------
#    x    |      x
# ---------------------------
#    x    |
# ---------------------------
#         |      x
# ---------------------------
#         |
# ---------------------------

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

backup_scheme="${1}"

loc_param="${2}"

echo BackupScheme : "$backup_scheme"

jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

echo JobsFolder : "$jobs_folder"


# Does the file exist? if not, we might use the  jobs folder as a second chance

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
#    probe=${jobs_folder/$loc_param/}
    echo >&2 Probe : $probe
    if [[ "$probe" !=  "$candidate" ]] ; then
      # its within, and a valid symlink
      echo $candidate
    else
      echo >&2 "the symlink given is not the correct one for the path given"
    fi
  fi
fi
