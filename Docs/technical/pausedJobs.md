The concepts behind paused jobs
-------------------------------

The concept for paused job, is that instead of uninstalling
a job, and install it again, you can just pause it, for
whatever reason you wish, the two obvious ones beeing that
you are about to either install, or edit your dropin script.

The intent behind the concept is that pause be short, while
you are amending things to your liking. More like for maybe
a day or two at max. Otherwise, we remove the job.

If there is a file with the same name as a symlink in the
BackupScheme's jobs folder, then that is the token for that
backup job  to be paused for  that moment being.

### Subcommands that inflicts upon the paused state:

The only command so far that changes the pause state of
a backup-job is `fbctl`, by the subcommands:

* `start`

`start` will remove a paused file and let the governor pick
up the job the next time it runs. The service isn't shut
down, as long as there are paused jobs there.
(This is only one item of `start`s` job description.)

* `stop`

`stop` will remove a `symlink.paused` in addition to the
**symlink** itself, when it removes a job for good.

* `pause`

`pause` will create a paused file if one already isn't in
place.


* `activate` does the same as `start`, but none of the rest.

* `run` will do the same as `start`, only instaneously.
	(Like start .. ... --now ), (run through the governor).


The subcommands `status`  and `job-stat` reads off the paused
state.



  Last updated:23-03-10 22:08

