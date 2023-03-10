The different jobstates and how to reckognize them
---------------------------------------------------

So, a job, which is run by a service can have one state at
one point in time.

### The different states of a Folder Backup job.
(A job is identified by a full symlink name, in a job folder
for a backup scheme).

* void

The job is not there, it is not installed, there are no
traces of it in the jobs folder, (*it might be removed*) but
it might have remnants in the FB/Periodical<backup-scheme>
folder if it ever was in use. This is just here for
completion.


* installed
The job has been installed, but it hasn't run yet. The first
time it is run, or about to run the accompanying `<symlink>.installed` file 
is removed. `fbctl's` `start` subcommand removes it, it also
removes the `<symlink>.paused`, or  `<symlink>.stopped` files.


* running

The job is active, it has no accompanying .stopped,
.installed, or .paused file.


* paused

The job isn't currently running, it has a `<symlink>.paused`
file.

* stopped

The job isn't running for an inderminate point in time. The
difference between stopped and paused jobs, is that the
service is shut down if there are only stopped jobs, but
still running if there are only .paused jobs.








  Last updated:23-03-10 22:26

