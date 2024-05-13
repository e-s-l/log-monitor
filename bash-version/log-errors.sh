#!/bin/bash

#######################################################################################################################################
#
# This script given the live log file intermittently watches it and searches for ERROR matches.
# If found the program appends the error code and messages to a file
#
# Designed assuming that the alarm on the other end will be triggered if the STATUS_FILE is non-empty
#
#######################################################################################################################################

#FUNCTIONS:

get_config() {
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

finisher() {
	###
	if $DEBUG; then echo; echo "finisher"; echo; fi
	###
	# properly kill the stream and tail processes
	kill "$(pgrep -f "$FIND_ERRORS")" &>/dev/null	# & means...
}

# catch signals and close correctly
trap "finisher; exit 0" SIGINT SIGTERM

main() {
	###
	if $DEBUG; then echo; echo "main"; echo; fi
	###
	#
	get_config
	#
    # Assign positional parameters to variables (for clarity):
	EXP=$1
	TL=$2
	#File names:
	EXP_LOG="${EXP}${TL}.log"
	echo "Expect log file: ${EXP_LOG}"

	#Log File Location...
	#Status File Location...

	if ! [ -f "$EXP_LOG" ]
	then
		echo "Log file $EXP_LOG not found!"
		exit 2
	else
		# empty (or create) the status file
		echo -n > "$STATUS_FILE"

		# start tailing the log file:
        if FIND_ERRORS="$(ssh oper@host "timeout TIMEOUT_TIME tail -f "$EXP_LOG" | egrep "ERROR">> "$STATUS_FILE"")"    # ooph
        then
            echo "Monitoring Log File for errors"
        else
            # catch errors...
            exit_code=$?
            if [ "$exit_code" -eq 124 ]
            then
                echo "Timeout!"
                echo "Warning. Log file timed out.">> "$STATUS_FILE"
                finisher
            fi
        fi
	fi

    ###
	finisher
	###
}

#######################################################################################################################################

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

#######################################################################################################################################


