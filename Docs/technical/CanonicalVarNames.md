~/wrk/BackupProject/technical/CanonicalVarNames.md
--------------------------------------------------

The purpose of this document is to list all the global variables we
have canonical nanmes for as they are permeating all the
scripts of the folder backup system.


The variables comes under several different categories.

* System variables.
This is variables that we use from the system context.


* variables that is about the runtime.



* Variables that governs output.


##  System Variables

Mostly gives the paths to directories we need, and as such
readonly, from the scripts, after they are set. Set by the
user, or can be.

#### XDG\_BIN\_HOME
XDG\_BIN\_HOME: `~/.local/bin`, or whatever you set it to.

#### XDG\_DATA\_HOME
XDG\_DATA\_HOME: `~/.local/share` or whatever you set it to.

#### XDG\_CONFIG_HOME
XDG\_CONFIG_HOME: `~/.config`

#### FB
FB: The backup tree, mounted from the Google Drive,
which contains backups of Peridical, and One\Shotkinds 

#### FB\_SCHEMES\_BIN



## RUNTIME VARIABLES

#### PNAME:
PNAME: the script/program name, R/O.

#### CURSCHEME:
Curent Scheme, deduced from PNAME, when the Current schem
haven't been read in yet, or for error messages. By the way
"Folder Backup" is the top of the hierarchy scheme-name wise.

#### BACKUP\_SCHEME
BACKUP\_SCHEME: The different backup schemes Folder Backup
supports.


#### RUNTIME\_MODE:
RUNTIME\_MODE: can only have  two values: **SERVICE**
and **CONSOLE**, it is used to tell us whether we are
running as a service, or from the console. This controls
where output will be sent. R/O.

#### DRY\_RUN:
DRY\_RUN:  Governs whether the script should really do, or
just be verbose about the actions that would have gone down.


### Paths mostly derived from system variables.

#### SCHEME\_BIN\_FOLDER
Not fully implemented: only used in shared_functions.sh/manager(): Iti
denotes the folder for delegate scripts for the current backup
scheme in question. Mostly used for local variables.


#### SCHEME\_CONTAINER

The folder for the backup\_scheme, the parent of the
BACKUP\_CONTAINER, not, and not in use.


#### BACKUP\_CONTAINER
BACKUP\_CONTAINER: The container for all the backups of a
folder, named by a construed symlink name.

### Variables used as parameters runtime

#### DELEGATE\_SCRIPT
DELEGATE\_SCRIPT: is set from the manager to be used in the
`governor.sh` and `fbrestore`. It gives the correct name of
the script to use, on the basis of which dropin folder have
been used.

#### SYMLINK\_NAME
SYMLINK\_NAME: The symlink name of the current folder for
backup, it is the full pathname of the folder with  any
leading dots in the folders in the path escaped with `\` and
`/` are replaced with `-`.


#### KIND:
KIND: Whether the backup is of Periodical or OneShot kind. 

### Runtime variables governing the output


#### DEBUG
DEBUG : Intented to be used for sending output to the
console, or through a notification, depending on
RUNTIME\_MODE.

#### QUIET
QUIET : turns off success notification in delegates

#### TERSE\_OUTPUT
TERSE\_OUTPUT : turns on quiet for the delegate, and writes out
a terse summary, from the governor.

#### VERBOSE
VERBOSE: Mostly concerns how the output of the  tar backup
or restore commands is to b presented.


#### DAYS\_TO\_KEEP\_BACKUPS:
DAYS\_TO\_KEEP\_BACKUPS

#### ARCHIVE\_OUTPUT:
ARCHIVE\_OUTPUT: is dependent of DRY\_RUN, and decides
whether we shall send ARCHIVE\_OUTPUT during the DRY\_RUN,
or not.


#### SILENT:
SILENT: Controls whether to send success message
when verbose = false, upon completed backup. It is governed
by TERSE\_OUTPUT,  which  turns SILENT on, when set.

#### ERR_IGNORE:
ERR_IGNORE: controls if the ERR trap shall emit an error
message.

( fra governor.sh, kan kanskje brukes. )
  Last updated:23-02-23 15:41

