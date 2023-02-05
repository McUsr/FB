Systems overview implementation level
--------------------------------------

We can categorize the routines and services into system and user
interaction routines.  We start with the user routines, and
works backwards into the the system realm, ending with the
services. Finalizing it all with the install script.
The motivation behind this, is to be able to reuse as much
code as possible in order to have to correct spelling
mistakes everywhere.


There are two paths of routines here, user triggered and
service triggered.

We can part the  routines for getting a backup job done into
three tiers of classes of  routines

Contents:

* Deliverables

* Routines

* File system hierarchy

## Deliverables

* Install script

## Routines

### The tiers of routines 


### Executive class:

fbinstall is in a class by itself, since it just calls fbctl
with the correct parameters to achieve certain operations.




The service triggered routine is named `governor.sh` and serves
all periodic backups. it is triggered -- normally -- by a
service.

The user triggered routine are named `fbctl` and
`fbinstall`.

### Manager class

The user triggered commands at this level are `fbrestore` and
`fbsnapshot`, since those are slightly deviating from the rest of
the naming schemes.

the managers basically takes care of finding which delegate
to run.

### the agent/delegate class

The delegates are the low level workers, their job is also
to figure out if there are any exclude files involved.

exclude files are of no use to `fbrestore`


## Filesystem hierarcy

The structure under XDG_BIN_HOME/fb contains a flattened
structure, replicating the folder structure under the root
of the FB folder on the GoogleDrive, as far as Periodic is
removed, and OneShot is placed aside of the Periodic's
backup-scheme folders.



  Last updated:23-02-05 03:30

