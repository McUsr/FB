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

backup_scheme="${1}"

loc_param="${2}"

echo BackupScheme : "$backup_scheme"

jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

echo JobsFolder : "$jobs_folder"


# Does the file exist? if not, we might use the  jobs folder as a second chance

if [[ ! -r "$loc_param" ]] ; then
 candidate="$jobs_folder"/"$loc_param"
 echo "and the candidate is: $candidate"

  if [[ -r "$candidate" ]] ; then
    echo "found $candidate"
    if ! isASymlink "$candidate" ; then
      echo -e >&2 "$PNAME : $candidate isn't a symlink, unresolvable conflict.\n\
Please specify another parameter.\nTerminating"
      exit 2
    else
      echo "$candidate"
    fi
  else
      echo -e >&2 "$PNAME : $candidate doesn't exist, unresolvable conflict.\n\
Please specify another parameter.\nTerminating"
      exit 2
      # more difficult. what we intend to try, is to  figure the  real path
      # but
  fi
else
  echo "pass 2"
  #  we get the real path
  full_path="$(realpath "$loc_param")"
  # we create a symlink of it.
  if ! isASymlink "$full_path" ; then
    # we need to create its symlink
    symlinkName="$(fullPathSymlinkName "$full_path")"
    echo Da symlinkname: "$symlinkName"
    exit 1
  fi

#  its readable, which means it exists, it can be anything.




# eof preps.

# 1. Is it a symlink?
# 2. Is it in the jobs folder?
 

# if it isn't a symlink, and isn't in the jobs folder, translate!


  # There is some issues, the second parameter, we should accept all possible

  # forms of it, for maximum flexibility.

  # Check  no. 1

    # vi trenger ikke side effect nå, fordi hvis ting er som de skal, og er symlink,
    # så kan vi bare bruke den lange.!
    # vi må bare appende pause og se om denne finnes.
    probe=${loc_param/$jobs_folder/}
#    probe=${jobs_folder/$loc_param/}
    echo Probe : $probe
    if [[ "$probe" !=  "$loc_param" ]] ; then
      echo Is withn
      newprobe=${probe/\//}
      # newprobe=$(echo "$probe" | sed -n 's/^.//p' )
    echo Newprobe : $newprobe
    else
      echo Not within
    fi

fi

  # is whatever we got whithin the jobsfolder.

  # full symlink, realpath, invisible symlink.

  # so there are some reefs here: symlink, that exists, but isn't within the jobs folder.

  # we need the jobs folder to figure out what is what.


  # it can be from within the jobs-folder, and still not be a symlink?
