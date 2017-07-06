{%- from "zookeeper/map.jinja" import backup with context %}
#!/bin/bash
# Script to restore zookeeper schema and keyspaces from snapshot one by one

# Configuration
# -------------
    ZOOKEEPERDIR="/var/lib/zookeeper/version-2/"
    DBALREADYRESTORED="{{ backup.backup_dir }}/dbrestored"

# Functions
# ---------
    function check_dependencies() {
        # Function to iterate through a list of required executables to ensure
        # they are installed and executable by the current user.
        DEPS="awk cat cut echo find getopt grep hostname "
        DEPS+="mkdir rm sed tar tr "
        for bin in $DEPS; do
            $( which $bin >/dev/null 2>&1 ) || NOTFOUND+="$bin "
        done

        if [ ! -z "$NOTFOUND" ]; then
            printf "Error finding required executables: ${NOTFOUND}\n" >&2
            exit 1
        fi
    }

    function usage() {
        printf "Usage: $0 -h\n"
        printf "       $0 -f <backupfile file>\n"
        printf "    -h,--help                          Print usage and exit\n"
        printf "    -f,--file <backup tar file>        REQUIRED: The backup tar file name\n"
        exit 0
    }


# Validate Input/Environment
# --------------------------
    # Great sample getopt implementation by Cosimo Streppone
    # https://gist.github.com/cosimo/3760587#file-parse-options-sh
    SHORT='h:f:'
    LONG='help,file:'
    OPTS=$( getopt -o $SHORT --long $LONG -n "$0" -- "$@" )

    if [ $? -gt 0 ]; then
        # Exit early if argument parsing failed
        printf "Error parsing command arguments\n" >&2
        exit 1
    fi

    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -h|--help) usage;;
            -f|--file) BACKUPFILE="$2"; shift 2;;
            --) shift; break;;
            *) printf "Error processing command arguments\n" >&2; exit 1;;
        esac
    done

    # Verify required binaries at this point
    check_dependencies

    # Only a backup file is required
    if [ ! -r "$BACKUPFILE" ]; then
        printf "You must provide the location of a snapshot package\n"
        exit 1
    fi

    # Need write access to local directory to create dump file
    if [ ! -w $( pwd ) ]; then
        printf "You must have write access to the current directory $( pwd )\n"
        exit 1
    fi


# LOAD BACKUP FILE
# ----------------
    # Extract snapshot package
    tar -xvzf "$BACKUPFILE" -P
    RC=$?

    if [ $RC -gt 0 ]; then
        printf "\nBackup file $BACKUPFILE failed to load.\n"
        exit 1
    else
        printf "\nBackup file $BACKUPFILE was succesfully loaded.\n"
        touch $DBALREADYRESTORED
    fi

# Fin.
