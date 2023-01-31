Install Notes
--------------------------------------------------

THIS DOCUMENT IS A WORK IN PROGRESS, AND ARE NOT FINISHED
OR IN ANY SENSE USABLE OR TESTED AT THE MOMENT,

THIS IS JUST A DRAFT, DO NOT TRY TO DO WHAT IS DESCRIBED
HERE!

## Installation

* System alignement

	You need to align your system before you can install the
	software.


* Installation of fboneshot and fbrestore commandline
	utilities.



### System alignement


#### Installation of utilities if you don't already have them:

You need to install the utilities below in order to use this:
If you have any of those installed, please see to that you
have the latest versions. I am on chromeos ver. 109 in the
moment of writing, I believe I have had all the utilities
installed since 107, before that, I don't guarrantee
for anything.

* ping so we can check for a working internet connection.
  `sudo apt install/upgrade iputils-ping`


* lib-notify: desktop notifications.
  `sudo apt install/upgrade  libnotify-bin`


* tar, I'd still install it, so we are on the same page.
	`sudo apt install/upgrade tar`

#### Reworking your login process by adopting, editing your bash profile.


It's the core element of alignement and involves some
manual labour. Most of the reason for this, is to get
desktop notifications in ChromeOs, but it won't drastically
change your current bash configuration.


The main part is to create/edit  a .bash\_profile, which you'll
then be sourcing your bashrc from, so, all your previous
configurations will be retained.


There is a "blue-print" inside the *home-folder* of the
repo. copy that over to your $HOME directory, or yank in the
contents into your own .bash_profile.

1.) The first thing you should do after that, is to open
`Filer` in ChromeOs, create a folder without any spaces in
its name, and share that folder with Linux.

2.) Enter the command line/shell prompt  and cd to
/mnt/GoggleDrive/MyDrive/<your-folder-name>

3.) Assign the variable FB to the full path name of that
folder, so that the line reads:

    export FB= /mnt/GoggleDrive/MyDrive/your-folder-name

4.) Close down your Linux container and restart it.


5.) Try to: `echo $FB` from the commandline/shellprompt.

If the path to the root-folder for your folder backups now
are echoed back at you, then congratulations!

We are done with the system alignement!

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



### Installation of system services and scripts

TODO.

  Last updated:23-01-31 16:28

