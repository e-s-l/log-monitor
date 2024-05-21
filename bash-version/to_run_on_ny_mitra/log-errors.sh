#!/bin/bash

#######################################################################################################################################
#
# This script intermittently watches a live log file for ERROR matches. If found, it appends the error code and messages to a file.
# It is designed assuming that an alarm system will be triggered if the STATUS_FILE is non-empty.
# ie Run on Ny Mitra pulling from FS. If need be can easily be reversed.
#
#######################################################################################################################################

# FUNCTIONS:

get_config() {
	###
	if $DEBUG; then echo "get_config"; fi
	###
	# Read in variables from configuration file:
	. ./log-errors.cfg  # Source variables from config file
	###
	if [ "$1" == "nn" ]; then	#switch for the two field systems
		SERVER=$FS_NN_IP
	elif [ "$1" == "ns" ]; then
		SERVER=$FS_NS_IP
	fi

	if $DEBUG; then
		echo "Status file: $STATUS_FILE"
		echo "Time till timeout: $TIMEOUT_TIME seconds"
		echo "Remote User: $USER"
		echo "FS_IP: $SERVER"
	fi
}

finisher() {
	###
	if $DEBUG; then echo "finisher"; fi
	###
	# Properly kill the stream and tail processes
	#pgrep -f "$FIND_ERRORS" | xargs -r kill &>/dev/null
	# Or...
	kill "$(pgrep -f "$FIND_ERRORS")" &>/dev/null	#otherwise tail will keep running...
	exit 0
}

# Catch signals and close correctly
trap "finisher; exit 0" SIGINT SIGTERM

main() {
	###
	if $DEBUG; then echo "main"; fi
	###
    # Assign positional parameters to variables (for clarity):
	EXP="$1"	# EXP for experiment
	TL="$2"		# TL for telescope
	#
	get_config "$TL"
	#
	# File name:
	EXP_LOG="${EXP}${TL}.log"
	###
	if $DEBUG; then echo "Expect log file: ${EXP_LOG}"; fi
	###
	# Log file with path:
	LOG_FILE="/usr2/log/$EXP_LOG"

	if ssh "${USER}@${SERVER}" "[ -f \"$LOG_FILE\" ]"; then		#check existence of log file
		if $DEBUG; then echo "Found log!"; fi
		# Empty (or create) the status file
		echo -n > "$STATUS_FILE"
		# Start tailing the log file:
		ssh "${USER}@${SERVER}" "timeout ${TIMEOUT_TIME} tail -f \"${LOG_FILE}\"" | \
		while read -r line; do
			if echo "$line" | grep -q "ERROR"; then				# if a line in the tail has the word error
				if ! grep -Fxq "$line" log-errors.cfg; then		# & if the line is NOT in the .cfg file (note this might be too strict...)
					echo "$line" >> "$STATUS_FILE"				# then print to status file.
					###
					if $DEBUG; then echo "ERROR!"; fi
					###
				fi
			fi
		done
		# Catch errors...
		exit_code=${PIPESTATUS[0]}  #$?						# to catch errors thrown by timeout.    #THIS NEEDS MORE WORK!
		if [ "$exit_code" -eq 124 ]; then					# so we know if it timed-out
			if $DEBUG; then echo "Timeout!"; fi
			echo "Warning. Log file timed out." >> "$STATUS_FILE"
		elif [ "$exit_code" -ne 0 ]; then					# other non-timeout related exit codes
			if $DEBUG; then echo "Error occurred while excuting tail or SSH."; echo; fi
		fi
		###
		echo "Exiting Log Error Monitor." >> "$STATUS_FILE"		# we're outta here
		finisher
		###

	else
		if $DEBUG; then echo "Log file $LOG_FILE not found!"; fi
		exit 2	#couldn't find the log file
	fi

}

#######################################################################################################################################
###
DEBUG=false

# Check positional parameters:
# -d switch to turn on debug.
if [ "$#" -eq 3 ] && [ "$3" == "-d" ]; then		# Recall: $# = len(#@)
	echo "Debug Mode: ON"
	DEBUG=true
elif ! [ $# = 2 ]; then
# wrong number of arguments.
	echo "This script should be run like: $0 EXP TL"
	exit 1
fi
###
if ! ([ "$2" == "nn" ] || [ "$2" == "ns" ]); then
	# parameter wasn't what we expected.
	echo "Are you not using NN or NS ?!"
	exit 1
fi

main "$1" "$2"

#######################################################################################################################################
