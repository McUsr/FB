~/wrk/BackupProject/technical/DelegateSkeleton.md
-------------------------------------------------

### Tasks

The delegate:

* Gets a symlink and the backup scheme from the Governor to
process.

* Sets up the job by asserting that we have everything we
need.

* Checks if we need to make the backup.

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

TODO:

rename everywhere to source


...

todays backup folder"

Den måten vi bruker nå, er ikke okay, hvis vi ikke SKAL ha
en backup på en bestemt dato. fordi: kanskje unoedvendig, og
TVINGER frem en rotasjon.

burde egentlig LETE IGJENNOM DOKUMENTASJON.

made or not, is a condition we will use for figuring out if
we're going to perform a backup rotation.


! alt som går til console bruker setbuf




--------------------------------------
  Last updated:23-02-21 22:54
