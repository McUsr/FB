~/wrk/BackupProject/technical/Governor.md
-----------------------------------------

### Tasks

The governor validates the job, checks if the job is paused, and if it is,
then it skips it,  with a notice to journal-ctl.

The governor figures out which script to run for the job, if
there are customized alternatives for that job.

### Modus operandi

Like services, the governor operates in either a "SERVICE"
mode, or a "DEBUG_MODE", when initiated from the command
line.

### Incoming parameters

This is highly mode dependent when it comes to the governor,
during normal runs, in "SERVICE" mode, it only takes one
parameter, the backup-scheme, which is passed from the
systemd service.

in "DEBUG_MODE" the situation is highly different!

it depend on what you want to debug/test.




### How the governor validates the backup-scheme

We check if a folder with the name submitted as
backup-scheme exsists under $XDG_BIN_HOME/fb.
If it does, it is valid, if no, then it is not.


## Where do the governor finds its jobs

$XDG_DATA_HOME/fbjobs. And if there is a file with the same
name as a full-symlink-name, ending in pause. I.e
`full-symlink-name.pause` then we know that we will bypass
that file, and if there is something like that, then there
is no stopping of the daemon.


This document should contain more specific technical detail.


<!--- This is where the spec of the governor eventually ends up as
I have sifted through what I have already written.

And some of it may even be sent over to the executioner.
 --->

Today's ephiphany is that we use just one snaphsot file for
incremental backups, and that we escape '{}' in find
commands.

The rest of the epihiphany is that we  need to check if
there is something to back up, before we check if we need to
create a new folder.

-where to create a new folder? Governor or Executioner?

The Governor checks if there is something to back up.

The Executioner  should check if we need to make a new
folder.

The Executioner controls whether we are making the base
backup, or the next incremental/differntial backup.
-(One snapshot file for the incremental.)


Parameter passing, which parameters do we need?

DailyIncremental 'symlink-name'
yields Container name togther with $FB and Scheme ($0)

    $FB/$0/$1

    last part of the symlink is the folder name.
		
		date +"%Y-%m-%d" # gives the date.
		
    echo home-mcusr-server-homepage | sed -n 's:^.*[-]::p'

		curFolName=$(date +"%Y-%m-%d"-$(echo $1 | sed -n 's:^.*[-]::p'))




  Last updated:23-02-08 19:35

