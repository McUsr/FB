Thoughts about Debug Output
--------------------------------------------

Initial thoughts :22-04-18 01:18

This document/these thoughts, pertains mostly to services,
and not cli programs.

What I state here, *may* change over the course.

As for now, the thought is, that when I'm executing the fb
commands from the command line, I get the error messages
right into my face, at the console, and if I missed it the
first time, whatever it was, I can rerun the command again,
and this time redirecgt stderr and stdout to `more`, or
`less`, or `batcat` or `bat` for that matter, if you don't 
redirect to a sort of log file you can inspect after the
command has finished.

And, that way, the journal is kept clean for more important
log messages, you can't see in the console, because the jobs
runs in the background.

So, when service scripts are executed in "DEBUG_MODE", they
act like the command line commands, and sends output to the
console, and not to the journal.

The conclusion of this: 23-02-22

We keep output from command line utilities, and services
that runs in console mode to the Terminal window, and not
into any journal. The backed up files in the backup tree,
is the evidence oof successful backups.

  Last updated:23-02-23 20:29

