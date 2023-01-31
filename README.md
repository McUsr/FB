     _____     _     _             ____             _                
    |  ___|__ | | __| | ___ _ __  | __ )  __ _  ___| | ___   _ _ __  
    | |_ / _ \| |/ _` |/ _ \ '__| |  _ \ / _` |/ __| |/ / | | | '_ \ 
    |  _| (_) | | (_| |  __/ |    | |_) | (_| | (__|   <| |_| | |_) |
    |_|  \___/|_|\__,_|\___|_|    |____/ \__,_|\___|_|\_\\__,_| .__/ 
                                                              |_|    

# README v0.0.2


**Folder Backup** is a dedicated back up system for
backing up folders from Linux containers on
ChromeOs to your GoogleDrive, so you have cloud based
backups, of what matters to you.


* The backups can either be  a spontaneously executed snapshot
of a folder, executed from the commandline,  or as *installed periodical
backups* run in the background at specified time and calendar
intervals.

* It is capable of taking backup of folders *everywhere* in
	your Linux container, and can take backups of, and restore
	invisible folders too (.dotfiles). Folders, files and
	globs to exclude items from beeing backed up  in a local
	`exclude.file` are also considered.

* It is highly customizable, to suit your individual needs,
	should the basic assumptions and configurations not suit
	you.  It is possible to customize the execution of the
	backups, on a general level for a backup scheme, or at a
	local folder level.


* There is only one command to restore any kind of backup,
	with few options.
 

### About v0.0.2

This is the beginning of the whole system, the only thing
operating here, is manual backups and restores, which are
always manual, so, there are only two manual commands,
`fbsnapshot` and `fbrestore in this version.


[Please see: "System  Configuration and Installation"](https://github.com/McUsr/FB/blob/main/Docs/User/SystemInstallation.md)
### Folder Backup of  Linux Containers on ChromeOs

* It uses GoogleDrive as a backup medium for easy access,
	and security.  You can use  the same  GoogleDrive for
	several machines.  (You'll of course need to install the
	software on every machine, and create a designated root
	for their backups.

* Easy to restore backups, one script restores all kinds.

* Easy to install periodic backups of a folder. No writing
	of scripts involved if the basics suits your neeeds,
	periodic backups are sparse in that they are only
	performed when there are something new to back up.

* Periodic backups will be performed later if your machine
	was off when the timer fired.

* All Periodic and Oneshot backups on one drive, under the
	same folder for one machine, makes it easy to get an
	overview over your backups.

* Supports Daily, Weekly and Monthly backup intervals.

* Full/Snapshot, Incremental and Differential schemes. 

* It is easy to make use of an `exclude-file`, if exclusion
	of a certain folder(s) or files is all you need of
	customization. It can be made, edited and deleted by
	command line tools.

* No manual starting and stopping of background processes,
	the system takes care of everything.
	
* Automatic per-scheme rotation of backups, configurable,
	by editing the intervals in the script for the job.


* Time-machine (tm) functionality, can be adopted:
  A folder can be backed up under different schemes to
	ensure that you can go back months in time, should you so
	wish..


* Periodic backups will only be done when needed. When there
	are something new since last backup to processs.


* Having all backups for one machine under on common root,
	makes it easy to refind backups, as you can drill down
	through the scheme, but also use a find command on the
	commandline should you have backed up  a folder using
	several backup schemes over time. 

* The basic backups are in tarball format (gzipped tar file)
	to preserve space, which has the added advantage, that at
	least snapshots of various kinds can be mounted and files
	be viewed in ChromeOs's Filer.
	

  Last updated:23-02-02 00:02
