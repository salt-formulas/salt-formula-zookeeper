{%- from "zookeeper/map.jinja" import backup with context -%}
#!/bin/bash
# Script to backup zookeeper schema and create snapshot of keyspaces

SKIPCLEANUP=false
while getopts "sf" opt; do
  case $opt in
    s)
      echo "Cleanup will be skipped" >&2
      SKIPCLEANUP=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Configuration
# -------------
    BACKUPDIR="{{ backup.backup_dir }}/full"
    SERVERBACKUPDIR="{{ backup.client.target.get('backup_dir', backup.backup_dir) }}/full"
    TMPDIR="$( pwd )/${PROGNAME}.tmp${RANDOM}"
    TMPLOG="zookeeper-tmplog.log"
    ZOOKEEPERDIR="/var/lib/zookeeper/version-2/"
    {%- if backup.client.backup_times is not defined %}
    HOURSFULLBACKUPLIFE={{ backup.client.hours_before_full }} # Lifetime of the latest full backup in hours
    if [ $HOURSFULLBACKUPLIFE -gt 24 ]; then
        FULLBACKUPLIFE=$(( 24 * 60 * 60 ))
    else
        FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
    fi
    {%- endif %}
    KEEP={{ backup.client.full_backups_to_keep }}
    LOGDIR="/var/log/backups"
    RSYNCLOG="/var/log/backups/zookeeper-rsync.log"




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
 
        {%- if backup.client.containers is defined %}
        {%- for container_name in backup.client.containers %}

        docker exec {{ container_name }} mkdir -p $BACKUPDIR/$TIMESTAMP
        docker exec {{ container_name }} tar -zcvf $FILENAME -P $ZOOKEEPERDIR > /dev/null 2>&1
        RC=$?

        if [ $RC -gt 0 ]; then
            printf "Error generating tar archive.\n"
            [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
            exit 1
        else
            printf "Successfully created a backup tar file.\n"
            [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
        fi
        docker cp {{ container_name }}:$FILENAME $BACKUPDIR/$TIMESTAMP
        docker exec {{ container_name }} rm $FILENAME

        {%- endfor %}
        {%- else %}
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

        {%- endif %}


    fi

# rsync just the new or modified backup files
# -------------------------------------------

    {%- if backup.client.target is defined %}
    echo "Adding ssh-key of remote host to known_hosts"
    ssh-keygen -R {{ backup.client.target.host }} 2>&1 | > $RSYNCLOG
    ssh-keyscan {{ backup.client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $RSYNCLOG
    echo "Rsyncing files to remote host"
    /usr/bin/rsync -rhtPv --rsync-path=rsync --progress $BACKUPDIR/* -e ssh zookeeper@{{ backup.client.target.host }}:$SERVERBACKUPDIR >> $RSYNCLOG

    if [ -s $RSYNCLOG ] && ! grep -q "rsync error: " $RSYNCLOG; then
            echo "Rsync to remote host completed OK"
    else
            echo "Rsync to remote host FAILED"
            exit 1
    fi

    {%- endif %}

# Cleanup
# ---------
if [ $SKIPCLEANUP = false ] ; then
    {%- if backup.client.backup_times is not defined %}
    echo "----------------------------"
    echo "Cleanup. Keeping only $KEEP full backups"
    AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
    find $BACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$BACKUPDIR/{} \; -execdir rm -rf $BACKUPDIR/{} \;
    {%- else %}
    echo "----------------------------"
    echo "Cleanup. Keeping only $KEEP full backups"
    NUMBER_OF_FULL=`find $BACKUPDIR -maxdepth 1 -mindepth 1 -type d -print| wc -l`
    FULL_TO_DELETE=$(( $NUMBER_OF_FULL - $KEEP ))
    if [ $FULL_TO_DELETE -gt 0 ] ; then
        cd $BACKUPDIR
        ls -t | tail -n -$FULL_TO_DELETE | xargs -d '\n' rm -rf
    else
        echo "There are less full backups than required, not deleting anything."
    fi
    {%- endif %}
else
    echo "----------------------------"
    echo "-s parameter passed. Cleanup was not triggered"
fi
# Fin.
