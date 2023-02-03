Systems overview implementation level
--------------------------------------

The motivation behind this, is to be able to reuse as much
code as possible in order to have to correct spelling
mistakes everywhere.

There are two paths of routines here, user triggered and
service triggered.

We can part the  routines for getting a backup job done into
three tiers of classes of  routines

### The tiers of routines 


### Executive class:

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





  Last updated:23-02-03 11:20

