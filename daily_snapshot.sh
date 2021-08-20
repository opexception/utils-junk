#!/bin/bash
###############################################################################
#                                   Purpose                                   #
# Intended to be called by cron, this script will create daily full backups   #
# of specified directories on remote targets.                                 #
# A companion script will provide weekly backups every monday using the       #
# newest daily backup (previous sunday) created by this script.               #
# Suggested Cron entry follows:                                               #
# NOTE:(make sure weekly backup runs first on mandays!)                       #
# Run job at 11:59pm everyday, send errors only to root@localhost             #
# 59 23 * * *  root /usr/local/bin/daily_snapshot.sh \                        #
#	>/root/logs/snapshot_weekly`date +"%Y-(%m)%b-%d_%H:%M"`.log               #
#                                                                             #
#-----------------------------------------------------------------------------#
#             Machine (backup server) specific setup and context:             #
# OS and related partitions reside on /dev/sda                                #
# Scratch space is /dev/sdb1 and is mounted on /scratch.                      #
# This is a 250GB filesystem                                                  #
# Backup space is /dev/sdc1 and is mounted on /root/snapshot.                 #
# Future improvement is software RAID5 /dev/md0 mounted on /root/snapshot.    #
# mount /root/snapshot read-only upon boot, remount read-write as necessary   #
# to keep the backup filesystem as readonly as possible.                      #
# Mount NFS volumes on demand to keep unnecessary access to data minimal.     #
# NOTE: Mounting remote NFS volumes can be eliminated by running an rsync     #
#       server, and pulling data over ssh instead. This is more secure, and   #
#       efficient, at the expense of being more intusive to the backup client #
#       machines, as software needs to be installed/configured for this       #
#       approach to work. The current solution takes advantage of existing    #
#       NFS shares for access to data, therefore no configuration is          #
#       necessary on client machines.                                         #
#                                                                             #
#-----------------------------------------------------------------------------#
#                       Items needing improvement:                            #
#                                                                             #
# FIXME: efficiency can be improved by running as a rsync server,             #
#        rather than pulling via NFS                                          #
# FIXME: Create function oriented version of this script for ease of mgmnt    #
# FIXME: Implement .ini file to define back up source and destinations        #
###############################################################################

###############################################################################
#                                  Section 1:                                 #
# Prepare environment. Define commands absolutely, leave no ambiguity.        #
###############################################################################

# Prevent accidental use of $PATH
unset PATH

# Define commands used by this script
ID=/usr/bin/id;
ECHO=/bin/echo;
MOUNT=/bin/mount;
UMOUNT=/bin/umount;
RM=/bin/rm;
MV=/bin/mv;
CP=/bin/cp;
TOUCH=/bin/touch;
RSYNC=/usr/bin/rsync;
DATE=/bin/date;
EXPR=/usr/bin/expr;
LOGGER=/usr/bin/logger;
LOGFILE=/root/logs/snapshot_daily_`$DATE +"%Y-(%m)%b-%d_%H:%M"`.log;
# Define backup source and destination file locations
# Backup spindle
SNAPSHOT_DEV=/dev/sdc1;
# Backup spindle mount point
SNAPSHOT_DIR=/root/snapshot;
# Root mount point for NFS, CIFS shares to be backed up
BKUPSRC_DIR=/root/bkupsrc;
# Excludes are not yet implemented
#EXCLUDES=<path to excludes file>;
# Define secure credentials file for windows backups
# HMCCO domain credentials (caroot)
HMCCOCRED=/root/snapshot/hmcco.credentials;

# NOTE: List here, for reference only, active machines and directories that
#       are getting backed up.
#	[Machine] ruby [Directories] /raid/data, /raid/lib, /raid/Lapp, /raid/home

# Section 1 END


###############################################################################
#                                  Section 2:                                 #
# Initialize environment for backup proceedure                                #
###############################################################################
# Create a start time to compare job time to complete
TimerStart="$($DATE +%s)"
TimerStart=$TimerStart
$ECHO "Backup `date +"%b-%d_%H:%M"`: Starting job" >> $LOGFILE  

# Check if running as root
if (( `$ID -u` != 0 ));
    then
        {
        $ECHO "Backup `date +"%b-%d_%H:%M"`: Sorry, must be root." >> $LOGFILE;
        exit;
        }
fi

$LOGGER Snapshot_Backup: Daily backup operation initializing
$ECHO "Backup `date +"%b-%d_%H:%M"`: Daily backup operation initializing" >> $LOGFILE

# Remount $SNAPSHOT_DEV as read-write
$ECHO "Backup `date +"%b-%d_%H:%M"`: Mounting backup device read/write" >> $LOGFILE
$MOUNT -vo remount,rw $SNAPSHOT_DEV $SNAPSHOT_DIR >> $LOGFILE;
if (( $? ));
    then
        {
        $ECHO "Backup `date +"%b-%d_%H:%M"`: Could not remount $SNAPSHOT_DIR readwrite" >> $LOGFILE;
        exit;
        }
fi;

$LOGGER Snapshot_Backup: Mount $SNAPSHOT_DIR read/write successful
$ECHO "Backup `date +"%b-%d_%H:%M"`: Mount $SNAPSHOT_DIR read/write successful" >> $LOGFILE

# Mount all intended backup sources via NFS as read-only
# Ruby
$LOGGER Snapshot_Backup: Mounting Ruby:/raid read only
$ECHO "Backup `date +"%b-%d_%H:%M"`: Mounting Ruby:/raid read only" >> $LOGFILE
$MOUNT -o ro 192.168.16.73:/raid $BKUPSRC_DIR/ruby >> $LOGFILE
$LOGGER Snapshot_Backup: Mount Ruby:/raid read only successful

# Section 2 END


###############################################################################
#                                  Section 3:                                 #
# Rotate existing backups, and purge expired                                  #
###############################################################################

# Oldest backup is now expired. Delete it.
# Ruby
$LOGGER Snapshot_Backup: Purging old daily backup
$ECHO "Backup `date +"%b-%d_%H:%M"`: Purging expired backups" >> $LOGFILE
if [ -d $SNAPSHOT_DIR/ruby/7DaysAgo ] ;
    then $RM -rf $SNAPSHOT_DIR/ruby/7DaysAgo >> $LOGFILE;
fi ;
$ECHO "Backup `date +"%b-%d_%H:%M"`: Purging expired backups complete" >> $LOGFILE
# Age all backups by one day.
# Ruby
$LOGGER Snapshot_Backup: Rolling all daily snapshots over one day
$ECHO "Backup `date +"%b-%d_%H:%M"`: Rolling daily backups" >> $LOGFILE
if [ -d $SNAPSHOT_DIR/ruby/6DaysAgo ] ;
    then $MV $SNAPSHOT_DIR/ruby/6DaysAgo $SNAPSHOT_DIR/ruby/7DaysAgo >> $LOGFILE;
fi ;
if [ -d $SNAPSHOT_DIR/ruby/5DaysAgo ] ;
    then $MV $SNAPSHOT_DIR/ruby/5DaysAgo $SNAPSHOT_DIR/ruby/6DaysAgo >> $LOGFILE;
fi ;
if [ -d $SNAPSHOT_DIR/ruby/4DaysAgo ] ;
    then $MV $SNAPSHOT_DIR/ruby/4DaysAgo $SNAPSHOT_DIR/ruby/5DaysAgo >> $LOGFILE;
fi ;
if [ -d $SNAPSHOT_DIR/ruby/3DaysAgo ] ;
    then $MV $SNAPSHOT_DIR/ruby/3DaysAgo $SNAPSHOT_DIR/ruby/4DaysAgo >> $LOGFILE;
fi ;
if [ -d $SNAPSHOT_DIR/ruby/2DaysAgo ] ;
    then $MV $SNAPSHOT_DIR/ruby/2DaysAgo $SNAPSHOT_DIR/ruby/3DaysAgo >> $LOGFILE;
fi ;
$ECHO "Backup `date +"%b-%d_%H:%M"`: Rolling daily backups complete" >> $LOGFILE
#
# Mark finish time for daily roll over
TimerStopRoll="$($DATE +%s)"
TimerStopRoll=$TimerStopRoll
# Create snapshot of Yesterdays backup - hard-link of Yesterday into 2DaysAgo
# Ruby
$LOGGER Snapshot_Backup: Rolling Yesterdays full backup into Incremental
$ECHO "Backup `date +"%b-%d_%H:%M"`: Rolling Full backup into incremental" >> $LOGFILE
if [ -d $SNAPSHOT_DIR/ruby/Yesterday ] ;
    then $CP -al $SNAPSHOT_DIR/ruby/Yesterday $SNAPSHOT_DIR/ruby/2DaysAgo >> $LOGFILE;
fi ;
$ECHO "Backup `date +"%b-%d_%H:%M"`: Rolling Full backup into incremental complete" >> $LOGFILE
# Mark Finish time for incremental transfer
TimerStopIncr="$($DATE +%s)"
TimerStopIncr=$TimerStopIncr

# Section 3 END


###############################################################################
#                                  Section 4:                                 #
# Pull current backups into latest snapshots                                  #
###############################################################################

# Create new backup of Yesterday - rsync current data into latest snapshot
$LOGGER Snapshot_Backup: Capturing latest backup
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing Latest backup" >> $LOGFILE
# Ruby
# Sync ruby:/raid/data into snapshot
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/data" >> $LOGFILE
$RSYNC -ha --delete --stats $BKUPSRC_DIR/ruby/data /$SNAPSHOT_DIR/ruby/Yesterday/ >> $LOGFILE
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/data complete" >> $LOGFILE
# Sync ruby:/raid/Lapp into snapshot
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/app" >> $LOGFILE
$RSYNC -ha --delete --stats $BKUPSRC_DIR/ruby/Lapp /$SNAPSHOT_DIR/ruby/Yesterday/ >> $LOGFILE
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/app complete" >> $LOGFILE
# Sync ruby:/raid/lib into snapshot
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/lib" >> $LOGFILE
$RSYNC -ha --delete --stats $BKUPSRC_DIR/ruby/lib /$SNAPSHOT_DIR/ruby/Yesterday/ >> $LOGFILE
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /eng/lib complete" >> $LOGFILE
# Sync ruby:/raid/home into snapshot
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /home" >> $LOGFILE
$RSYNC -ha --delete --stats $BKUPSRC_DIR/ruby/home /$SNAPSHOT_DIR/ruby/Yesterday/ >> $LOGFILE
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing /home complete" >> $LOGFILE
# Mark finish time for sync'ing latest data
TimerStopSync="$($DATE +%s)"
TimerStopSync=$TimerStopSync
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capturing Latest backup complete" >> $LOGFILE
# Section 4 END


###############################################################################
#                                  Section 5:                                 #
# Update mtime of 'Yesterday' to reflect the snapshot time                    #
###############################################################################

# Ruby
$TOUCH $SNAPSHOT_DIR/ruby/Yesterday ;
$LOGGER Snapshot_Backup: Backup Successful
$ECHO "Backup `date +"%b-%d_%H:%M"`: Backup Successful" >> $LOGFILE
# Section 5 END


###############################################################################
#                                  Section 6:                                 #
# Cleanup and protect filesystem                                              #
###############################################################################
$LOGGER Snapshot_Backup: Cleaning up
$ECHO "Backup `date +"%b-%d_%H:%M"`: Cleaning up..." >> $LOGFILE

# Remount $SNAPSHOT_DEV as read-only
$LOGGER Snapshot_Backup: Protecting filesystem
$ECHO "Backup `date +"%b-%d_%H:%M"`: Protecting filesystem" >> $LOGFILE
$MOUNT -vo remount,ro $SNAPSHOT_DEV $SNAPSHOT_DIR >> $LOGFILE;
if (( $? )) ;
    then
        {
        $ECHO "Backup `date +"%b-%d_%H:%M"`: Could not remount $SNAPSHOT_DIR readonly" >> $LOGFILE;
        exit ;
        }
fi;
$LOGGER Snapshot_Backup: Filesystem Protected
$ECHO "Backup `date +"%b-%d_%H:%M"`: Filesystem Protected" >> $LOGFILE
# Unmount NFS,CIFS volumes
# Ruby

$ECHO "Backup `date +"%b-%d_%H:%M"`: Unmounting backup sources" >> $LOGFILE
$UMOUNT -v $BKUPSRC_DIR/ruby >> $LOGFILE
if (( $? )) ;
    then
        {
        $ECHO "Backup `date +"%b-%d_%H:%M"`: Could not umount $BKUPSRC_DIR/ruby" >> $LOGFILE;
        exit ;
        }
fi;
$ECHO "Backup `date +"%b-%d_%H:%M"`: Unmounting backup sources complete" >> $LOGFILE

$LOGGER Snapshot_Backup: Operation complete
$ECHO "Backup `date +"%b-%d_%H:%M"`: Operation complete" >> $LOGFILE
TimerStopTotl="$($DATE +%s)"
elapsed_secondsRoll="$($EXPR $TimerStopRoll - $TimerStart)"
elapsed_secondsIncr="$($EXPR $TimerStopIncr - $TimerStopRoll)"
elapsed_secondsSync="$($EXPR $TimerStopSync - $TimerStopIncr)"
elapsed_secondsTotl="$($EXPR $TimerStopTotl - $TimerStart)"
$LOGGER Snapshot_Backup: Roll Daily backup took $elapsed_secondsRoll seconds
$ECHO "Backup `date +"%b-%d_%H:%M"`: Roll Daily backup took $elapsed_secondsRoll seconds" >> $LOGFILE
$LOGGER Snapshot_Backup: Increment last Backup took $elapsed_secondsIncr seconds
$ECHO "Backup `date +"%b-%d_%H:%M"`: Increment last Backup took $elapsed_secondsIncr seconds" >> $LOGFILE
$LOGGER Snapshot_Backup: Capture latest data took $elapsed_secondsSync seconds
$ECHO "Backup `date +"%b-%d_%H:%M"`: Capture latest data took $elapsed_secondsSync seconds" >> $LOGFILE
$LOGGER Snapshot_Backup: Total Procedure took $elapsed_secondsTotl seconds
$ECHO "Backup `date +"%b-%d_%H:%M"`: Total Procedure took $elapsed_secondsTotl seconds" >> $LOGFILE
$LOGGER Snapshot_Backup: Done.
$ECHO "Snapshot_Backup: Done." >> $LOGFILE

# Section 6 END

#------------------------------------------------------------------------------
# daily_snapshot.sh
# Written Aug. 23 2011, by Robert Maracle
# Updated Aug. 25 2011, by Robert Maracle Rev.1
#	  - Reorganized file structure
# Updated Sep. 9 2011, by Robert Maracle Rev. 2
#     - Added \\Quebec\HomeDir to backups
#     - Edited comments throughout
# Updated Sep. 15 2011, by Robert Maracle Rev. 3
#     - Added \\quebec\Contracts to backups
# Updated Oct. 17 2011, by Robert Maracle Rev. 4
#     - Removed Quebec from job. Quebec is backed up to tape on Dexter now.
# Updated Nov. 9 2011, by Robert Maracle Rev. 5
# Updated Nov. 10 2011, by Robert Maracle Rev. 6
#     - Added support for syslog entries. 
# 	  - Changed Crontab to write to log file in /root/logs/snapshot_*.log
#	  - Added crude timer support
# Updated Nov. 21 2011, by Robert Maracle Rev. 7
#     - Cleaned up old comented out code (Quebec entries).
#     - Checked "/ruby/home" code, not capturing data, adjusted log for debuging
#     - Fixed previously unnoticed typo in if statement. "#" removed line 128
# Updated Dec. 5 2011, by Robert Maracle Rev. 8
#     - Adjusted logging to be more verbose
#     - Adjusted timer logging
# Updated Dec. 6 2011, By Robert Maracle Rev. 9
#     - Added missing varible definition for `expr`
#     - Changed logging to be less verbose, previous log was 800+MB
#     - Added Context headers to logging
# Updated Dec. 8 2011, by Robert Maracle Rev. 10
#     - Added more logging context headers
#     - Corrected timer
#     - Added escape routine for umounting backup source
# END OF FILE

