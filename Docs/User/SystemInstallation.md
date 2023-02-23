Configuration and Installation of Folder Backup v0.0.4
------------------------------------------------------

This version of the document goes with "v0.0.4" of Folder
Backup. The document assumes you are going configure  a
standard Linux/Debian container under ChromeOs, and that you
have an available Google Drive with some free space on it.

You should have had downloaded a copy of the Folder Backup
software before starting the alignment process.

## Initial system configuration

1.)  Installation of utilities if you don't already have them.

2.) Creating and mounting the folder backup root.

3.) Configuring  the bash initialization process. 

4.) Run the install script `fbsysinstallv0.0.4.sh`

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

* **lib-notify**: desktop notifications.
  `sudo apt install/upgrade  libnotify-bin`

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


### 3.) Reworking your login process by adopting, editing your bash profile.

It's the core element of alignment and involves some
manual labour. Most of the reason for this, is to get
desktop notifications in ChromeOs, but it won't drastically
change your current bash configuration.

#### Set up the shell-environment for FB.

The main part is to create/edit  a .bash\_profile, which you'll
then be sourcing your bashrc from, so, all your previous
configurations will be retained.

There is a "blue-print" inside the *home-folder* of the repo
you have downloaded a copy of, or cloned. Copy that over to
your $HOME directory, or yank in the contents into your own
.bash_profile, and edit.

When you are done editing, restart your Linux Container.

1. See that you can echo out $FB, and that it points to
your mounted folder.

2. `cd $FB` and see that you indeed end up in root of your
	 Backup tree.

	 If this doesn't work, that `cd $FB` doesn't take you
	 anywhere,  then you may  isssue a command line command:
	 `shopt -s cdable_vars`, then try again: if that fixed it,
	 then you should add `shopt -s cdable_vars` to your
	 `.bashrc`. If that didn't work, then something is
	 probably not configured right, check the `$FB` variable.

3. Move to the folder where the install script is and
	 execute the install script from there. `installv0.0.2`

The script will create the bare minimum of folders to run
under `$XDG_BIN_HOME/fb` and copy in helper scripts for
backup and restore: `OneShot.backup.sh` and
`OneShot.restore.sh` under `$XDG_BIN_HOME/fb/OneShot`.

The script will in the end  execute: `type -a fbrestore` and `type
-a fboneshot` afterwards, to confirm the installation.

### 5.) Use it!

Read the help docs: fbrestore.md and fbsnapshot.md 

Try it out by: `fbsnapshot <yourfolder>`

Then try to `fbrestore
$FB/path-to-your-folder/folder-2023-02-01`

And watch the result in your `/tmp` folder.

**All Done**


**Tip!**

If you remove the shebang from your `.bashrc` after
having sourced it from `.bash_profile`, then there will be
spawned one shell less, but with the same functionality.

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
.profile, that you can yank into your .bashrc and adapt to
your needs.


Reference:
A full description of "Aligning your configuration" can be
found here: [`https://www.reddit.com/r/Crostini/comments/zqky47/fully_working_demo_of_backup_by_systemd_user_in/`](https://www.reddit.com/r/Crostini/comments/zqky47/fully_working_demo_of_backup_by_systemd_user_in/).

  Last updated:23-02-23 20:04

