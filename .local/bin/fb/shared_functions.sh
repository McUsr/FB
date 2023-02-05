
# todo: hardcode paths to utilities.

export ROOTFOLDERS="OneShot Periodic"

export SCHEMEFOLDERS="Daily DailySnapshot DailyIncremental DailyDifferential Weekly WeeklyIncremental WeeklyDifferential Monthly MonthlyIncremental MonthlyDifferential"

# checkIfOkMandatoryVariable()
# checks if a variable is set, and contains value,
# and checks that the path indeed exists. 
# it will be fooled by some senselessly set path in a variable.
# TODO: Labels must be passed into system-cat.
# TODO: choose if you want  notifications in addition to loggin information
# with journalctl.

# TODO : NRARG tests!

checkIfOkMandatoryVariable() {
	if [  -z "$1"   ] ; then
		echo The variable $1 isn\'t set. | systemd-cat -t "Daily Differential" -p crit
	elif [ ! -d $1 ] ; then
		echo "The system directory $1 doesn\'t exist. ( Set in Environment=$2=$1. ) " | systemd-cat -t "$3" -p crit
	else
		return 0
	fi
	return 1
}


# brokenSymlink()
# Alert's us if a symlink in a symlink folder is broken,
# Probably due to the fact that we have moved the directory 
# somewhere else, or deleted it. TODO: Get that into the 
# error message as well.

# TODO: Fix for console

brokenSymlink() {
		echo "The symlink $1/$2 is broken! No backups are made for  $2 before it is fixed."  | systemd-cat -t "$3" -p crit
		notify-send "$3" "The symlink $1/$2 is broken! No backups are made for $2 before it is fixed."
}


# isASymlink() 
# returns if the parameter is a symlink.
# ( I need the full path to the file, to be able to check it. {realpath} )
isASymlink() {
	file "$1" | grep 'symbolic link' >/dev/null
	return $?
}


isUnbrokenSymlink() {
	file "$1" | grep 'broken symbolic link' >/dev/null
	if [ $? -eq 0 ] ; then
		return 1
	fi
	return 0 
}

# isDirectory()
# just returns whether the parameter given is a
# directory, or not.
isDirectory() {
	file "$1" | grep 'directory' >/dev/null
	return $?
}

# hasInternet()
# The governor checks if there is an internet-
# connection to back up to, since we are based
# on backing up to our GoogleDrive.
# ping can be installed by:
# sudo apt install iputils-ping
# should it be amiss on your system.

hasInternet() {
	if ping -c 1 -q google.com >&/dev/null ; then 
		return 0
	else
		return 1
	fi
}	

# consoleHasInternet()
# checks if we have our Internet connection
# and times out if we haven't got it still, after 5 minutes.
# from the command line.
# TODO: ADD PROGRESS-BAR
consoleHasInternet() {
	if [[ $# -ne 1 ]] ; then 
		echo -e "${0##*/}/consoleHasInternet  I need a parameter for the BACKUP_SCHEME in use!\nTerminating... " 1>&2
		exit 5
	fi
	  	
local CTR=0
	while : ; do
    if hasInternet ; then
			if [ $CTR -gt 0 ] ; then 
				echo "${0##*/}  :Your internet connection is back. Continuing." | journalThis 5 $1
			fi
	    break 
		else 
			CTR=$(( $CTR + 1 ))
			if [ $CTR -eq 5 ] ; then 
		  	echo  "${0##*/} : No internet connection in 5 minutes. Giving up." | journalThis 2 $1
				exit 255
			else
		  	echo  "${0##*/} : You have no internet connection. Retrying in 1 minute." | journalThis 5 $1
		  	sleep 60 
			fi
		fi
	done	
}


# consoleFolderIsMounted()
# checks if our Destination folder is mounted,
# and times out if it still isn't after 6 minutes.
# from the command line.
# TODO: ADD PROGRESS-BAR
consoleFBFolderIsMounted() {
	if [[ $# -ne 1 ]] ; then 
		echo -e "${0##*/}/consoleFBFolderIsMounted()  I need a parameter for the BACKUP_SCHEME in use!\nTerminating... " 1>&2
		exit 5
	fi
local	MNT_CTR=0 
	while : ; do
		if [  -d $FB ] ; then
				if [ $MNT_CTR -gt 0 ] ; then 
					echo "${0##*/} : You have successfully mounted \$FB: $FB Continuing." | journalThis 5 $1
				fi
				break 
		else 
			MNT_CTR=$(( $MNT_CTR + 1 ))
			if [ $CTR -eq 3 ] ; then 
				echo  "${0##*/} : No mounted folder \$FB: $FB in 6 minutes. Giving up." | journalThis 2 $1
				exit 255
			else
				echo "${0##*/} You have forgotten to mount/create the root backupfolder \$FB: $FB. Retrying in 3 minutes"	| journalThis 5 $1
				sleep 180 
			fi
		fi
	done
}

# TODO: Error output to journal-ctl for backupKind and periodic BackupScheme:
# I might use the methods I have learned with regards to redirecting, the thing is, I have to 
# send to systemd-cat.
# maybe periodicBackupScheme comes in two flavors, daemon and console, due to journalling.
# - not sure if it is necessary when it comes to daemons.

# backupKind()
# Figures out which KIND of backup we are restoring, 
# 'OneShot', or 'Periodical', so we know what to do in 'fbrestore'

backupKind() {
  local	ORIG="$1"
 	local REPLACED="${1/$FB/}"
	if [ "$ORIG" = "$REPLACED" ] ; then 
		echo ${0##*/} : "The path to the backup isn't within  the defined location.\nTerminating..."
		exit 2
	elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then 
		echo -e "${0##*/} : The path to the backup isn't complete with a path to the actual backup.\n($FB isn't specific enough,\nthe path must include the folder from which to restore.)\nTerminating..."
		exit 2
	fi 
	OLDIFS=$IFS
	IFS=/
	set -- $REPLACED
	# the path starts with a delimiter, so $1 will contain '' for the empty element at front to the left
	# of the delimiter.
	if [ ! -z $1  ] ; then 
		echo -e "${0##*/} : The path to the backup starting with the KIND doesn't start with '/'.\n Is it a slash amiss after \$FB ($FB)\n in the path to the backup ($ORIG)?\nTerminating..."
		exit 2
	fi
	export IFS=$OLDIFS
	echo $2
}

# periodicBackupScheme
# Returns the 'Periodic' Backup Schme for a folder, so that the type of 
# restore can be identified by fbrestore.

periodicBackupScheme() {
  local	ORIG="$1"
	local BIT_TO_REMOVE=$FB/Periodic
 	local REPLACED="${1/$BIT_TO_REMOVE/}"
	if [ "$ORIG" = "$REPLACED" ] ; then 
		echo "${0##*/} : The path to the backup isn't within  the defined location.\nTerminating..."
		exit 2
	elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then 
		echo -e "${0##*/} : The path to the backup isn't complete with a path to the actual backup.\n($FB isn't specific enough,\nthe path must include the folder from which to restore.)\nTerminating..."
		exit 2
	fi 
	OLDIFS=$IFS
	IFS=/
	set -- $REPLACED
	# the path starts with a delimiter, so $1 will contain '' for the empty element at front to the left
	# of the delimiter.
	if [ ! -z $1  ] ; then 
		echo -e "${0##*/} : The path to the backup starting with the KIND doesn't start with '/'.\n Is it a slash amiss after \$FB ($FB)\n in the path to the backup ($ORIG)?\nTerminating..."
		exit 2
	fi
	export IFS=$OLDIFS
	echo $2
}


# identifyBackupSourceFolder()
# Parameters: 'BackupKind/BackupScheme' '/Our/parameter/for/a/folder/or/file/to/back/up'
# The path is alredy confirmed to exist.
# Returns the path to the sourcefolder in 'full-symlink-format'
# Example: identifyBackupSourceFolder Periodic/DailySnapshot $FB/Periodic/Daily/etc-apache/apache-2023-01-01
# Returns: etc-apache
# Example: identifyBackupSourceFolder Periodic/OneShot/etc-apache/apache-2023-01-01
# returns etc-apache
identifyBackupSourceFolder() {
	
	if [ $# -ne 2 ] ; then 
		echo -e "${0##*/} : I really need two arguments for identifyBackupSourceFolder()\nTerminating..."
		exit 5
	fi	

  local	ORIG="$2"
	local BIT_TO_REMOVE=$FB/$1
 	local REPLACED="${2/$BIT_TO_REMOVE/}"
	if [ "$ORIG" = "$REPLACED" ] ; then 
		echo "${0##*/} : The path to the backup isn't within  the defined location.\nTerminating..."
		exit 2
	elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then 
		echo -e "${0##*/} : The path to the backup isn't complete with a path to the actual backup.\n($FB/$1 isn't specific enough,\nthe path must include the folder from which to restore.)\nTerminating..."
		exit 2
	fi 
	OLDIFS=$IFS
	IFS=/
	set -- $REPLACED
	# the path starts with a delimiter, so $1 will contain '' for the empty element at front to the left
	# of the delimiter.
	if [ ! -z $1  ] ; then 
		echo -e "${0##*/} : The path to the backup starting with the PREFIX doesn't start with '/'.\n Is it a slash amiss after \$FB ($FB)\n in the path to the backup ($ORIG)?\nTerminating..."
		exit 2
	fi
	export IFS=$OLDIFS
	echo $2
}

# validateFormatOfTimeStampedBackupContainingFolder()
# PARAMETERS: A backup containting folder to validate the name-format of. 
# Returns: A true exit code (0) if the name was valid.

validateFormatOfTimeStampedBackupContainingFolder() {
	if [ $# -ne 1 ] ; then
		echo -e "${0##*/}/validateFormatOfTimeStampedBackupContainingFolder() : \nI really need one argument for identifyTimeStampedBackupContainingFolder()\nTerminating..."
	fi
	 echo "$1" |  grep '.*[-][1-2][09][0-9][0-9][-][01][1-9][-][0-3][0-9]' >/dev/null
	 return $?
}
	 
# identifyTimeStampedBackupContainingFolder()
# Parameters: Stem consisting of backup kind and eventually a scheme,
# and the bucket (a folder named by its full symlink name,
# consisting of the full path to the to the source-folder).
# AND THE FULL PATH TO THE BACKUP AS PARAMETER2!
# RETURNS: The folder that contains the actual backups
# of the source folder, IF it's name  is on the proper form.
#
# Example:
# identifyTimeStampedBackupContainingFolder 'OneShot/var-html/' '/pathtoFB/OneShot/var-html/html-2023-01-08/'
# returns: '/var/html'
# Example2:
# identifyTimeStampedBackupContainingFolder 'Periodic/DailySnapshot/var-html/' '/pathtoFB/Periodic/DailySnapshot/var-html/html-2023-01-08/'
# returns: '/var/html'
identifyTimeStampedBackupContainingFolder() {
# Container
	
	if [ $# -ne 2 ] ; then 
		echo -e "${0##*/} : I really need two arguments for identifyTimeStampedBackupContainingFolder()\nTerminating..."
		exit 5
	fi	

  local	ORIG="$2"
	local DEESCAPED_ORIG="$( echo "$ORIG" | sed -ne 's:\\::g' -e 'p' )"
	local BIT_TO_REMOVE="$FB/$1"
	local DEESCAPED_BIT_TO_REMOVE="$( echo "$BIT_TO_REMOVE" | sed -ne 's:\\::g' -e 'p' )"
	local DBG_ESC=1
	if [ $DBG_ESC -eq 0 ] ; then 
		echo ORIG : "$ORIG" >/dev/tty
		echo DEESCAPED_ORIG : "$DEESCAPED_ORIG" >/dev/tty
		echo BIT_TO_REMOVE :"$BIT_TO_REMOVE" >/dev/tty
		echo DEESCAPED_BIT_TO_REMOVE : "$DEESCAPED_BIT_TO_REMOVE" >/dev/tty
	fi
 	local REPLACED="${DEESCAPED_ORIG/$DEESCAPED_BIT_TO_REMOVE/}"
	if [ "$ORIG" = "$REPLACED" ] ; then 
		echo "${0##*/} : The path to the backup isn't within  the defined location.\nTerminating..." >&2
		exit 2
	elif [[ "$REPLACED" = "/" ||  -z "$REPLACED" ]] ; then 
		echo -e "${0##*/}/identifyTimeStampedBackupContainingFolder() : \nThe path to the backup isn't complete with a path to the actual backup.\n($FB/$1 isn't specific enough,\nthe path must include the folder from which to restore,\n and a timestamped folder that contains the actual files containing the  backup.)\nTerminating..." >&2
		exit 2
	fi 
	OLDIFS=$IFS
	IFS=/
	set -- $REPLACED
	# the path starts with a delimiter, so $1 will contain '' for the empty element at front to the left
	# of the delimiter.
	if [ ! -z $1  ] ; then 
		echo -e "${0##*/}/identifyTimeStampedBackupContainingFolder() : \nThe path to the backup starting with the PREFIX doesn't start with '/'.\n Is it a slash amiss after \$FB ($FB)\n in the path to the backup ($ORIG)?\nTerminating..." >&2
		exit 2
	fi
	export IFS=$OLDIFS
	# We check here if the folder conforms with the naming standard.
	if validateFormatOfTimeStampedBackupContainingFolder "$2" ; then 
		echo $2 | sed -ne 's:^\.:\\.:' -e 'p'
	else
		echo -e "${0##*/}/identifyTimeStampedBackupContainingFolder() : \nThe name of the folder that is supposed to be a timestamped folder,\n that consists of the name of the original folder and a timestamp, isn't on the correct format.\n("$2")?\nTerminating..." >&2
		exit 2
	fi
}

# baseFromFullSymlinkName() 
# returns the base folder name from a full symlink-name.
# Ex: `baseFromFullSymlinkName usr-share-fonts`
# returns `fonts`
# and before that, I have to figure out todays name.
baseFromFullSymlinkName() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an argument\nTerminates" >&2 ; exit 5 ; fi
echo "$1" |  sed -n  's:^.*[-]::p'
}

# baseNameDateStamped() 
# returns the base folder name from a full symlink-name with
# an iso8601 datestamp appended.
# Ex: `baseNameDateStamped usr-share-fonts`
# returns `fonts-2023-01-12`
baseNameDateStamped() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an argument\nTerminates" >&2 ; exit 5 ; fi
	echo $(echo "$1" |  sed -n  's:^.*[-]::p')-$(date +"%Y-%m-%d")
}

# baseNameDateStamped() 
# returns the base folder name from a full symlink-name with
# an iso8601 datestamp appended.
# Ex: `baseNameDateStamped usr-share-fonts`
# returns `fonts-2023-01-12`
baseNameTimeStamped() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an argument\nTerminates" >&2 ; exit 5 ; fi
	echo $(echo "$1" |  sed -n  's:^.*[-]::p')-$(date +"%Y-%m-%dT%H:%M")
}


# baseNameFromBackupFile() 
# returns the base folder name which is the name of the tarball,
# without the suffix.
# it handles invisible files.

baseNameFromBackupFile() {
if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need an argument\nTerminates" >&2 ; exit 5 ; fi
	echo "$1"	| sed -n 's,\(.*[-][^.]\+\).*,\1,p'
}
# validPathOrFileName() 
# Returns 0 if the path is legal 
# it returns true for two / in a row,
# but that IS legal in Unix/Linux
# $HOME//docs/tech is a legal path.
# where the superfluous '/' is simply 
# ignored.

validPathOrFileName() {
	grep -En '^/?(([A-Za-z]|[-_+.])+/?)+$' &>/dev/null
	return $?
}


# hasLevel0SnarFile()
# is called from both incremential and
# differential routines to assert that
# we have indeed the level0 snar file.

function hasLevel0SnarFile() {
	if [ ! -f $1 ] ; then
		echo "${0##*/} : I can't find the file $1, something is terribly wrong. Exiting."
		# Dette går til critical error i log, men avstedkommer også en notification.
		exit 9
	fi
}


# nextSnarFile()
# Used for *differential backups*. Takes a name
# of the form base.{number}.suffix and finds
# the first file name, with a higher number in
# it, that doesn't exist.

nextSnarFile() { 
	IFS='.' 
	set $1
	newNum=1
	# we start
	newfile=$1.$newNum.$3
	while [ -f $newfile ] ; do
		newNum=$(expr $newNum + 1 )
		newfile=$1.$newNum.$3
	done
	echo $newfile
}

# fullPathSymlinkName() 
# PARAMETERS: the full path to convert.

# RETURNS: the fullPath of the folder we want to create a symlink to,, so that
# there is no ambiguity, as to which folder the symlink points to.

fullPathSymlinkName() {
	if [ $# -ne 1 ] ; then 
		echo -e "${0##*/}/fullPathSymlinkName: I need exactly 1 parameter.\nTerminating"
		exit 5
	fi
	local fn
	fn=$(realpath "$1")
	echo "$fn" | sed -ne 's:^/::' -e 's:/:-:g' -e 's:^\.:\\.:' -e 's:[-]\(\.\):-\\\1:' -e 'p'
}

# pathFromFullSymlinkName(){
# PARAMETERS: the full symlink name to convert.
# RETURNS the fullSymlinkName back to the path it once was.
# Add a trailing slash yourself, on the outside, shoud you need one.

pathFromFullSymlinkName() {
	if [ $# -ne 1 ] ; then 
		echo -e "${0##*/}/pathFromFullSymlinkName: I need exactly 1 parameter.\nTerminating"
		exit 5
	fi
	echo "$1" | sed -ne  's:^:/:' -e 's:-:/:g' -e ':/(.*/)$:\1\/:g' -e 's:\\::' -e 'p'
}

# journalThis() 
# Sends output to the journal, not sure of the utility for most commandline commands
# Can be useful for fbinstall and fbctl though. so we can keep track of jobs and their
# status, insulating the file system.
# PARAMETERS:
#   LOGLEVEL : the log level the message shall be filed under
#   TAG: the tag the message should be tagged under.
# GLOBAL VARIABLES:
#   LOG_TO_JOURNAL : If this variable is set, and true, then the message will be sent to the
#   log, otherwise, the message will be sent to the console.

journalThis() {

	if [ $# -ne 2 ] ; then 
		echo -e "${0##*/}/journalThis(): I really need two parameters.\nTerminating"
		exit 5
	fi
  if [[ -v LOG_TO_JOURNAL && $LOG_TO_JOURNAL = true ]] ; then 
		tee /dev/tty | sed -n '/[a-z][A-Z]*/ s:^:<'''$1'''>:p' | systemd-cat -t $2
	else 
		cat >/dev/tty
	fi
}


# manager()
# find the correct script/dropin-script to execute if any:
# Passes the DELEGATE back to the caller by the global  DELEGATE_SCRIPT variable.
# PARAMETERS (mandatory!)
# BACKUP_SCHEME, or kind what considers OneShot.
# SYMLINK_NAME
# OPERATION backup/restore, so we can use it everywhere.

manager() {
	declare -g DELEGATE_SCRIPT
  local CANDIDATE_SCRIPT GENERAL_DROPIN LOCAL_DROPIN

	if [ $# -ne 3 ] ; then 
		echo -e "$PNAME/manager() : Wrong number of arguments, I need BACKUP_SCHEME SYMLINK_NAME OPERATION\nTerminates..." | journalThis 2 $BACKUP_SCHEME
		exit 5
	else
		BACKUP_SCHEME=$1
		SYMLINK_NAME=$2
		OPERATION=$3

		if [[ $OPERATION != "backup" && $OPERATION != "restore" ]] ; then 
			echo -e "$PNAME/manager() : Wrong value for \$OPERATION, MUST  be either \"backup\" or \"restore\".\nTerminates..." | journalThis 2 $BACKUP_SCHEME
		exit 5
		fi
	fi

	CANDIDATE_SCRIPT="$XDG_BIN_HOME"/fb/"$BACKUP_SCHEME"/"$BACKUP_SCHEME".$OPERATION.sh

	if [ ! -x "$CANDIDATE_SCRIPT" ] ; then
		# same if with DRYRUN or VERBOSE
		echo -e "$PNAME/manager() : I can't find the backup script "$CANDIDATE_SCRIPT".\nThis is a critical error.\nTerminates..." | journalThis 2 $BACKUP_SCHEME
		exit 255
	else

		DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
		if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then 
			echo "$PNAME/manager() : Current backup script is : $DELEGATE_SCRIPT" | journalThis 7 $BACKUP_SCHEME
		fi
	fi
	GENERAL_DROPIN=1
	# the place to look for a general replacement is in the $BACKUP_SCHEME.d folder.

	CANDIDATE_SCRIPT="$XDG_BIN_HOME"/fb/"$BACKUP_SCHEME"/"$BACKUP_SCHEME".d/"$BACKUP_SCHEME".$OPERATION.sh
	if [  -f "$CANDIDATE_SCRIPT" ] ; then
		if [[ $DEBUG -eq 0 || $VERBOSE = true || $DRYRUN = true ]] ; then
			echo "$PNAME/manager() :  I have a readable backup script: "$CANDIDATE_SCRIPT"." | journalThis 7 $BACKUP_SCHEME
		fi
		if [ ! -x "$CANDIDATE_SCRIPT" ] ; then
			echo -e "$PNAME/manager() :  I found a backup dropin script: "$CANDIDATE_SCRIPT"\nBut it isn't executabe.\nTerminates.." | journalThis 7 $BACKUP_SCHEME
			exit 5
		else
			GENERAL_DROPIN=0
			DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
			if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then 
				echo "$PNAME/manager() : I found a GENERAL backup dropin script: Current backup script is : $DELEGATE_SCRIPT" | journalThis 7 $BACKUP_SCHEME
			fi
		fi
	elif [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then 
		echo "$PNAME/manager() : I didn't find  a GENERAL backup dropin script at: "$CANDIDATE_SCRIPT"." | journalThis 7 $BACKUP_SCHEME 
	fi
	LOCAL_DROPIN=1
	# the place to look for a general replacement is in the $BACKUP_SCHEME.d folder.
	CANDIDATE_SCRIPT="$XDG_BIN_HOME"/fb/"$BACKUP_SCHEME"/"$SYMLINK_NAME".d/"$BACKUP_SCHEME".$OPERATION.sh

	if [  -f "$CANDIDATE_SCRIPT" ] ; then
		if [[ $DEBUG -eq 0 || $VERBOSE = true || $DRYRUN = true ]] ; then
			echo "$PNAME/manager() : I have a readable LOCAL dropin backup script: "$CANDIDATE_SCRIPT"." | journalThis 7 $BACKUP_SCHEME
		fi
		if [ ! -x "$CANDIDATE_SCRIPT" ] ; then
			echo -e "$PNAME/manager() :  I found a LOCAL backup dropin script: "$CANDIDATE_SCRIPT".\nBut it isn't executabe.\nTerminates.." | journalThis 7 $BACKUP_SCHEME
			exit 5
		else
			LOCAL_DROPIN=0
			DELEGATE_SCRIPT="$CANDIDATE_SCRIPT"
			if [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then 
				echo "$PNAME/manager() : I found a LOCAL backup dropin script : Current backup script is : $DELEGATE_SCRIPT" | journalThis 7 $BACKUP_SCHEME
			fi
		fi
	elif [[ $VERBOSE = true || $DEBUG -eq 0 || $DRYRUN = true ]] ; then 
		echo "$PNAME/manager() : I didn't find  a LOCAL backup dropin script in : "$CANDIDATE_SCRIPT"." | journalThis 7 $BACKUP_SCHEME
	fi

}


# verifyEditorToUse() 
# selects VISUAL over EDITOR
# sets global THE_EDITOR with the correct editor.
# RETURNS: any error code.
dieIfNoEditorSetToUse() {
  declare -g THE_EDITOR
	FOUND_EDITOR=1 

	if [[  -v VISUAL  ]] ; then  
		type -a $VISUAL &>/dev/null 
		if [[ $? -eq 0 ]] ; then 
			# if 0, found  executable
	 		FOUND_EDITOR=0 ; THE_EDITOR=$VISUAL
		fi	
	fi

	if [[ $FOUND_EDITOR -eq 0 && -v EDITOR  ]] ; then  
		type -a $EDITOR >/dev/null
		if [[ $? -eq 0 ]] ; then 
	 		FOUND_EDITOR=0 ; THE_EDITOR=$EDITOR
		fi	
	fi
	if [[ $FOUND_EDITOR -ne 0  ]] ; then 
		echo -e  "$PNAME : Neither the  variable \$VISUAL nor \$EDITOR was set or didn't point to a binary.\nYou need to set assign the \$EDITOR variable in .bashrc or .bash_profile, then  \"exec bash\" and try again.\nTerminating..." | journalThis 5 OneShot
		exit 255
	fi

}

# dieIfNotValidFullSymlinkName()
# PARAMETERS: SYMLINKNAME SCHEME
# RETURNS: 0, if the symlink name is valid.
dieIfNotValidFullSymlinkName() {
	if [[ $# -ne 2 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : I need two arguments full-symlink-name and scheme.\nTerminates" >&2 ; exit 5 ; fi
  local FULL_SYMLINK_NAME SCHEME
	FULL_SYMLINK_NAME="$1" ; SCHEME=$2
	if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} :FULL_SYMLINK_NAME : $FULL_SYMLINK_NAME" | journalThis 7 $SCHEME
	fi 
	full_path="$(pathFromFullSymlinkName $FULL_SYMLINK_NAME)"
	if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} :full_path after : \$(pathFromFullSymlinkName \"\$FULL_SYMLINK_NAME\") : $full_path"| journalThis 7 $SCHEME
	fi
	symlink_probe="$(fullPathSymlinkName "$full_path" )" 

	if [[ "$FULL_SYMLINK_NAME" != "$symlink_probe" ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} : $FULL_SYMLINK_NAME Not a valid symlink name! \nTerminates" >&2 ; exit 5 
 	fi
}

# dieIfNotValidFbFolderName() 
# returns 0 if the folder name within XDG_BIN_HOME/fb given, is a valid one
# TODO: We must premake the folders?

dieIfNotValidFbFolderName() {

	if [[ $# -ne 1 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : I need 1 argument.\nTerminates" >&2 ; exit 5 ; fi
	local validFbFolderNames
	validFbFolderNames=( OneShot DailySnapshot DailyIncremental WeeklySnapshot WeeklyIncremental WeeklyDifferential MonthlySnapshot MonthlyDifferential MonthlyIncremental )
	FOUND_SCHEME=1
	for backup_category in ${validFbFolderNames[@]} ; do
	 	if [[ $1 = $backup_category ]] ; then
			FOUND_SCHEME=0
			break
		fi
	done
	if [[ $FOUND_SCHEME -ne 0 ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} : $2 Not a valid scheme folder name in the $XDG_BIN_HOME/fb folder! \nTerminates" | journalThis 2 FolderBackup ; exit 2
		# error_code 2, because can be user set from the command line.
	fi
}

# createExcludeFile() 
# 
# creates an exclude file, or not, in which case the caller should abort the current operation.
# that is, this current operation.
# PARAMETERS:
# a scheme name 
# A valid symlink name.
# GLOBAL: uses  THE_EDITOR with the correct editor, if any.

createExcludeFile() {
	if [[ $# -ne 2 ]] ; then echo -e "${0##*/}/${FUNCNAME[0]} : Need two argument\nTerminates" >&2 ; exit 5 ; fi
	# visual first, editor after.
	dieIfNotValidFbFolderName $1
	SCHEME=$1
	dieIfNotValidFullSymlinkName "$2" $1
	FULL_SYMLINK_NAME="$2"

	# Only one place a the exclude file. And if it doesn't exist, then we'll make it.
	if [ ! -d "$XDG_BIN_HOME"/fb/$SCHEME/"$FULL_SYMLINK_NAME".d ] ; then 
		echo "$XDG_BIN_HOME"/fb/$SCHEME/"$FULL_SYMLINK_NAME".d

		if [[ $DEBUG -eq 0 || $VERBOSE = true ]] ; then 
			echo -e "$PNAME : The folder \"$XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d\" didn't exist.\nMaking it.\nmkdir -p ~/.local/bin/fb/OneShot/$FULL_SYMLINK_NAME.d" | journalThis 7 $SCHEME
		fi
		mkdir -p $XDG_BIN_HOME/fb/$SCHEME/"$FULL_SYMLINK_NAME".d
		touch $XDG_BIN_HOME/fb/$SCHEME/"$FULL_SYMLINK_NAME".d/exclude.file
	fi

	dieIfNoEditorSetToUse

	$THE_EDITOR "$XDG_BIN_HOME"/fb/$SCHEME/"$FULL_SYMLINK_NAME".d/exclude.file

	if [[ $? -ne 0 ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} : Something went wrong during editing.\n $XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d/exclude.file\nTerminating..." | journalThis 2 OneShot
		exit 1
	fi

	# Maybe we should check if there were any contents in the file we created before we see this as a success?
  grep '[-/.@+a-zA-Z0-9]\+'  < $XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d/exclude.file &>/dev/null 
	if [[  $? -ne 0 ]] ; then 
		echo -e "${0##*/}/${FUNCNAME[0]} : The exclude file\n$XDG_BIN_HOME/fb/$SCHEME/$FULL_SYMLINK_NAME.d/exclude.file\nIs empty!\nTerminating..." | journalThis 2 $SCHEME
		exit 1
	fi 
}


# topLevelConsistency() 
# Checks that we have internet, so we can check the superstructure for sure
# and that the superstructure is in order. We perform per - backup scheme tests
# further down the road. It is run before we install or remove a folder.

topLevelConsistency() {

	if ! hasInternet ; then
		echo "${0##*/} : No internet connection. I really need that! Exiting."
		exit 9
	fi

	# checking main environment var 

	if [ x"$FB" = x ] ; then
		echo "${0##*/} : The variable \$FB not set in your .bash_profile. I really need that! Exiting."
		exit 9
	fi

	# Consistency of dest folder tree.

	if [ ! -d $FB ] ; then
			echo  "${0##*/}" "You have forgotten to mount/create $FB. Exiting."	
			exit 9
	fi


	if [ ! -d $FB/OneShot ] ; then
			echo  "${0##*/}" "You have forgotten to mount/create $FB/OneShot. Exiting."	
			exit 9
	fi

	if [ ! -d $FB/Periodic ] ; then
			echo  "${0##*/}" "You have forgotten to mount/create $FB/Periodic. Exiting."	
			exit 9
	fi

	# consistency with regards to .config folders. We are only considering the 
	# static parts of the structure here, Backup-schemes may come and go, this is handled
	# on that level?

	if [ ! -d ~/.config/systemd/user ] ; then
			echo  "${0##*/}" "I can't find the user services folder ~/.config/systemd/user. Is the system installed?. Exiting."	
			exit 9
	fi


	if [ ! -d ~/.local/share/FBInstall ] ; then
			echo  "${0##*/}" "I can't find the main folder for symlinks to backup folders ~/.local/share/FBInstall. Is the system installed?. Exiting."	
			exit 9
	fi

	if [ ! -d ~/.local/bin/FB ] ; then
			echo  "${0##*/}" "I can't find the  ~/.local/bin/FB folder that is the root of the source tree with backup scripts.Is the system installed? Exiting."
			exit 9
	fi
	return 0
}
