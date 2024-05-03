##########################################################################################################################################
#
# This script given the live log file intermittently watches it and searches for ERROR matches.
# If found the program appends the error code and messages to a file and rsyncs/pushes this file
# to the server running the alarm watchdog system.
# Here(there) another file takes the reins and triggers the appropriate alarms.
#
##########################################################################################################################################

####################################
#       SYSTEM REQUIREMENTS:
#   assumes a unix operating system installed with:
#   tail, rsync, sshpass
#   Otherwise uses standard installation python libraries.
#   This program requires two other files containing
#   configuration (log_err_cfg.py) and passwords (.nym-pw).
#   The script creates two temporary files containing any error codes/messages
#   one locally, and one in the watchdog
####################################

####################################
#run like: log-errs-fs.py r1234 nn
####################################

import sys
import signal
import subprocess
import os

###################################
status_file = "log-error-status.txt"
###################################

###################################
def main(args):
    ###########
    alarm = False
    ###########

    #if status file exists and has content then...
    if os.path.isfile(status_file) and (os.path.getsize(status_file) > 0):

        # alarm is true
        alarm = True

        #import last line of content...
        err = execcommand("tail -1 %s" % status_file).decode().strip()
        print(err)
        execcommand("echo \"Error! %s\" | mail -s \"Error! %s\" -r vlbi@kartverket.no vlbi@kartverket.no" % (err, err))

    else:
        print("Status file does not exist or is empty. (Both good things.)")
        sys.exit(0)

    ###################

    if alarm:
         execcommand("radio_alarm &")
    else:
        print("No alarms from log file errors.")
        sys.exit(0)

    ####################
    print("-----------------------------------------------------------")


#############################

def execcommand(command):
    print("\"%s\"" % command)
    proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output, stderr = proc.communicate()
    if proc.returncode != 0:
        print("Error executing subprocess command.")
        print("-----------------------------------------------------------")
        sys.exit(0)
    return output


################################

def signalhandler(signal, frame):
    print("\n-----------------------------------------------------------")
    sys.exit(0)


################################

if __name__ == "__main__":
    main(sys.argv)

################################
