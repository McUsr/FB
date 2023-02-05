### fbctl



`fbctl` is the command that controls the whole setup, the
idea is that this should be the only command you need to use
in order to manipulate, create, or edit jobs inn the system,
trying to save you as much as possible from getting your
fingers dirty when you need to configure the system.
`fbctl` uses command completion, so there is no need to
remember all those name of Backupschemes in order to get it
right. Whereas `fbinstall` is for quickly getting boiler
plate backup jobs up and running, `fbctl` is for those cases
where you need to tinker some, like with the backup rotation
interval, or want to use something different than tar, like
`gzip`,`rsync` or `rclone`. then you need to edit your
backupscript, and your restore-script, created from the
original ones, and before you start that job, you would want
to pause the backup job, if you ever started it. 

Before you are done, you would wan't to try to run the
script, and see that it does what you want, before you use
`fbctl` to start up the job again.

`fbctl` is greatly inspered by `systemd`, which is the
underlying services manager running the jobs.

#### Tasks `fbctl` can do / Syntax:

* `fbctl list-backups <scheme>|--all`

  Lists all backup-jobs for a scheme, or all backup-jobs for all
	schemes that are active/running.

* `fbctl job-state <active/running/paused>|--all`

  Lists which schemes have running backup-jobs, (and active
	daemons). or "paused backup-jobs" (daemon still running),
	Or, everything, active and paused jobs. 

* `fbctl stop <scheme> <folder>`

   Stops the backup job right away, by removing the symlink
	 from the scheme folder, and if that symlink was the last
	 one, it then stops the daemon for the backup scheme.

* `fbctl install <scheme> <folder>`

	 Does what `FBinstall` does, but with one more word to
	 remember. If you  want the job to run immediately then be sure
	 to use the `--now` option, so it doesn't rest in "pause"
	 mode" before you `start/restart` it.

* `fbctl cat <scheme> <folder>`

	 Shows all involved files, including "dropins" and
	 "exclude-files file" for that backup.

* `fbctl revert <scheme> <folder>`

	 Reverts any customizations to an "original" plain state,
	 removing any exclude files an other customizations.


	<!--- renaming the "dropin.sh" folder
	to `"dropin.sh".old`.. --->

* `fbctl edit <scheme> <folder>` Creates a "dropin.sh"
	folder under the scheme, and copies the original backup
	script into it, before opening it with `$EDITOR` or
	`$VISUAL`.
	
	<!--- TODO: maybe have some kind of lock mechanism, so that any
	backups are skipped while the edit is in progress..
	And, then there is the conundrum with the restore script,
	does this script require a restore script as well. 
	Then you might as well use `FBctl restart <scheme>
	<folder>` when you have created the restore script.
	--->

* `fbctl edit-exclude <scheme> <folder>`

   Pauses the backup-job in question, before creating an
	"ExcludeFile"  for the backup-job, opening it with `$EDITOR` or
	`$VISUAL` for you to put one `glob` pattern per line in.

	When you are done, you should try to run the the backup
	job with `--dryrun` to see if the results are as expected,
	before you `start/restart` the job again.


* `fbctl pause <scheme> <folder>`

   Makes the job pause, by installing a "lock file", that
	 makes the governor skip any backups of the folder, until
	 the "lock file" is removed. -May happen automatically
	 during `fbinstall`, `fbctl install` or `fbctl edit`,
	 after beeing queried whether the system is good to go.


	 <!--- TODO: forskjellige statuser på backup jobs, og hva
	 de innebaere. Beskrive. ---> 


* `fbctl status <scheme> <folder>`

	* running,paused,stopped, non-existant (comparision by
		dest backup folder - if it ever was there )

	* Files involved, - like `fbctl cat`

	* Last log messages.

* `fbctl restart <scheme> <folder>`
  Restarts a paused job, if the job has alread been started,
	then no foul, no harm.

* `fbctl run <scheme> <folder> [--dry-run]`

  Lets you run a backup-job directly, for testing reasons
	with the optional `--dry-run` option, or otherwise.

