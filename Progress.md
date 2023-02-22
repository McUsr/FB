Progress
=======

23-02-22 

The first services/background processes `HourlySnapshot` are
complete, as are the commandline utilities `fbsnapshot` and
`fbrestore`. A lot remains on the command line utility
`fbctl`, which like `systemctl` for `systemd` administers
starts and stopping of jobs, where `systemctl` would start
and stop processes. And a lot remains with regards to
documentation, so far dealing most with configuration, as it
has been written while I coded/designed, and not so much
about usage. So, this release too, is mostly for specially
interested people, and not so much for end users, but I have
have high hopes to get there in the foreseeable future.


23-01-10 Design complete.
23-01-31 Due to messy commit history, I am starting all
over, the `fboneshot` and `fbrestore` routines, which are
the command line tools for making spontaneous backups into
the FB/OneShot directory of a Google Drive are now finished.

I am contining with the work on the governor, it's scripts,
the Documentation,  and the services now in order to finish
this off, into a great tool for making both periodic and
spontanoeus folder backups in ChromeOs.

23-02-01 Finished off the making  of `fbsnapshot` and
`fbrestore` as  standalone installment before the parts
concerning period backups by background processes are
finished and tested, 
