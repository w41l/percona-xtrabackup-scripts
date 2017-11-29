# percona-xtrabackup-scripts
Mariadb/MySQL backup scripts using percona xtrabackup

# HOWTO
1. Full backup (base backup) is only needed one time. Full backup is needed to create the base database structure for the backup. You cannot restore the incremental backup if you don't have the full backup. After performing a full backup, save it somewhere safe.
2. Although full backup is only needed one time, you can have it everymonth, everyweek, every 10-days, or everyday if you think you need some close-range restore point. Perhaps you think you can remove old backup afterwards? I don't know. But I have provide timestamp-based tar-bzip2 function of full backup (base backup).
3. Incremental backup is performed based on the LAST LSN (to_lsn variable) from the last taken backup. Every incremental backup will have a different content because the starting point (LAST LSN/to_lsn) of every incremental backup is different. You must keep every incremental backup otherwise you won't be able to restore it. Like full backup, every incremental backup is also archived using tar+bzip2 with timestamp in the filename.

PLEASE READ THE LICENSE BEFORE USING MY BACKUP SCRIPTS
