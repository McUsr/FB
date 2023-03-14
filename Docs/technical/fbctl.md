fbctl
-----

Controls periodical backups in the background of a folder in
a Penguin/Debian Container in ChromeOs, to the owner's Google disk.

### The commands fbctl does can be sorted out in two categories:

*Job control commands* that  controls single backup jobs,
and *Service commands* that controls all jobs under a single
backup scheme. Taxonomically speaking, a backup job belongs
under a backup scheme, and it is identified with a symlink
that is named by its full path. (See termasandjargon.md)

### Job Control Commands:

Are divided into:

* Commands concerning running backup jobs:

* Commands that configures backup jobs.


##  Commands concerning running backup jobs:

#### install       BACKUPSCHEME FOLDER

Installs a new job under the chosen Backup scheme.

Does what `fbinstall (alias)` does, but with one more word to
remember. If you  want the job to run immediately then be sure
to use the `--now` option, so it doesn't rest in "install"
mode" before you `start/restart` it.

entering a state of installed only works if the job/symlink
in questio  wasn't already installed. If the symlink isn't
actually created, the install stated isn't "entered".


#### start         BACKUPSCHEME FOLDER

Starts an existing existing job, presumuably in either a paused,
stopped, or installed state.


#### stop          BACKUPSCHEME FOLDER

Stops an existing job, by creating a SYMLINK.stopped file in
the scheme's jobs folder, if the job stopped was the only
running, the service is shut down.

It is effectively like the job wasn't even installed, except
that it will run immediately when started, and doesn't need
to be installed up front.


#### pause         BACKUPSCHEME FOLDER

Pauses a job temporarily for some maintenance reason,  the
service is kept alive whilst waiting for the job to be
enabled, started or activated.

Makes the job pause, by installing a "lock file", by the
name `<symlink>.pause` that makes the governor skip any
backups of the folder, until the "lock file" is removed.

#### run          BACKUPSCHEME FOLDER

Lets you run a backup-job directly, for testing reasons
with the optional `--dry-run` option, or otherwise. 

As per today the --dry-run is realistic with concern to
considering the need to backup, this behaviour needs to go,
so that the `--dry-run`, which is an experiment will work
every time.

The `run` command won't consider the current state of a
backup-job and won't change the state of the current backup
job.

it might be an idea to remove install, stop and pause files
termporarily, start the job now, and reestablish the state.

-- AS overruling the governor, might be a tad more to deal
with?



##  Commands that configures backup jobs.

##### Common for all edit commands:

The edit commands will install the a "lock" file, so the job
is skipped while you edit. It isn't removed automatically
when you are done, so you can get the time to try out your
edits with the `fbctl run ... --dry-run` option.

Use `fbctl start ...` to remove the `<symlink>.pause` file,
when you are done editing. Presumably after a --dry-run,
seems to work the way you'd like.


#### edit         BACKUPSCHEME FOLDER

Edits a local dropin, unless the  --all switch is given,
which edits the general dropin script for that folder.  The
plan b, was to use a GENERAL value for the backup scheme
parameter.


#### edit-restore BACKUPSCHEME FOLDER

Edits a local dropin restore script, unless the  --all
switch is given, which edits the general dropin restore
script for that folder.


#### edit-exclude BACKUPSCHEME FOLDER

Edits a local dropin exclude  file, that contains globs that
are to be excluded from backup.


#### job-state    BACKUPSCHEME FOLDER

Shows the status of the specified single job, and all
involved files with full path!

####  cat         BACKUPSCHEME FOLDER

Shows all involved files, including "dropins" and
"exclude-files file" for that backup. (It catenates all the
files from that path given by `job-state`.)

#### revert       BACKUPSCHEME FOLDER

Reverts any customizations to an "original" plain state,
removing any exclude files an other customizations.


<!--- renaming the "dropin.sh" folder
	to `"dropin.sh".old`.. --->

#### list-jobs    FOLDER

Lists all jobs for a folder under all backup schemes.


#### list-jobs    BACKUPSCHEME

Lists all jobs for one backup scheme.


#### list-jobs    --state=[ACTIVE/PAUSED/INSTALLED/STOPPED]

Lists all jobs with  the status supplied for all schemes.


#### list-jobs     --all

Lists all jobs with a current status for all schemes.
<!--- I think I could just as well give away a backup scheme
to see all the jobs for a backup scheme, with the status.
Maybe it is more natural for the job-state command. --->
	
<!-- TODO: forskjellige statuser på backup jobs, og hva
	 de innebaere. Beskrive. ---> 


### Service Control Commands:

#### check         BACKUPSCHEME

Checks that the unit and timer is installed, and the current status.

#### enable        BACKUPSCHEME

Enables a service. presumably in either a disabled, or stopped state.
Does a `systemctl --user daemon-reload` as well as starting in the process.

#### disable    BACKUPSCHEME

Disables a service, for editing or whatever, it stops the service in the
process.

#### configure  BACKUPSCHEME[.timer]

Configures a service, or its timer. Stops and disables the service before
editing.

it does a damon-reload before restarting again.

#### status    BACKUPSCHEME

Shows various interesting properties of the service.

#### list-backups BACKUPSCHEME | FOLDER

#### restore-backup 

<!--- TODO
(tui, requires fzf)
--->

<!-- Remnants that might be useful

* `fbctl edit <scheme> <folder>` Creates a "dropin.sh"
	folder under the scheme, and copies the original backup
	script into it, before opening it with `$EDITOR` or
	`$VISUAL`.
	
--->
	<!--- TODO: maybe have some kind of lock mechanism, so that any
	backups are skipped while the edit is in progress..
	And, then there is the conundrum with the restore script,
	does this script require a restore script as well. 
	Then you might as well use `FBctl restart <scheme>
	<folder>` when you have created the restore script.
	--->

<!-- Remnants that might be useful
* `fbctl edit-exclude <scheme> <folder>`

   Pauses the backup-job in question, before creating an
	"ExcludeFile"  for the backup-job, opening it with `$EDITOR` or
	`$VISUAL` for you to put one `glob` pattern per line in.

	When you are done, you should try to run the the backup
	job with `--dryrun` to see if the results are as expected,
	before you `start/restart` the job again.




* `fbctl status <scheme> <folder>`

	* running,paused,stopped, non-existant (comparision by
		dest backup folder - if it ever was there )

	* Files involved, - like `fbctl cat`

	* Last log messages.


* `fbctl restart <scheme> <folder>`
  Restarts a paused job, if the job has alread been started,
	then no foul, no harm.
	

* `fbctl run <scheme> <folder> [--dry-run]`
--->

