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

	USER="oper"
	SERVER="10.0.109.38"

	if [ "$1" == "nn" ]
	then
		echo "north FS"
	elif [ "$1" == "ns" ]
	then
		echo "south FS"
	fi

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
    # Assign positional parameters to variables (for clarity):
	EXP=$1
	TL=$2
	#
	get_config "$TL"
	#
	#File names:
	EXP_LOG="${EXP}${TL}.log"
	echo "Expect log file: ${EXP_LOG}" ; echo
	LOG_FILE="/usr2/log/$EXP_LOG"

	#Log File Location...
	#Status File Location...

	if ssh "$USER@$SERVER" [ -f "$LOG_FILE" ]
	then
		# empty (or create) the status file
		echo -n > "$STATUS_FILE"
		# start tailing the log file:

		FIND_ERRORS="$(ssh "$USER@$SERVER" "timeout $TIMEOUT_TIME tail -f "$LOG_FILE" | egrep "ERROR"")"

        if "$FIND_ERRORS"
        then
            echo "Monitoring Log File for errors"
            while read -r line
            do
                if ! grep -Fxq "$line" deactivated_errors.txt       # grep -Fxq ...
                then                                                # check in list of deactivated errors.
                    "$line">> "$STATUS_FILE"
                    ###
					if $DEBUG; then echo; echo "ERROR!"; echo; fi
					###
                fi
            done < <("$FIND_ERRORS")
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
	else
		echo "Log file $LOG_FILE not found!"
		exit 2
	fi

    ###
	finisher
	###
}

#######################################################################################################################################

DEBUG=false

#CHECK POSITIONAL PARAMETERS:
if [ "$#" -eq 3 ] && [ "$3" == "-d" ]		# recall: $# = len(#@)
then
	echo "Debug Mode: ON"
	DEBUG=true
elif ! [ $# = 2 ]
then
	echo "This script it to be run like: $0 EXP TL"
	exit 1
fi

if ! ([ "$2" == "nn" ] || [ "$2" == "ns" ])	# hmmm
then
	echo "Are you not using NN or NS ?!"
	exit 1
fi

main "$1" "$2"

#######################################################################################################################################


