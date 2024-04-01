
#
#draft python script to scp a given log file from the field system computer
#then to monitor ths log file for the occurence of errors
#then if an error is found to send an error code string to the watchdog
#
 
from string import *
from datetime import *
import sys
import signal
import subprocess


############################

def main(args):

    fileName = getLogFileName()
    print(fileName)

    ##################################
    sourceFile = "/usr2/log/" + fileName + ".log"
    monitorFile = "monitored.log"
    destinationFilePath = "/oper/watchdog/log/" + monitorFile
    print(f"I am going to scp from {sourceFile} (on the fs) to {destinationFilePath} (on NyMitra)")

    cltCommand = "scp oper@10.0.109.39:../log/test.log ./watchdog/log/monitored.log" #ip is 10.0.109.38
    pw = "NyalesunD"

    cltCommand="pwd"

    ####see below function of rubens###
    proc = subprocess.Popen(cltCommand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output, stderr = proc.communicate()
    print(output)
    ####

    proc = subprocess.Popen(cltCommand, stdin.PIPE)
    proc.stdin.write(pw)

def getLogFileName():

    print ("-----------------------------------------------------------")
    print ("Welcome")
    print ("-----------------------------------------------------------")
    print("***FOR Ns ONLY***")
    print ("Please input below the name of the log file to be monitored: \n")
    fileName = input()
    print ("-----------------------------------------------------------")

    return fileName

########################################################
def execcommand(command):
	#print "  > %s" % command
        proc = subprocess.Popen(command, shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output,stderr = proc.communicate()
        return output
        status = proc.poll()

########################################################
if __name__=="__main__":
    main(sys.argv)

