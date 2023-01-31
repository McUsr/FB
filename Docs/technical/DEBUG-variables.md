DEBUG-variables.md
------------------

Describes how you can debug/test your own scripts, based on
using existing scripts as blueprints.

The reason for having variables, and not just pass a long
parameters to a service, is that passing along parameters to
a service, would affect ALL jobs tha service runs, and maybe
you don't want to do that.


* In all scripts there is a DEBUG variable, that lets you
  turn on verbose output to the log file, which is accessible
	through `journalctl --user -xe `. You can even filter, by
	applying the correct "tag" (like OneShot), like so
	to filter further: `journalctl --user  -t OneShot -xe`.


* the $DEBUG variable is there, to replicate verbose when
	you are debugging/seeing how a script is running through 
	the services/governor.


* You can and maybe you should, turn on DRYRUN **explicitly**
*after* the parsing of arguments, if you would want to see
what would have been done when running the service.

  Last updated:23-01-29 15:27

