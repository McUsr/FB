About the Delegates
-------------------

The actual delegate is passed control to from the governor,
when it comes to periodic backup jobs, it performs the
actual backup of a folder, and also the rotation of backups
if the threshold is reached. The delegate will read in any
exclude file from a dropin folder, if the dropin folder of
the symlink in question, and an exclude file within it
exists.

The delegates can also be run from the commandline, with
options like dryrun or verbose set, in order to see what is
backed up before it is started up as a service for instance.


The governor, finds the correct delegate for the symlink
that represents the folder that is to be backed up.

The original delegates can be copied into dropin folders,
under the backcup scheme folder , and customized. The
customization can be done in whatever way that works for the
you, but the general idea is to  let you edit the
configurable variables, as to how many days of backups  to
be saved before rotation, and adjust the output, maybe for
debug purposes, should you do more elaborate customizations. 





### Tasks

The delegate:

* Determines  RUNTIME_MODE

* Bootstraps source files before system context is
established.


* Gets a symlink and the backup scheme from the Governor to
process if in SERVICE_MODE, otherwise reads in the command
line.


* Sets up the job by asserting that we have everything we
need.

* Checks if we need to make the backup.

* Checks out if we have an exclude file.

* Prepares the destination folder if we do need to make a
backup.

* looks for any  exclude files

* sets any verbose options

* creates the  file name for the backup.

makes the backup, and, when done, it tries to rotate
backups, if it made a new folder to store backups in for
this day, during this run. (See **backup rotation**)

### RUNTIME MODES

Either services are operating in "SERVICE" mode, which is when
they are executed from a running service with the governor
as a proxy.

Or, they are beeing costumized or otherwise tested, or
debugged through the console, also maybe via the governor
In order to make that process, we say we are in another
mode, "DEBUG\_MODE". When in DEBUG\_MODE, we do parse consider
options like "--dry\_mode", and "--verbose" to make debugging
easier, we also don't forward error messages into the
journal, and we turn off notifications, (which can be
overriden in the script by a variable).

### Incoming parameters

At all times we do need two parameters, one for the
backup-scheme, and one for the  full-symlink name.


### Modes

The delegates operates in two modes, one is called service,
and is the one for running as a service in the background.

The other mode is called console, and is for when you edit,
debug, and  test your delegate from the command line.

You can switch between both those modes by setting variables in the
script so the options are on when run as a service and not
from the command line.


### Options

You can run your commandline tool with --verbose feedback, and
--dry-run, which will show you what would have taken place
during a normal run. You can also set these variables in the
Delegate script, so they take effect when run as a service.

Feel free to just add your own debug variables to fence off
your own debug code during configuration/customization.

### Global variables

#### Non configurable.

Those can be set during options, or are set through deduction
by the script.

* PNAME

* MODE

####  Configurable variables:

* DAYS\_TO\_KEEP\_BACKUPS `<number>`
* Daily_backup\_folders\_to\_keep would be a better name.
This variable governs how many days to keep backups of,
before **rotating backups** (topic in its own right).

* NO\_CHATTER `<true/false>` (As written!)

Only works in SERVICE\_MODE, turns off "success
notifications", but lets the "error notifictions" pass
through, out into ChromeOs' desktop.

* SILENCE whether, command line stuff should output to the
journal or not. -This would really be best fit in a
config file. since so many commands would use it.

23-02-10 The verdict says that we don't journal anything
from the command line tools.


TODO:
There must be a commandline option that overrides this
version, because we want a success notification to turn up
when we have used `fbinstall?`.
SOLVED:
we let fbinstall run the notification, upon success.


## Structure of  the skeleton

### asserting system/configuraton context

* system variables
* Internet connection
* mounting
* determining mode: SERVICE/DEBUG

### asserting run-time context

* determining if the command line can be correct

* Parsing of command line variables.

* validating if it was correct.

* setting global variables

### getting and validating parameters.

Options were gotten by the parsing

Do we have enough parameters?


    param1 : BACKUP_SCHEME="${1}"
    param2 : SYMLINK_NAME="\{2}"




#### Validating our current job-environment/parameters.

We check if we have enough parameters to go on,

BACKUP\_SCHEME and  FULL\_SYMLINK\_NAME

since we have chickened out and don't use CURSCHEME
unless at the beginning, when routines not sourced yet
forced our hand.

##### Qualify the jobs folder

That it exists



#####  Qualify the targets folder

that it exists, and isn't within the source tree.

todays backup folder a backup folder timestamped byt this
date.

this only works for hourly and daily schemes. it will look
like Weekly and Monthly folder for other schemes.

  Last updated:23-02-23 20:34
