Backup Schemes for Folder Backup
--------------------------------------

### Periodic Backup schemes.

In addtion to this, are of course any ad hoc backups you
make when you feel for it with `fbsnapshot`.

<table>
  <tr>
  <th style="text-align:left;padding:1em;">Category</th>
  <th style="text-align:left;padding:1em;">Scheme Name</th>
  <th style="text-align:left;">Description</th>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;">Daily</td>
  <td style="text-align:left;padding:1em;">HourlySnapshot</td>
  <td style="text-align:left;">A snapshot every hour of the day</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td
  style="text-align:left;padding:1em;">DailyIncremental</td>
  <td style="text-align:left;">A snapshot at the start of the day, then incremental backups every hour of the day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td
  style="text-align:left;padding:1em;">DailyDifferential</td>
  <td style="text-align:left;">A snapshot at the start of the day, then differential backups every hour of the day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td style="text-align:left;padding:1em;">DailyFull</td>
  <td style="text-align:left;">A snapshot at the start  every day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;">Weekly</td>
  <td
  style="text-align:left;padding:1em;">WeeklyIncremental</td>
  <td style="text-align:left;">A snapshot at the start of the week, then an incremental backup on the start of every day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td
  style="text-align:left;padding:1em;">WeeklyDifferential</td>
  <td style="text-align:left;">A snapshot at the start of the week, then a differential backup on the start of every day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td style="text-align:left;padding:1em;">WeeklyFull</td>
  <td style="text-align:left;">A snapshot at the start  every week.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;">Monthly</td>
  <td
  style="text-align:left;padding:1em;">MonthlyIncremental</td>
  <td style="text-align:left;">A snapshot at the start of the month, then an incremental backup at the start of every day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td
  style="text-align:left;padding:1em;">MonthlyDifferential</td>
  <td style="text-align:left;">A snapshot at the start of the month, then a differential backup at the start of every day.</td>
  </tr>
  <tr>
  <td style="text-align:left;padding:1em;"></td>
  <td style="text-align:left;padding:1em;">MonthlyFull</td>
  <td style="text-align:left;">One snapshot at the start
  of every month.</td>
  </tr>
</table>

### Daily Backup schemes

Daily backups no matter the scheme, are the backups made
within a calendaric day.

### Weekly Backup schemes

Weekly backups no matter the scheme, are the backups made
within a calendaric week.


### Monthly Backup schemes

Monthly backups no matter the scheme, are the backups made
within a calendaric Month.


### Note

A backup at the start of the day or otherwise means, at the
start of the day, if there is something there that has
changed since last backup and neccessitates a new backup,
backups will only be made if there is something new to
backup there.



  Last updated:23-03-04 05:00
