#!/bin/bash

# User defined variables
HOST="$(hostname)"
FILELIST="/etc/backup-sys-files/filelist"
BACKUPREPO="/hive/backup/$HOST"

## Check that we are running as root
#if [ "$(whoami)" != "root" ]; then
#	echo "You need to run this script with sudo"
#	exit 1
#fi

#Function to write backup
writeBackup () {
	mkdir -p $BACKUPFOLDER
	rsync -q -p -P $SRCFILE ${BACKUPFOLDER}${FILENAME}
	echo $SRCFILE > "${BACKUPFOLDER}".${FILENAME}.path
	echo ""
}

while true; do
	while read SRCFILE; do
		if [ ! -z $(echo $SRCFILE | grep -v '^#') ]; then
	
			# Set necessary variables
			DATE=$(date +"%Y-%m-%d_%H:%M:%S")
			FILENAME="${SRCFILE##*/}"
			BACKUPFOLDER="${BACKUPREPO}$(dirname $SRCFILE)/${DATE}/"
	
			# Check if you can find a copy of SRCFILE in the backup repository
			find $BACKUPREPO -name $FILENAME | egrep '.*' > /dev/null 2>&1
	
			# If file can not be found, then create a folder for it and rsync it
			if [ $? -ne 0 ]; then
				echo "Adding new file: $FILENAME"
				writeBackup
				NEWFILE="${SRCFILE##*/}"
				NEWFILES="$NEWFILE $NEWFILES"
				continue
			fi
			
			# If you found a backup of the file, diff it with the source file		    	
			DIFFDSTFILE="$(find $BACKUPREPO -name $FILENAME -printf '%T@ %p\n' | sort -nr | head -1 | awk '{print $2}')"
			diff "$SRCFILE" "$DIFFDSTFILE" > /dev/null 2>&1
			
			# If the sourcefile has been updated, create a new backup for it
			if [ $? -ne 0 ]; then
				echo "$FILENAME has been updated, syncing changes to $BACKUPFOLDER"
				writeBackup
				UPDATEDFILE="${SRCFILE##*/}"
				UPDATEDFILES="$UPDATEDFILE $UPDATEDFILES"
			fi
		fi
	done < $FILELIST
	sleep 300
done
