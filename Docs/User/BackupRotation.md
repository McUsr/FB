How do we rotate backups?
--------------------------------------------

This is a development of the specification found in
`~/wrk/BackupProject/ingress.md` to reflect the current
reality. Nothing left in `ingress.md` concerning backup
rotation.

## Backup rotation

The general backup rotation, saves a specified number of
backups before purging the old ones.

If general backup rotation, is to keep the 14 last days
of backups, then we  delete the oldest, 15'th before we are to start
making a new backup.

So, all the oldest backups are deleted to minimize the space
used for backing up, and that is what we call backup

The idea with backup rotation is to be able to go back
in time and look at the version of a file or folder then
or restore something after accidental deletion, change, or
disk-crash.

In order to be able to go back as far as possible under this
system, and yet be able to have a fine granularity with
respect to version of files closest to the present time,
you need to have several schemes running in parallell for
that folder: daily, weekly and monthly.

## How backup rotations are performed

Rotations of backups are performed by the scripts that
performs the backup, after the backup is executed, it is
best done at the stage a new folder is made, if a new folder
needs to be made.

Taking into account, that we backup sparsely; if no files
are changed within the folder under automatic backup, there
will be written in a log message that there was no files to
be backed up, (as a notice), (TODO:) and then the operation
aborted.

With this sparse `politic` in order to preserve disk space,
we won't necessarily have date-stamped files or folders for
each and every day.
Therefore, when we say we preserve say, the last 14 days of
backups, it means the last 14 times we made a daily backup.
TODO: Think through this, as maybe TIMES is a better word,
or RESULTS.
Actually: BACKUP_SETS are best.

## Rotation of OneShot backups

There are no rotation of OneShot backups, only of periodic
backups.

(See Backup types.)

## Daily Backup schemes

Daily backups no matter the scheme, are the backups made
within a calendaric day.

For instance under a daily backup scheme, say we create a
new folder to contain todays daily backup, when the backup
is done, we see we have ended up with 15 folders, then we
remove the oldest one, by the date in its name.

The folder that candidates for deletion is checked to see
if the name of it is on the correct format, otherwise it is
skipped.

## Weekly Backup schemes

Weekly backups no matter the scheme, are the backups made
within a calendaric week.

Here the scheme is a little bit different.

At some point in time, if the machine is on within a week
(7-day period) there will be made a backup for that
calencaric week, though, your machine might stay home, while
you are on a 3-week holiday, so it is fine to skip some
weeks, and under this scheme, with weekly folders, when we
say we rotate after 4 weeks, we mean that we will delete the
oldest fifth folder after having made a new one, even if the
4th folder in reality is 7 weeks or more old.

## Monthly Backup schemes

Monthly backups no matter the scheme, are the backups made
within a calendaric Month.

As under the other schemes, there might have been months you
were absent, so the same principle apply here.

For instance: rotation after 12 months means that when a new
monthly folder are made and you end up with more than 12
folders, the oldest one will be deleted, and the that the
now 12th folder, may be the folder 14 months ago, since you
were absent, hiking, a couple of months.

## Yearly Backup Scheme

One full backup as soon as possible in the year,
there are no rotation.


## The end game  or consequences of the rotation method.

When you stop working,on a project, there won't be any new
backups, and since there have been no new backups, nothing
have rotated, so when you look at the backups, say after a
months time, watching the backups will be like seeing them,
the day after you stopped working on the project. Or it
might seem like you look at the back ups from  yesterday.



## The time-traveler  alike  scheme

The commands `fbinstall`, or `fbctl` will have a
`time-traveler` option, this will make for a lot of redundant
backups in the beginning, but sees to that with the rotation
schemes I have specified, that you will have backups for

* Each year  (1 full backup, as in DailyFull)

* Last 12 months (1 full backup as in DailyFull)

* Last 4 weeks (1 full backup as in DailyFull )

* Last 14 days with whatever scheme you use:

  * DailySnapshot (full) this is default.

  * DailyDifferential

	* DailyIncremental



--------------------------------------
  Last updated:23-03-03 22:08
