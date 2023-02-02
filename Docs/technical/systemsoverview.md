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


### Governor class:

The service triggered routine is named `governor.sh` and serves
all periodic backups.

The user triggered routine are named `fbctl` and
`fbinstall`.

### Manager

The user triggered commands at this level are `fbrestore` and
`fbsnapshot`, since those are slightly deviating from the rest of
the naming schemes.

the managers basically takes care of finding which delegate
to run.

### the agent/delegate/executioner

The delegates are the low level workers, their job is also
to figure out if there are any exclude files involved.





  Last updated:23-02-02 23:14

