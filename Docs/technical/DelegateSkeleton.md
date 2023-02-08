~/wrk/BackupProject/technical/DelegateSkeleton.md
-------------------------------------------------

### Tasks

The delegate makes the backup, and, when done, it tries to rotate
backups, if it made a new folder to store backups in for
this day, during this run. (See **backup rotation**)

### Modus operandi

Either services are operating in "SERVICE" mode, which is when 
they are executed from a running service with the governor
as a proxy.

Or, they are beeing costumized or otherwise tested, or
debugged through the console, also maybe via the governor
In order to make that process, we say we are in another
mode, "DEBUG_MODE". When in DEBUG_MODE, we do parse consider
options like "--dry_mode", and "--verbose" to make debugging
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

You can turn on both those modes by setting variables in the
script so the options are on when run as a service and not
from the command line.


### Options

You can run your commandline tool with --verbose feedback, and 
--dry-run, which will show you what would have taken place
during a normal run.

Feel free to just add your own debug variables to fence off
your own debug code during configuration/customization.


### Configurable variables:

* DAYS_TO_KEEP_BACKUPS `<number>`
* Daily_backup_folders_to_keep would be a better name.
This variable governs how many days to keep backups of,
before **rotating backups** (topic in its own right).

* NO_CHATTER `<true/false>` (As written!)

Only works in SERVICE_MODE, turns off "success
notifications", but lets the "error notifictions" pass
through, out into ChromeOs' desktop.

TODO:
There must be a commandline option that overrides this
version, because we want a success notification to turn up
when we have used `fbinstall?`.

  Last updated:23-02-08 15:39

