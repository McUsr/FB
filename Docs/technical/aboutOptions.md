About Options
-------------

We do have some standard options, the standard options are :

* help
* dryrun
* verbose
* Version

Other options are --create-exclude-file, --dest-dir, --force.

## Quirks.

--dry-run doesn't do anything for --create-exclude file,
create exclude file isn't part of the normal operation, so 
in that context, create exclude file doesn't consider --dryrun,
it is the operation that comes later, that is dryrun.


governor has two modes, it figures out byitself if it is in the mode REAL, or CLI
by the number of arguments. it only goes to the job folder directly, when there is one parameter 
involved, which is a backup scheme under the jobs folder.

exit
 

