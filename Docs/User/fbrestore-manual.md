### fbrestore

fbrestore v0.0.2 only restores backups made with
`fbsnapshot`.

`fbrestore [options] <source>  <destination-folder|(optional)>`

fbrestore is the one shop stop command for restoring
backups, regardless of the schemes used for backups made
with the FB system.

it takes two parameters, `<target>` and `<destination>`,
`<destination>` is optional.

If no `<destination>` is specified, a suitable directory will be
made for you inside the  `/tmp` folder. This ensure that any restored
files will be removed with all the other temp-files after
the next reboot of your machine.

If you want to, you *can* restore right into the folder
which was the source of the backup, but you will be asked
to confirm if that is what you really want to do, because
that is irreversable. And per now, the restore operation
will hard-handedly effectively overwrite whatever what was
there before the restore in a worst-case scenario.

If you find you still want to do this, replacing every file
that was changed after a certain date, or similiar, then you
can resort to operate tar by yourself from the commandline,
to get the proper granularity you want, for now at least.

#### Syntax:

`fbrestore [options] <source>  <destination-folder|(optional)>`

`<destination-folder>` (Optional), the restored backup will
be put in a suitable folder under the /tmp directory if
amiss, ditto if a folder in your user-domain is given, but
will protest if trying to restore into the original folder
if it is a systems folder. To do that, you **must** use the
`--force` option.

##### Options 

`-h | --help` shows a short help.

`-o | --dest-dir`, specifies that the next parameter is the
destination folder. Not mandatory anymore.

`-v | --verbose` tells `fbrestore` to be verbose with
regards to details.

`-n | --dry-run` tells `fbrestore` to just list out what would
have been done during normal execution. It will even list
out all the files that would have been restored from the
backup.

`-F | --force` tells `fbrestore` to restore back into the
original folder, even if the user and you, aren't the same,
or if you really want to dump the contents directly into
that folder, without creating the folders that separates
this backup from any other backups.

`-V | --version ` shows the version.


See "fbrestore-About.md"
