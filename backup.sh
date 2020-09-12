#!/bin/bash

set -eu

# Variables needed by borg
export BORG_REPO='ssh://user@host/path/to/backup/repo'
export BORG_PASSPHRASE=$(cat "$HOME/.borg-passphrase")
export BORG_REMOTE_PATH=/bin/borg
export BORG_RSH='ssh -oBatchMode=yes'

# Variables for the script itself
BORG_EXEC=/usr/sbin/borg
LOGPATH=$HOME/Desktop/logs/borg
LOGFILE=borg_`date +"%Y-%m-%d"`.log
OLDLOGFILE=dailybackup_`date -d"60 days ago" +"%Y-%m-%d"`.log

####
## Functions
####

errorcheck()
{ 
  if [ "${1}" -ne "0" ]; then
    echo "Returned ${1} : ${2}"
    writelog "ERROR! Exiting! Returned ${1} : ${2}"
    exit $1
  fi
}

writelog()
{ 
  echo `date +"%Y-%m-%d %H:%M:%S"` ": ${1}" >> $LOGPATH/$LOGFILE
}

####
## Script Body
####

writelog "Beginning Backup"

writelog "Cleaning up old log files"
# If the old local log file exists, delete it.
if [ -e $LOGPATH/$OLDLOGFILE ]; then
  rm $LOGPATH/$OLDLOGFILE
  errorcheck $? "Deleting $LOGPATH/$OLDLOGFILE"
  writelog "Deleted $LOGPATH/$OLDLOGFILE"
fi
writelog "Old log file cleanup complete"

# Initialize the backup; not needed for routine work.
# $BORG_EXEC init --encryption=repokey-blake2

writelog "Beginning borg create"
# Do the backup.
#  Add /var/www back in for production usage.
$BORG_EXEC					\
	create 					\
        --verbose                               \
	--stats					\
	--list					\
	--exclude '/home/*/.cache/*'    	\
	::{hostname}-{now:%Y-%m-%dT%H:%M:%S}	\
	/home/$USER 			        \
	>> $LOGPATH/$LOGFILE 2>&1

errorcheck $? "Running borg create"

writelog "Completed borg create"

writelog "Beginning borg prune"

# Clean up the old backups.
$BORG_EXEC					\
	prune					\
	--stats					\
	--list					\
	--keep-daily=7				\
	--keep-weekly=4				\
	--keep-monthly=1			\
	>> $LOGPATH/$LOGFILE 2>&1

errorcheck $? "Running borg prune"

writelog "Completed borg prune"

writelog "Backup Complete"
