#!/bin/bash
#
# This script has a dependency on colordiff. Either install it or change the DIFF variable to regular diff.
#

# Check that we are running as root, if we aren't then exit and show a message
if [[ "$(whoami)" != "root" ]]; then
	echo "You need to run this script as root"
	exit 1
fi

# Check that we are running the script correctly, if we aren't then then exit and show a message
if [[ $# -ne 1 ]]; then
	echo "Usage: restore <filename>"
	exit 1
fi


# User defined variables
HOST="$(hostname)"
BACKUPREPO="/hive/backup/$HOST"
# Set DIFF=diff to use regular diff
DIFF="colordiff"


# Put any found backups in variable SEARCHRESULT
FILENAME="$1"
SEARCHRESULT="$(find $BACKUPREPO -type f -name $FILENAME -printf '%T@ %p\n' | sort -nr | awk '{print $2}')"


# Check that we can actually find what is being asked for in the backup repo, otherwise exit with a message
if [[ -z $SEARCHRESULT ]]; then
	echo "Backup of $FILENAME was not found in $BACKUPREPO"
	exit 1
fi


# Set some pretty colors in variables to be used more easily
RED='\033[0;31m'
GREEN='\033[0;32m'
# Use NC variable to reset to no color
NC='\033[0m'


# Set BACKUPS_FOUND to 0 until proven different
BACKUPS_FOUND=0
# Read the search result into array BACKUPS, also put the corresponding path-files array PATHFILES
while read LINE; do
	# Array to contain the files found
	BACKUPS+=("$LINE")
	# Variable to contain the folder the file resides in 
	BACKUPDIR="$(dirname $LINE)"
	# Array to contain the originating source path for all backups found
	PATHFILES+=("$BACKUPDIR/.$FILENAME.path")
	# Increment BACKUPS_FOUND by one for each found backup
	let BACKUPS_FOUND=BACKUPS_FOUND+1 
done <<< "$SEARCHRESULT"


# Function to show a list of all the files found
showFileList () {
	# Set BACKUPS_CHANGED to 0 until proven different
	BACKUPS_CHANGED=0
	# Give each file an index, for script output purposes, start at 1
	INDEX=1
	# Array counts from 0
	ARRAYINDEX=0
	for BACKUP in "${BACKUPS[@]}"; do
		# Test if we can find any difference between found files and the source
		if ! diff $BACKUP $(cat ${PATHFILES[$ARRAYINDEX]}) > /dev/null 2>&1; then
			echo -e "${GREEN}$INDEX${NC}: $(echo $BACKUP | rev | cut -d '/' -f-2 | rev)"
			# Increment INDEX, ARRAYINDEX and BACKUPS_CHANGED
			let INDEX=INDEX+1
			let ARRAYINDEX=ARRAYINDEX+1
			let BACKUPS_CHANGED=BACKUPS_CHANGED+1
		fi
	done
	# If the amount of changed backups is 0, exit script
	if [[ $BACKUPS_CHANGED -eq 0 ]]; then
		echo "No changes found in $BACKUPS_FOUND files, exiting"
		exit 0
	else
		echo "Found $BACKUPS_CHANGED files with differing content"
	fi
} 

# Function to replace original with backupfile
replaceOrigFile () {
	# Ask user to confirm that we really want to replace the original with chosen backup
	printf '\e[A\e[K'
	echo -e "Really replace?"
	echo -e "${RED}---${NC} $ORIGFILE"
	echo -e "with"
	echo -e "${GREEN}+++${NC} $BACKUPFILE\n"
	
	echo -en "Answer (y)es, or any other key will abort: "

	# Put answer in variable ANSWER, and check if it is a yes
	read ANSWER
	if [[ $ANSWER == "y" ]]; then
		# Reset counter to nothing
		COUNTER=""
		# Run this loop as long as ORIGBACKUP is empty
		while [ -z $ORIGBACKUP ]; do
			# Check if original file already has a backup, iterate until it doesn't
			if [ -f "$ORIGFILE.bak$COUNTER" ]; then
				# Increment COUNTER and try again
				let	COUNTER=COUNTER+1
			else
				# Set ORIGBACKUP to ORIGFILE.bak+number that is not already taken
				ORIGBACKUP="$ORIGFILE.bak$COUNTER"
			fi	
		done
		
		# Some debug output, these are the commands that will run
		echo -e "\n---"
		echo -e "${RED}DEBUG: mv $ORIGFILE $ORIGBACKUP ${NC}"
		echo -e "${RED}DEBUG: mv $BACKUPFILE $ORIGFILE ${NC}"
		echo -e "${RED}DEBUG: rm $PATHFILE ${NC}" 
		echo -e "---"
		echo -e "\nA backup of original has been saved to $ORIGBACKUP"	
	
		# Check if the folder for the backup is empty
		if ls $BACKUPFOLDER > /dev/null 2>&1; then
			echo "$BACKUPFOLDER contains other backups, not removing"
		else
			# If it is empty, remove it
			echo "BACKUPFOLDER is empty, removing it"
			echo "rm -rf $BACKUPFOLDER"
		fi
		
		# Exit script, we're done here
		exit 0
	else
		# Aborting replace, going back to file list
		echo -e "Aborting\n"
		continue
	fi
}

# Make answers non case sensitive
shopt -s nocasematch

# Show our files by calling our function showFileList
while true; do
	# Show us the backups which contain differences from original by calling on our function showFileList
	clear
	showFileList
	
	# Ask user for which backup to diff, and put answer in variable CHOICE
	echo -en "\nWhich file do you want to see a diff of? (enter number or (q)uit): "	
	read CHOICE
		
	# Exit script if user input equals q
	if [[ $CHOICE == "q" ]]; then
		echo "Quitting.."
		exit 0
	# Only allow for numbers to be valid choices
	elif [[ ! "$CHOICE" =~ ^[0-9]*$ ]] ; then 
		echo "Only valid input is numbers or (q)uit"
		sleep 2
		continue
	# Check that choice is not out of range
	elif [ $CHOICE -gt $BACKUPS_CHANGED -o $CHOICE -lt 1 ] ; then
		echo "Please input a number between 1 and $BACKUPS_CHANGED"
		sleep 2
		continue
	else 
		# Put the chosen backup in variable BACKUPFILE
		BACKUPFILE=${BACKUPS[$CHOICE]}
		# Put the folder of chosen backup file in variable BACKUPFOLDER
		BACKUPFOLDER=$(dirname $BACKUPFILE)
		# Put the path to the original file of chosen BACKUPFILE in variable ORIGFILE
		ORIGFILE=$(cat ${PATHFILES[$CHOICE]})
		# Put the path to the corresponding path file in PATHFILE
		PATHFILE=${PATHFILES[$CHOICE]}
		# Show a diff between the chosen backup and original file
		echo ""
		$DIFF -Naur $ORIGFILE $BACKUPFILE
		
		# Ask user for action to be taken
		echo -en "\n(R)eplace file with backup? (Any other key will return to list of backups): "
		read ACTION
			case "$ACTION" in
				r) replaceOrigFile
				;;
				
				*) echo ""
				;;
			esac
	fi
done
