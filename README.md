README for FB v.2
-----------------

Revised to conform with actual naming conventions.

## Installation:

The project is nowhere near installation.
If you still want to pull the project to look at the code at
your own discretion, I strongly recommend that you `pull`
the project into your own folder, because otherwise, it will
copy files into `~/.local/share/fbjobs`, `~/.local/bin/fb`,
`~/.`, and `~/Docs`, and last but not least `~/.config/systemd/user`

Sometime soon, documents concerning system-alignement, and
installation will be added. (23-01-25).

**FB -- Folder Backup** is a dedicated back up system for
backing up individual folders in Linux containers on
ChromeOs, either as one-shot backups run in the foreground,
or as periodical backups run in the background at specified
time and calendar intervals. There is just one simple
command to restore the backups `fbrestore`, a command to
easily install "boiler-plate" backups `fbinstall`, a command
`fbctl` that easily lets you control your periodical backup
jobs, and install customized backup jobs. A command that
lets you inspect the system journal, filtered on log
messages from your backup jobs, `fbjournal`

Technically; the system consists of user commands,
backup and restore scripts, several well defined folder
systems, and daemons running in the user space of systemd on
demand, in order for you to be able to make backups, restore
them, and install periodic backup jobs as easily as
possibly.

It is possible to use the system on several machines
towards, each set up with their own backup repository on the
same GoogleDrive.

You need to *align* your machine configuration, and install
binary dependencies for the system to work fully, as per
now.

### Folder Backup for Linux Containers on ChromeOs

* It uses GoogleDrive as a backup medium for easy access,
	and security.

* Easy to install periodic backups of a folder. No writing
	of scripts involved if the basics suits your neeeds.

* It is easy to make use of an `exclude-file`, if exclusion
	of a certain folder(s) or files is all you need of
	customization.

* No starting and stopping of services, the system takes
	care of everything.
	
* Easy to restore backups, one script restores all!

* Automatic per-scheme rotation of backups.

* Supports Daily, Weekly and Monthly backup intervals.

* Full/Snapshot, Incremental and Differential schemes. 

* Time-machine (tm) functionality, can be adopted:
  A folder can be backed up under different schemes to
	ensure that you can go back months in time, should you so
	wish..

* All Periodic and Oneshot backups on one drive, under the
	same folder, makes it easy to get an overview over your
	backups.

* Periodic backups will only be done when needed. When there
	are something new since last backup to processs.

* Periodic backups will be performed later if your machine
	was off.

* It is easy to get an overview of which backups under which
	scheme.

* It is highly customizable, to suit your individual needs,
	should the basic assumptions and configurations not suit
	you. 

* The basic backups are in tarball format (gzipped tar file) to preserve space.

## Example Usage

The examples are made to illustrate, how little you need
accomplish starting/stopping and restoring of period
backups, once you have installed the system.

### Instigate Periodic backup of a folder example

The system is intended to be as simple as possible, all it
should take is to write `fbinstall DailyIncremental
<folder-name>`

Then a backup should be taken immediately, and every two
hours henceforth, an incremental backup will be made, if
there is something that has changed within the folder.  The
symlink to the folder will be created in the "job"
(`~/.local/share/fbjobs/DailyIncremental`) folder, if there
weren't any other links in that folder, then the service
will be started.

'fbctl --install --scheme=DailyIncremental <folder-name>
--now' would accomplish the same as above.  Without the
`--now`, the backup job will be started according to its
timer. It is also possible to install jobs in a `--paused`
state to allow for configuring, before `--start`ing it,
maybe together with `--dryrun` and `--verbose` to check how
it performs.

### Stopping Periodic backup of a folder

To stop the folder from being taken backup of you should be
able to write `fbctl stop DailyIncremental <folder-name>`
The symbolic link to the folder will be removed from the
"job" folder, and if that was the last link in it, then the
service will be shut down, freeing up some processing time.


### Restore Example:

Say you had a mishap and want to restore a file from the
folder:

You have moved inside:

`/mnt/GoogleDrive/.../FB/Periodic/DailyIncremental/full-path-to-the-folder/`

You did that by `cd $FB/Periodic/DailyIncremental` (bash
tab-completion is your friend), then you cd'd to
`full-path-to-the-folder`.

There you enter: `fbrestore folder-name2-023-01-10` because
that was the last date a backup of that folder has been taken. (You
discovered the accident fairly immediately.)

A restore of the folder will then be placed in
`/tmp/full-path-to-the-folder/folder-name-2023-01-10T14:00`.

Then you can inspect the file from the last backup, and copy
it back into the original folder, if it indeed was that
instance of the file you wanted to restore.[1] 

This way, so that if you should want to restore several
backups for comparative purposes, you will have them under
the same "root".

### What if the file weren't there?

This was an incremental backup after all, and you didn't
find the file in the last incremental backup, so now you
enter the folder `/mnt/GoogleDrive/.../FB/Periodic/DailyIncremental/full-path-to-the-folder/folder-name-2023-01-10`;

There you find: three different incremental backups.

`folder-name-2023-01-10T10:00:00.tar.gz`
`folder-name-2023-01-10T10:00:00.snar`
`folder-name-2023-01-10T12:00:00.tar.gz`
`folder-name-2023-01-10T12:00:00.snar`
`folder-name-2023-01-10T14:00:00.tar.gz`
`folder-name-2023-01-10T14:00:00.snar`

At this point, you know that the backup picked when omitting
any time info, was the last one, so here you specify:

`fbrestore folder-name-2023-01-10T12:00:00.tar.gz`

Now, when you look into `/mnt/GoogleDrive/.../FB/Periodic/DailyIncremental/full-path-to-the folder/`

You'll see two folders:
`folder-name-2023-01-10T12:00`.
`folder-name-2023-01-10T14:00`.

You enter `folder-name-2023-01-10T12:00` and find the file
you were looking for.


### Conclusion

It is designed to be as easy as possible to use out of the
box, and be flexible enough, to support backups no matter
what your preference for backups are, as long as it involves
folders and not whole disks. I use Linux Container Backup
for that. (weekly.)

[1]
By all means, at least if the backup was a SnapShot, then
you could have drilled down to the backup file in `Filer`
too, doubleclicked it, copied the file in question, and
pasted it into a suitable folder in your Linux Container.
