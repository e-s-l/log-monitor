#!/bin/bash

##########################################################################################################################################
#
# This script given the live log file intermittently watches it and searches for ERROR matches.
# If found the program appends the error code and messages to a file
########
# then... maybe... and rsyncs/pushes this file to the server running the alarm watchdog system.
# Here(there) another file takes the reins and triggers the appropriate alarms.
#
#Again, over-engineered (badly), could probably like 1 line...
#
##########################################################################################################################################


##############
#FUNCTIONS:

read_config_variables() {
	###
	if $DEBUG; then echo; echo "read_config_variables"; echo; fi
	###
	# read in variables from configuration file:
	. ./monitor.config  # source variables from config file
	###
	echo "Remote Host: $REMOTE_HOST"
	echo "Status file: $STATUS_FILE"
	echo "Time till timeout: $TIMEOUT_TIME seconds"
}

find_errors() {
	###
	if $DEBUG; then echo; echo "find_errors"; fi
	###
	# find occurrences of errors for each line and print to status file if so.
	local STREAM="$1"
	#local STATUS="$2"
	#echo "Running: $1"
	#echo "to Status: $2"
	
	#OUTPUT=$(timeout -k 0.1s $TIMEOUT_TIME $STREAM 2>&1) 
	#if [ $? -eq 124 ]
	#then
	#	echo "Timeout!"
	#	echo "Warning. Log file timed out.">> "$STATUS_FILE"
	#	finisher
	#fi

	while read -r line
	do
		if [[ $line == *"ERROR"* ]]
		then
			echo "Found error."
			echo "$line" >> "$STATUS_FILE"
		fi
	done < "$STREAM"

	#done < <($STREAM)	# translate this...
}

finisher() {
	###
	if $DEBUG; then echo; echo "finisher"; echo; fi
	###
	# properly kill the stream and tail processes
	kill "$(pgrep -f "$STREAM_LOG")" &>/dev/null	# & means...
}

# catch signals and close correctly
trap "finisher; exit 1" SIGINT SIGTERM

main() {
	###
	if $DEBUG; then echo; echo "main"; echo; fi
	###
	
	# Assign positional parameters to variables (for clarity)
	EXP=$1
	TL=$2

	#File names:
	EXP_LOG="${EXP}${TL}.log"
	echo "Expect log file: ${EXP_LOG}"

	#
	read_config_variables
	#
	# start ssh connection and tail the log file
	#ssh $REMOTE_USER@$REMOTE_IP "timeout $TIMEOUT_TIME tail -f $LOG_FILE"  # with timeout
	# need catch for timeout eg if timeout echo "warning" > status file
	#ssh $REMOTE_USER@$REMOTE_IP "tail -f $LOG_FILE"
	# Check if log file exists
		# if ! ssh "$REMOTE_USER@$REMOTE_SERVER" "[ -f $LOG_FILE_PATH ]"; then
	#	echo "Log file not found on remote server."
	# 	exit 1
		#fi

	if ! [ -f "$EXP_LOG" ]
	then 
		echo "Log file $EXP_LOG not found!"
		exit 2
	else
		# empty the status file
		echo -n > $STATUS_FILE
		# start tailing the log file
		STREAM_LOG="tail -f $EXP_LOG"	# local debug version:
		# check the tail for errors
		find_errors "$STREAM_LOG"
	fi
	

	###
	# Finishing up:
	# But how do we get here...

	# delete the file when not running
	#rm -f "${STATUS_FILE}"
	# exit: all well:
	exit 0
}

##############

DEBUG=false

#CHECK POSITIONAL PARAMETERS:
if [ "$#" -eq 3 ] && [ "$3" -eq "-d" ]		# recall: $# = len(#@)
then
	echo "Debug Mode: ON"
	DEBUG=true
elif ! [ $# = 2 ]		
then
	echo "This script it to be run like: $0 EXP TL"
	exit 1
fi

if ! [ "$2" -eq "NN" ] || ! [ "$2" -eq "NS" ]	# hmmm
then
	echo "Are you not using NN or NS ?!"
	exit 1
fi

main "$1" "$2"
		
