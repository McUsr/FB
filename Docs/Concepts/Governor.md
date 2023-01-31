Concepts concering the Governor
---------------------------------------------

## Concepts

* The governor is a dispatcher of found backup jobs in the
	folder that contains symlinks for that specific backup
	scheme. 

	The service passes onto its name, which is the name of 
	backupscheme in question.

* There is **just one governor that servers all schedules**

	It is dispatched from the different **services**, which
	are bootstrapped from the different **timers**
	
* It is a shell script called from a daemon.

* The governor is a **kernel level** routine

* It has no direct interaction with users.

* The governor is called from the *Backup services*.

* Some of its functionality is shared with the different
	user commands, with regards to consistency checks of the
	system.
	
	* Necessary folders exist

	* Internet connection available

	* Backup destination mounted


* The governor calls the "executioners" of the backup.

  The functionality below is shared with:

	* `fbrestore`

	* `fboneshot`

	* `fbinstall`

	* `fbctl`

	The call of executioners implies that it checks for an
	"dropin.sh" routines the user has configured for the
	scheme in general, by putting it into the "<scheme>.d"
	folder, or a a individual scheme for one special folder,
	by putting it into a "full-symlink-name.d" folder, in
	order to override the normal behaviour.

  Last updated:23-01-25 14:10

