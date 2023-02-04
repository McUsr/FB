Configuration and Installation of Folder Backup v0.0.3
------------------------------------------------------

This version of the document goes with "v0.0.3" of Folder
Backup. The document assumes you are going configure  a
standard Linux/Debian container under ChromeOs, and that you
have an available Google Drive with some free space on it.

You should have had downloaded a copy of the Folder Backup
software before starting the alignment process.

## Initial system configuration

1.)  Installation of utilities if you don't already have them.

2.) Creating and mounting the folder backup root.

3.) Configuring  the bash initialization process. 

4.) Run the install script `fbsysinstallv0.0.2.sh`

### 1.) Installation of utilities if you don't already have them

You need to install the utilities below in order to use this:
If you have any of those installed, please see to that you
have the latest versions. I am on chromeos ver. 109 in the
moment of writing, I believe I have had all the utilities
installed since 107, before that, I don't guarrantee
for anything.

* **ping**: We need to check that we have an
	internet-connection for Gdrive.

  `sudo apt install iputils-ping`


* **tar**: Having the latest version is a good idea.
 
	`sudo apt install/upgrade tar`


### 2.) Creating and mounting the folder backup root

You need internet connection to do this. (A great keyboard
short cut for turning on/off wifi is: **ctrl-shift-cmd/alt-n**)

1.) Open `Filer` in ChromeOs, create a folder without any
spaces in its name, for instance FB, *directly under Google
Disk/ My Disk *, and share that folder with Linux, by
"right-clicking" the FB folder.

2.1) Open a Linux terminal window and move inside the mounted
folder, then issue `pwd`.

2.2.a) If the address of your folder turns out to be:
`/mnt/chromeos/GoogleDrive/MyDrive/FB`, then you are pretty
much done, and can use the boilerplate values in
`.bash_profile.` (But the final setup still needs to be tested.)

2.2.b) If you choose another name, for instance `AsusFB`
instead of `FB`, or you are using a `.bash_profile` for
initialization up front; issue the command `pwd > ~/FBpath`,
while still standing in your GoogleDrive/MyDrive/FB folder
so you get the full path that you can later paste into
your `.bash_profile` when  you configure the
initialization of bash.


### 3.) Configuring  the bash initialization process. 

It's the core element of alignment and involves some
editing. It is not set in stone, the result is what matters,
you can still roll with only making the changes to
`.bashrc`, but then you'll have to do these steps when
coming around to the next version utilizing services for 
periodic backups.

#### Set up the shell-environment for FB.

The main part is to copy/edit  a `.bash_profile`, which you'll
then be sourcing your bashrc from, so, all your previous
configurations will be retained.

a.) If you already use a `.bash_profile` for system
initialization, open it up in your favorite editor.

b.) If not, then copy the  "blue-print" from inside the
*home-folder* of the repo to your `$HOME` directory, and
open it in your favourite editor.

##### For  case a.)

a.1) 

* Add `export XDG_DATA_HOME=$HOME/.local/share`
* Add ` export XDG_BIN_HOME=$HOME/.local/bin`
* and Add `export FB=/mnt/chromeos/GoogleDrive/MyDrive/FB` or 
whatever you have used.

a.2)

* Add `$XDG_BIN_HOME/fb` to your path, so `fbrestore` and
`fbsnapshot` are accessible.

a.3)

*  Seee "special considerations for Alacritty", if you use
Alacritty.


##### For  case b.)

b.1)

*  Edit the  `export FB=/mnt/chromeos/GoogleDrive/MyDrive/FB` to  
whatever you have used, if you have used something different.

b2.)

*  Open your `.bashrc` as well, and transfer  `$PATH` you
	 have set in `.bashrc`  to `.bash_profile` and edit the 
	 path so it looks all right. you may just find a good spot
	 within your `$PATH` to insert `$XDG_BIN_HOME/fb`.

b3.)

*  Source your `.bashrc` from the `.bash_profile` by
inserting a line like: `source .bashrc` at the end of
`.bash_profile` you should also remove any shebang
(`#!/bin/bash`) from the top of your `.bashrc`.

b.4) 

* Seee "special considerations for Alacritty", if you use
Alacritty.

##### Both cases:

1.)  `exec bash`, and test your paths, and see to that `echo
 $FB` gives the expected result.

2.) Test if you can `cd $FB/`, if not, add `shopt -s
cdable_vars`, to your `.bashrc`, then `exec bash` again.


### 4.) Run the install script

1.) Download the zip file and from the right sidebar and
unzip it somewhere inside your Linux/Debian container.

2.) When in the terminal window, change directory to  folder
of your unzipped package with the Folder Backup v0.0.2
download. 

3.) Run the script `fbsysinstallv0.0.2.sh` script. It will
install `fbrestore`, `fbsnapshot` and `shared_functions.sh`
in your `$HOME/.local/bin/fb` folder, the paths within the
scripts are hardcoded for that address, so, the location is
set in stone, unless you will edit them and break upwards
compatibility.

The script will create the bare minimum of folders to run
under `$XDG_BIN_HOME/fb` and copy in helper scripts for
backup and restore: `OneShot.backup.sh` and
`OneShot.restore.sh` under `$XDG_BIN_HOME/fb/OneShot`.


The script will in the end  execute: `type -a fbrestore` and `type
-a fboneshot` afterwards, to confirm the installation.

**All Done**

### 5.) Use it!

Read the help docs: fbrestore.md and fbsnapshot.md 

Try it out by: `fbsnapshot <yourfolder>`

Then try to `fbrestore
$FB/path-to-your-folder/folder-2023-02-01`

And watch the result in your `/tmp` folder.


##### Steps for making it work flawlessly in Alacritty

There are some special considerations if you are using the
Alacritty Terminal emulator, *and have set your terminal
type to "alacritty"*, for instance to make colors work
properly in Vim, with GPU support!  In ChromeOs, we will
start up Linux from the regular `hterm app`  ,so `systemd`
will be fed with what `systemd` needs, through the
.bash_profile, but when Alacritty is configured with
`TERM=alacritty` in `.alacritty.yml` then Alacritty won't
execute a login shell, hence `.bash_profile` won't be touched,
and you, and the scripts  are blindsided at the commandline
prompt, what PATH's and environment variables are concerned.

My solution is to have, rather early in my `.bashrc` which
*is read by alacritty*, an if block: `if [ $TERM = alacritty
] ; then ` that convolutes all the environment variables I
have set in `.bash_profile`, it's a kluge, I know, but it
works.  I have left such a block in the folder with the
`.bash_profile`, that you can yank into your `.bashrc` and
adapt to your needs.


  Last updated:23-02-01 21:58

