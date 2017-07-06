{%- from "zookeeper/map.jinja" import backup with context %}
#!/bin/bash

# Script is to locally prepare appropriate backup to restore from local or remote location and call client-restore script in for loop with every keyspace

# Configuration
# -------------
    BACKUPDIR="{{ backup.backup_dir }}/full"
    SCRIPTDIR="/usr/local/bin"
    DBALREADYRESTORED="{{ backup.backup_dir }}/dbrestored"
    LOGDIR="/var/log/backups"
    LOGFILE="/var/log/backups/zookeeper-restore.log"
    SCPLOG="/var/log/backups/zookeeper-restore-scp.log"


if [ -e $DBALREADYRESTORED ]; then
  error "Databases already restored. If you want to restore again delete $DBALREADYRESTORED file and run the script again."
fi

# Create backup directory.
if [ ! -d "$LOGDIR" ] && [ ! -e "$LOGDIR" ]; then
    mkdir -p "$LOGDIR"
fi

{%- if backup.client.restore_from == 'remote' %}

echo "Adding ssh-key of remote host to known_hosts"
ssh-keygen -R {{ backup.client.target.host }} 2>&1 | > $SCPLOG
ssh-keyscan {{ backup.client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $SCPLOG
REMOTEBACKUPPATH=`ssh zookeeper@{{ backup.client.target.host }} "/usr/local/bin/zookeeper-restore-call.sh {{ backup.client.restore_latest }}"`

#get files from remote and change variables to local restore dir

LOCALRESTOREDIR=/var/backups/restoreZookeeper
FULLBACKUPDIR=$LOCALRESTOREDIR/full

mkdir -p $LOCALRESTOREDIR
rm -rf $LOCALRESTOREDIR/*

echo "SCP getting full backup files"
FULL=`basename $REMOTEBACKUPPATH`
mkdir -p $FULLBACKUPDIR
`scp -rp zookeeper@{{ backup.client.target.host }}:$REMOTEBACKUPPATH $FULLBACKUPDIR/$FULL/  >> $SCPLOG 2>&1`

# Check if the scp succeeded or failed
if ! grep -q "No such file or directory" $SCPLOG; then
        echo "SCP from remote host completed OK"
else
        echo "SCP from remote host FAILED"
        exit 1
fi

echo "Restoring db from $FULLBACKUPDIR/$FULL/"
for filename in $FULLBACKUPDIR/$FULL/*; do $SCRIPTDIR/zookeeper-backup-restore.sh -f $filename; done

{%- else %}

FULL=`find $BACKUPDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -{{ backup.client.restore_latest }} | tail -1`
echo "Restoring db from $BACKUPDIR/$FULL/"
for filename in $BACKUPDIR/$FULL/*; do $SCRIPTDIR/zookeeper-backup-restore.sh -f $filename; done

{%- endif %}
