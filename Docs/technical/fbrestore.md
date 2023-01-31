Technical information concerning fbrestore
------------------------------------------

State: Unifinished, some parts into user-doc.

## About
It's syntax is so simple, since the backup scheme used, is
ingrained in the full path of the target backup file/folder
name to be used as source file for restoring a previous
backup. When the restore is done, you will be put into the
root of the actual restored folder.

call hierarchy

`fbrestore` follows the same hierarchy as Governor. and
OneShot. -It finds a suitable executioner of the restore
job, and basically sees to that the premises are right.


## Finding of the correct restore routine

Uses the same method as `fboneshot` to find the correct restore
routine, and thereby, it is possible to override, **some**
of the functionality. what can't/shouldn't be overridden, are the
conventions for the restore folder.

## About the fbrestore routine -- call conventions

* It is built with the same architecture like governor.sh,
	fboneshot and fbrestore, in order to pick up and execute
	any "dropin" scripts, or exclude-files.

## The division of responsibilities

The governor sees to that we have the starting folder made,
if it is amiss.

The governor selects the correct script to execute, should
there be several to choose from.

The convention is, that the executioner 

* remove any made folders, that it made,  due to errors,

* The fbrestore, will in turn remove any folders it made.

* The OneShot.restore  will check its parameters, even they
are passed over from fbrestore.

### Timestamping of folders we make:

* It better be the timestamp of the folder we are getting
backups from!



## Details concerning the --force switch.

The problem arises if we have decided upon a folder and want
that backup dumped in there, or if the `fbrestore` (caller)
has decided upon a folder for us to do the restore in..

-If we have several backups to choose from, then it would be
sensible to create a folder, for that backup file,
effectively identifying that backup, **if the backup is
going within the /tmp folder structure**. Otherwise if it is
not, then we might dump the backup into the folder given if
the `--force` switch is used. **Without** the `--force`
switch, **if a folder with the same name doesn't exist**
then *a new folder within the submitted destination folder
is made to contain the restored backup file*. **Otherwise,
if a folder already exist with that name then we give an
	error messsage and terminate.**

## Conclusion


If you want the backup to take place in the
folder you have specified, without any subfolder being made
to identify the backup, then you must apply the
`--force` switch.


## The breakdown of the fbrestore routine:

### check if the context is all right. 

If the context isn't all right, there isn't any point in
anything.

### parse the commandline

that options and everything is interpreted correctly.

### check that we have the one necessary argument afterwards

the backup source.

### Qualify the backup source

* Does the backup source indeed exist.

* Extract the KIND of backup we are to restore

* Extract the SCHEME used, if any.

* Extract the PATH_TO_SOURCE of the backcup.

* Extract and *validate* the TIME_STAMPED_BACKUP_CONTAINING_FOLDER
(container)

### Resolve the destination folder

### Determine the correct script to execute the restore with.

### call the executioner of the restore.

<!-- TODO: consider: "I wonder if this folder should be necessary, if we just wanted the latest?" -->



  Last updated:23-01-29 02:16

