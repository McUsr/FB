About fbrestore
--------------------------------------

**TL;DR**:

The least you need to specify, is a path to the
backup from $FB outwards and including the a foldername with
a time stamp.

If you want to restore directly into a folder, without
restoring into a subfolder, then you need to apply the
`--force` option and specify the destination folder.

## fbrestore

How do we do it  when we restore?  -We enter use
`fbrestore`, `fbrestore` restores backups whatever the
method (*command/backgroundprocess*),kind (*OneShot/Periodic*)
and scheme (*Full/Snapshot/Incremental/Differential*) used in
the FB system, but are meant to only work within that
system. At least we need to specify a source for our backup,
that backup can be a timestamped folder, then `fbrestore`
will restore the latest archive (tarball) within that
folder, or we can specify a specific file within that
folder, which will then be used.

We don't have to specify a destination folder, if we don't,
then a folder will be created for us beneath `/tmp`, having
the advantage that it will be automatically deleted during
the next boot, should we forget.

Normally, the backup will always be put in a folder with the
same name as the stem of the backup file, but this can be
overriden by the `--force` option, should we wish to place
the backup directly into the folder, and not into a folder,
inside that folder. The backups are made so
that the folder originaly backed up, is above the toplevel
of the backup.

Ex. If I backup up `$HOME`, then the archive will contain all
the files inside the `$HOME` folder, but not the `$HOME` folder
by itself.

I think it is great to have the files placed in a folder
signifying where they come from, for the times, where you
really must look to find the version of the file you are
looking for.


  Last updated:23-01-26 01:23

