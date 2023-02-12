Terms and jargon used in the Documentation for FB
-------------------------------------------------

v0.0.4

**State:** *Unfinished*

It is what it says, a dictionary over words used, so to
minimize ambiguity and confusion.


* **backup** 
	A **backup** is the result of a backup job, a backup has
	been taken of a source folder, and put in a destination
	folder.

* **BACKUP\_CONTAINER** [*variable-name*]
The directory,inside the **fb\_folder\_structure** within a
backup-scheme/kind (f.ex: OneShot), with the same name as
the **full-symlink-name**, and it serves as a container for all
the directories that have the folders name and the date
stamp , holding the backups that were made on that given
date (See: **TODAYS\_BACKUP\_FOLDER**)

* **backup-rotation**
	When we have reached the treshold for the number of days
	with backups we have, (not necessarily on consecutive
	dates), we purge the folder with backups   from  the
	oldest date when we have made a new one. We never rotate
	backups taken with `fbsnapshot`.


* **backup-script** The script that executes the actual
	backup of a folder, the most low-level of scripts through
	the execution path.

* **backup-type** The type of backup, all types relies on
	tar, and all backups are compressed into tarballs.
	(.tar.gz). the types are:

	* Full: Which is a full backup of the folder, and in
		reality the same as a `single snapshot`.

	* Snapshot: The same as `Full`, but it is inteded to have
		more than one of them, per day, (time-intervalled)

  * Incremental: meant for both time and calendar intervals,
	  the backup type that requires the least space, but you
		have to restore all of them to reach the last one.

	* Differential: as Incremental, but  requires more space,
		it includes everything that has changed since the `base
		backup` and therefore requires more space, but less
		operations (that can go wrong)  to restore.


<!-- * bucket a folder containing different **Schemes** and
	**Kinds**, that in turn contains scripts/jobs.
--->

* **Container**. A **Container** for backups.
  The `TIME_STAMPED_BACKUP_CONTAINING_FOLDER`: the folder
	containing backups from that date onwards, depending on
	the **scheme**.

* **date-stamp** A date-stamp are used for folders, a date
	stamp is on *iso 8601* format. **Ex:** `yyyy-mm-dd`
	(See: **time-stamp**)

* **Delegate** The actual executionor of the job, whether
	the job is performed on behalf of a manager?, called by the
	governor, or by a fbsnapshot.

* **Executioner** It's the *delegate*, that performs the
	actual job, on the behalf of the **Governor**, that
	qualifies and selects what to be done, and then gets the
	**Executioner** to do it.

* **fb\_folder\_structure**
TODO:

* **Full-symlink-name** The **full-symlink-name** is a
	*transformation of the full path to the target of the
	backup* where the first slash is removed, invisibility
	averted, and the rest of the slashes are replaced with
	dashes.<br/> Ex: The **full-symlink-name** of
	"`/usr/lib/groff`" would be "`usr-lib-groff`".<br/>
	We avert invisibility, by putting a backslash (\\) in front
	of leading periods (.), and leading periods only, so that we
	end up with visible backup files, because the naming
	convention for backup files, is to start with the name of
	the source-folder.
	**See:** [Naming conventions](https://github.com/McUsr/FB/blob/main/Docs/technical/namingconventions.md) 

* **job**  A **job** in the context of FB is the scheme for
	a backup of a folder, and  any services and
	`backup-scripts` to execute the backup job, excluding the
	resulting backup, which is referred to as the backup. 

	A **job** has a status, it can be **active** or
	**paused**.

* **JOBS_FOLDER** [*var-name*]
	
* **KIND** (Backup kind.) Denotes if it is a `OneShot` or a
	`Periodical` backup kind.

* **Modes** The scripts that runs from services, all
	supports two modes, "SERVICE_MODE" when they are running
	from a service, and "DEBUG_MODE" when they are run from
	the command line, in a state of beeing customized, tested,
	or debugged.

* **snapshot** This word has two different meanings. 
  I use it for a full backup at a given point in time, as to
	mean a *snapshot of the state of the folder* at that time.
	In the **tar manual** they talk about *snapshot-files* in
	the context of having a file for an incremental or
	differntial backup, that have recorded what was saved in
	the backup. (After the first level-0 backup was taken.)

* **SCHEME** What kind of backup scheme that is in use for
	the `Periodical` backupis. The **SCHEME** determines what
	kind of *time-period* is used, and the *type* of the
	backup.  Valid choices are: 

  
	* HourlySnapshot -- Not every hour, every two hours, or what
you set the interval to, should you wish, but  more than
one snapshot (full backup), (tarball) per day.

	* HourlyDifferential -- one full backup, then differentials
		during the day.

	* HourlyIncremental -- one full backup then incrementals
		during the day.

	* DailyFull -- One Tarball per day.

	* WeeklyFull -- one full backup (tarball) on mondays?

 	* WeeklyDifferential -- one full backup (tarball) on
		 the first mondays Then a differential backup throughout the
		up coming  weeks.

	* WeeklyIncremental -- one full backup (tarball) on
		the first monday? Then a incremental backup through the 
		upcoming weeks.

	* MontlySnapshot --one full backup (tarball) on the first
		of the month.

	* MonthlyDifferential one full backup (tarball) on the
		first of the month? Then a differential backup through
		the upcoming  months

	* MontlyIncremental one full backup (tarball) on the first
		of the month? Then an incremental backup throug the
		upcoming months.

* **Tarball** A **Tarball** is a gzipped `tar-file`
	resulting from using the `z` option in tar command,
	producing a `.tar.gz` file, that needs decompression
	during restore.

* **Time-period**

  * Daily, things that happens daily, are `time-intervalled`
		backups.

	* Weekly a `calendar-intervalled` backup.

	* Monthly a `calendar-intervalled` backup.
	
* **Time-stamp** A **time-stamp** has the time of day
embedded, in additon to just the **date-stamp**.
Ex: `yyyy-mm-ddThh:mm`.  (See: **date-stamp**)

* **TODAYS\_BACKUP\_FOLDER** [*variable-name*]
Is the folder that contains the backups for a given date,
whether they consists of a single timestamped file, or
several. **TODAYS\_BACKUP\_FOLDER** by itself, is named by the
basename of the folder it is to backup, and the  datestamp.
 **TODAYS\_BACKUP\_FOLDER** resides within
**TODAYS\_BACKUP\_FOLDER**. (See:**BACKUP_CONTAINER**)


Last updated:23-02-10 12:21

