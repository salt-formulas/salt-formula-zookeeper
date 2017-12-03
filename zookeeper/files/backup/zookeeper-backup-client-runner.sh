{%- from "zookeeper/map.jinja" import backup with context -%}
#!/bin/bash
# Script to backup zookeeper schema and create snapshot of keyspaces

# Configuration
# -------------
    BACKUPDIR="{{ backup.backup_dir }}/full"
    TMPDIR="$( pwd )/${PROGNAME}.tmp${RANDOM}"
    TMPLOG="zookeeper-tmplog.log"
    ZOOKEEPERDIR="/var/lib/zookeeper/version-2/"
    KEEP={{ backup.client.full_backups_to_keep }}
    HOURSFULLBACKUPLIFE={{ backup.client.hours_before_full }} # Lifetime of the latest full backup in seconds
    LOGDIR="/var/log/backups"
    RSYNCLOG="/var/log/backups/zookeeper-rsync.log"


    if [ $HOURSFULLBACKUPLIFE -gt 24 ]; then
        FULLBACKUPLIFE=$(( 24 * 60 * 60 ))
    else
        FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
    fi

# Create backup directory.
# ------------------------

    if [ ! -d "$BACKUPDIR" ] && [ ! -e "$BACKUPDIR" ]; then
        mkdir -p "$BACKUPDIR"
    fi

    if [ ! -d "$LOGDIR" ] && [ ! -e "$LOGDIR" ]; then
        mkdir -p "$LOGDIR"
    fi

    # Create temporary working directory.  Yes, deliberately avoiding mktemp
    if [ ! -d "$TMPDIR" ] && [ ! -e "$TMPDIR" ]; then
        mkdir -p "$TMPDIR"
    else
        printf "Error creating temporary directory $TMPDIR"
        exit 1
    fi


# Backup and create tar archive
# ------------------------------

    TIMESTAMP=$( date +"%Y%m%d%H%M%S" )

    echo stat | nc localhost 2181 | grep leader > "$TMPDIR/$TMPLOG"
    RC=$?

    mkdir -p "$BACKUPDIR/$TIMESTAMP"

    if [ $RC -gt 0 ] && [ ! -s "$TMPDIR/$TMPLOG" ]; then
        printf "Not a zookeper leader. This script does backup just on zookeper leader.\n"
        [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
        exit 0
    else
        # Include the timestamp in the filename
        FILENAME="$BACKUPDIR/$TIMESTAMP/zookeeper-$TIMESTAMP.tar.gz"

        tar -zcvf $FILENAME -P $ZOOKEEPERDIR > /dev/null 2>&1
        RC=$?

        if [ $RC -gt 0 ]; then
            printf "Error generating tar archive.\n"
            [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
            exit 1
        else
            printf "Successfully created a backup tar file.\n"
            [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
        fi
    fi

# rsync just the new or modified backup files
# -------------------------------------------

    {%- if backup.client.target is defined %}
    echo "Adding ssh-key of remote host to known_hosts"
    ssh-keygen -R {{ backup.client.target.host }} 2>&1 | > $RSYNCLOG
    ssh-keyscan {{ backup.client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $RSYNCLOG
    echo "Rsyncing files to remote host"
    /usr/bin/rsync -rhtPv --rsync-path=rsync --progress $BACKUPDIR/* -e ssh zookeeper@{{ backup.client.target.host }}:$BACKUPDIR >> $RSYNCLOG

    if [ -s $RSYNCLOG ] && ! grep -q "rsync error: " $RSYNCLOG; then
            echo "Rsync to remote host completed OK"
    else
            echo "Rsync to remote host FAILED"
            exit 1
    fi

    {%- endif %}

# Cleanup
# ---------
    echo "Cleanup. Keeping only $KEEP full backups"
    AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
    find $BACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$BACKUPDIR/{} \; -execdir rm -rf $BACKUPDIR/{} \;

# Fin.
