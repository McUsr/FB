Naming Conventions for the folder backup system
-----------------------------------------------

v0.0.3

State: Unfinished

This document is meant to explain the various naming
conventions, used thoughout the system.

* The naming conventions for folder backups.

* The symlink-format

* The backup scheme names

* Customizability of variables, kinds  and schemes

see folder structure.

* Naming conventions used by dropin delegates/executionors.

* Naming conventions for scripts of various kinds

## Periodic backup destination folder structure

TODO:  Move this to folderOrganization

The top level of folders, are the schemes we will use for
the different backups. The idea is that within a scheme,
there will be a folder consisting of the folder-name, and
the parent directory, in that order: `folder-parent`.

within that folder that is to contain the backups, we will
have either a folder named by the source folder name and the
date, if that is most feasible, like for daily incremental
or differntial backups, where there will be many files with
different suffixes, for one day, or just a single file named
the folder and the date,, for say a daily backups.


##  The naming conventions for folder backups.

We have naming conventions, so we can sanely store and
restore backups automatically, with as little human
intervention as possible.

### The factors that govern the convention

The naming conventions, and the file/folder organization,
varies first and foremost with the frequency of the backups
per interval, be it per day, per week, or per month.

The second factor is whether there are, or can be  more than
one backup per day.

The third factor is the backup scheme, itself.

### The general things that are globally valid for all schemes

Within a **bucket** named by  a name on the
**symlink-format** a backup, folder or file, will be named
with the base folder name, and the date the backup was
taken.

### Daily, Weekly and Monthly (Full)  Backups

Since there is only on backup for a single date, all we need
is the general format deskribed above for tar-backups **a
single file**:

  **folder-name-Iso8601format date**.

	(`apache-2023-01-11`)

### Snapshots, Incremental, Differential and OneShot Backups

All those backup-schemes will dicate that a **folder** on
the **folder-name-Iso8601format date**.

The frequency of the creation of that folder depends on the
backup-interval:

#### Daily

We are describing the conventions when there are taken several
backups per day.

Within the folder for the day, made as described above,
there will be file(s) per backup, that must have a time
stamp on the 24 hour format appended to the date, in order
to differ between the dates between.

	(`apache-2023-01-11T10:00`)

#### Weekly

Here, one folder is made for a certain date, which is to
last for a week. Inside the folder, as far as tar backups
are concerned, the backups are named with
**folder-name-Iso8601format date**.

#### Monthly 

Here, one folder is made for a certain date, which is to
last for a Month. Inside the folder, as far as tar backups
are concerned, the backups are named with
**folder-name-Iso8601format date**.

## The symlink-format 

The symlink name on this format consists of the
full path of the folder, without any starting or ending
slash, and the slashes in between replaced with dashes.  

If the file or folder is invisible, by starting with a
period (.) we escape the period so the invisible folder will
be written like this: **`home-me-\.vim`** in the symbolic file
name, everything will still work as expected.

We need this, so that the base name that is extracted from
the **full-symlink-name** becomes **`\.vim`** and hence
visible in the folder. Should we later want to compare the
backup with an existing folder, we'll simply remove the
slash, and end up with **`.vim`**, which will then identify as the
source of the backup.


We use this  symlink-format, the **full-symlink-name** for
naming symlinks and folders throughout the system.

### Hypothetical example:

`/etc/share/lib/apache/` becomes `etc-share-lib-apache`.

### Why do we apply such difficult "symlink-format" names?

We use them to avoid ambiguities, when folder names are the
same, so that we have a definitively unique identifier of a
folder, until, we move folders around.
.

### Where do we apply such "symlink-format" names.

* Symlinks to folders we want to back up, that are put in the
**jobs** folder for a backup scheme
(`~/.local/share/jobs/<backup-scheme>`).

* As a **bucket** for backups within the folders
	`$FB/Periodic/<backup-scheme>` and under `$FB/OneShot/`.
	(The OneShot is a "scheme" by itself, even if it is a "kind".)

* To help name **dropin.d** folders under the
`~/.local/bin/FB/<backup-scheme>` folder, when we need to
replace the general executioner with a special one for
that folder. The Governor of the backup scheme will look for
such a `symlink-format.d` folder, and a `Backup.sh` script
inside, to replace the regular `<backup-sheme>Backup.sh`,
and the `FBrestore` will equally look for a `Restore.sh`
script inside the folder and use that to replace the
`<backup-scheme>Restore.sh` script.


## The backup scheme names permeates the whole system.

They are used for:

* Identifying  the backup schemes

* They identify the  services,the timers that makes the periodic backup jobs run.
  (They reside in `~/.config/systemd/user`

* They identify the dedicated scripts for running backup jobs, and the corresponding restore,  for each scheme.

* They identify which `jobfolder` the symlinks on the
`symlink-format` are placed. 
(this folder is named ~/.local/share/FBInstall)

* They identify which `backup container` a folder is backed
	up into.

* They are used as a  parameter , when you install
new backups with `fbinstall`.

* They are used as selectors for finding the correct script
	to run, from within `fbrestore` for instance.

* They are used as the **restore-container** under /tmp,
when no designated folder is chosen. The folder, which name follows the **symlink-format** are placed inside the **restore-container** again, and inside that folder, are folders with arbitrary restores of former backups of the folder, identify able by beeing tagged by the timestamp of the backup.


* They are also used as tags in the journal, so it is easy
to sift through logmessages for a certain backup scheme.
Though, the folder name, on the `symlink-format` can also
be used.

## Naming conventions for dropin delegates/executionors.


23-02-02 (after v0.0.2) in the process of making the
Governor have the same functionality.

We follow the last conventions we made for OneShot, the
conventions

### Deviations: 

The `fbsnapshot` doesn't have a scheme really, it has only a
kind `OneShot`, since it is a kind of OneShot task, as the
other task/job kind is `Periodic`, since there are  no array
of backup-schemes but a only a snapshot-backup of a folder,
we treat the `OneShot` kind as a scheme of it is own, to
have a homogenous structure, so, in this context, everything
holds for `OneShot`, as it holds for any periodic
`<backup-scheme>`. 

### Naming standard for the folders the delegates reside in.

The folders for the different backup-schemes  are found beneath
`$XDG_BIN_HOME/fb` or `~/.local/bin/fb `

There is one folder for each backup-scheme we support, named by
the exact same name as the correlating backup-scheme.

Inside this folder the delegates reside, and folders for
dropins/overrides, and `exclude.file` files.

#### General dropins/overrides

There is one folder for a general dropin/override for all
jobs concerning one backup-scheme, and that folder is named
`<backup-scheme>.d`. You can't have an `exclude.file` file
inside the general dropin folder.

Additionally there are local dropins they get their name of
the `full-symlink-name` of the folder, the dropin is
for. Ex: `<etc-apache2-config>.d`, in local dropin folders,
you can have `exclude.file` files, (only one for each dropin.d
folder).  

### The naming standard for the delegates.

The delegates, one for backup, and one for restore resides
within the `<backup-scheme>` folder, at the same level as
any dropin.d folders.

They are named as `<backup-scheme>.backup.sh` and
`<backup-scheme>.restore.sh`, where the casing is *exactly*
the same as the casing of the backup-scheme.

The name of an dropin-scripts/overrides in dropin folders,
whether it is a local dropin folder or the general dropin
folder must have exactly the same name.


##  Naming conventions for scripts of various kinds

Routines that are commands and meant to be used from the cli
doesn't end in `.sh`. Scripts that are intendend to be
executed/sourced by other scripts and not by people,
**ends** in `.sh`.


## Customizability of the variables, kinds, and schemes

### The FB literal name for the root of your backup repo can be changed.

You can  exchange the literal 'FB; in the `$FB` environment
variable for something else, (and only that!) ,in the
initialization, and create that folder, and share it with
Linux, on a  machine so they have separate "backup-repos",
maybe seeing, but not using the other machine's repo,
because they have different roots for their repos.

There are no hardcoded paths in the code, everything
trickles down from the $FB environment variable, so this
will work just fine.

Instead of FB you  could use 'Book1' and 'Book2' for instance.

But use this featture sparingly, because it can confuse you
when reading the docs at least, which only refers to 'FB'
and not your individual named root for your backup repo.

### The literals for the kinds are set in stone

Both 'Periodic' and 'OneShot', enumerating the two kinds of
backups are hardcoded into the scripts, and changing them will
break the scripts.

### The literals for enumerating the different backupschmes are set in stone

They are hardcoded into the scripts as kinds as described above.

  Last updated:23-02-23 18:24

