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
import time

###########
# CONFIG: #
###########
from error-logger-cfg import *


###################################

#
def main(args):
    ###########
    print("-----------------------------------------------------------")
    print("Welcome")
    print("-----------------------------------------------------------")
    ###########
    debug = False
    #TURNS ON/OFF PRINT STATEMENTS to help better understand the process
    ###########
    #to catch exceptions etc.
    signal.signal(signal.SIGINT, signalhandler)
    ###########
    if len(sys.argv) <= 2:
        print("Please run again using e.g. log-errs-fs.py r1234 nn -d")
        print("-----------------------------------------------------------")
        sys.exit(0)
    #get exp name and telescope:
    exp = args[1].lower()
    tl = args[2].lower()
    ###########
    #created expected log file name:
    logname = "%s%s.log" % (exp, tl)
    log_path = "%s%s" % (hdir, logname)
    #confirm log path
    if not os.path.exists(log_path):
        print("Could not locate %s" % log_path)
        print("-----------------------------------------------------------")
        sys.exit(0)
    ###########
    if len(sys.argv) == 4 and args[3] == "-d":
        debug = True
        print("Debug is ON by '-d' switch")
        print("-----------------------------------------------------------")
    ######
    errnum = 0
    ######
    #INITIALISE EMPTY ERROR FILE
    execcommand("echo -n > ./%s" % errfile)
    ###########

    waitcounter = 0
    t1 = os.path.getmtime(log_path)

    while (1):

        t2 = os.path.getmtime(log_path)
        if t2 > t1:
            waitcounter = 0
            last10lines = execcommand("tail -10 %s" % log_path)
            #could use follow mode but this should be a different thread?? since follow is a bloacking operation, but threads share memory...
            last10lines = last10lines.decode().split("\n")
            if debug:
                print("Most Recent Log File Entries:")
            for ln in last10lines:
                if debug:
                    print(ln)
                ###
                if 'ERROR' in ln:
                    #####
                    err_code = ln.split()[1]
                    err_num = ln.split()[2]
                    err_msg = " ".join(ln.split()[3:])
                    #####
                    if error_code not in non_active_errors:
                        #####
                        errnum = errnum + 1
                        ######
                        with open(errfile, 'a') as f:
                            f.write("ERROR: %s %s %s \n" % (err_code, err_num, err_msg))
            execcommand("sshpass -f './%s' rsync ./%s %s:~/watchdog/%s" % (pwfile, errfile, nym_ip, errfile))
            if debug:
                print("Found %s Error(s)" % errnum)
                print("Pushed Error File to Alarm Handler (%s:~/watchdog/%s)." % (nym_ip, errfile))
        elif t2 == t1:
            if debug:
                print("...waiting...")
            time.sleep(waittime)
            waitcounter += 1
            if debug:
                print("...%s sheep..." % waitcounter)
            ###
            totalwait = ((waittime * waitcounter) // 60)
            if totalwait >= timeout:
                print("No Update to Log File in %s Minute(s). Aborting." % totalwait)
                break

        t1 = t2
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
