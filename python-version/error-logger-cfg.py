###############################
# CONFIG FOR log-errs-good.py #
###############################

###########
errfile = "log-error-status.txt"
###########
#THIS IS THE ACTIVE ERROR STATUS FILE
#created locally, empty, appended errors
#then rsync'd to the watchdog system

###########
nym_ip = ""
###########
#THE USER AND IP ADDRESS OF THE SERVER
#that is running the watchdog alarm system

###########
hdir = "./"
###########
#THIS IS THE DIRECTORY TO THE LOG FILE
#MOST LIKELY  "/usr2/log/"
#FOR DeBUGGIN HAVE: "./"

###########
pwfile = ".nym-pw"
###########
#THIS CONTAINS THE PASSWORD FOR THE SERVER
#that is running the watchdog alarm system
#THIS FILE NEEDS TO EXIST IN SAME DIRECTORY
#FOR THE PROGRAM TO RUN SUCCESSFULLY..

###########
waittime = 30   # SECONDS
###########
#SETS THE TIME BETWEEN RELOADS OF THE LIVE LOG FILE
#shouldn't be too short nor too long..
# Units of SECONDS

###########
timeout = 1     # MINUTES
###########
#THE TIME OUT TIME
#sets how long before the program
#decides the live log is dead
#and aborts
# Units of MINUTES

###########
non_active_errors= ["qo","qk"]
###########
#THESE ARE THE ERRORS THAT WILL !NOT! TRIGGER THE WATCHDOG PROGRAMMES
#FOR THE VERY LONG, FULL LIST SEE: https://github.com/vni-inc/fs/blob/main/control/fserr.ctl
#some discresion is needed in deciding what to include & what can we ignore...
