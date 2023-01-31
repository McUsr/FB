### fbsnapshot

Takes a snapshot backup of the folder given and places it in
its designated folder under `$FB/OneShot`, named with the full path of the
folder. 

#### Syntax:

  `fbsnapshot [options] <source>`

  `-h | --help`
<br/>Show help.

  `-n | --dry-run`
<br /> Tells `fbsnapshot` to just list out what would
	take place, during regular execution.

  `-v | --verbose`
<br/>Creates extensive output of what it is doing,
	listing the archive as it is created with attributes and
	so on.

  `-V | --version`
<br/>Shows the version, of the program and the system.

  `-c |--create-exclude-file`
<br>This will let you edit an exclude file up front, and ask
	 if you are happy with it, great if there are any large
	 directories of no value to you in the backup context;
	 it might be pictures/videos or code from other vendors,
	 like libraries and packages, that won't change and
	 comes from third-parties anyway. You can have only one
	 exclude file, subsequent calls to `fbsnapshot` with the
	 `--create-exclude-file` option, will open up the existing
	 one for editing. 

#### Tl;dr

* *The exclude file for that directory stops working,  the
second you change the source folder name for the backup*


* It is a good idea to use `--create-exclude-file` and
`--dry-run` together to see that you got it right before
making the backup. The `exclude.file` will be used
automatically there after, but can be removed for now from
the correlating folder under ~/.local/bin/fb/OneShot. 


<!---
Have dryrun check for an exclude files file. and checks the ~/.local/bin/FB/OneShot folder.
Normally the DailySnapshotBackup.sh and DailySnapshotRestore.sh is executed from the
FBoneShot routine. TODO: --->

