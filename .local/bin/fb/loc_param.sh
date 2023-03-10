#!/bin/bash

# motivasjonen er at uansett hvordan vi spesifiserer lokasjon, så skal vi klare å oversette denne
# til det som ligger i jobsfolder for backup-scheme.


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



  # is whatever we got whithin the jobsfolder.

  # full symlink, realpath, invisible symlink.

  # so there are some reefs here: symlink, that exists, but isn't within the jobs folder.

  # we need the jobs folder to figure out what is what.

  jobs_folder="$XDG_DATA_HOME"/fbjobs/"$backup_scheme"

  # it can be from within the jobs-folder, and still not be a symlink?
