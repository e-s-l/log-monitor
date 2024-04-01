#!/usr/bin/env python
from string import *
from datetime import *
import sys
import signal
import subprocess

def main(args):
	signal.signal(signal.SIGINT, signal_handler)
	
	knownerrors = []

	command = "ls /usr2/log/*.log"

	logfilelist = execcommand(command)
	logfilelist = strip(logfilelist)
	logfilelist = split(logfilelist, "\n")
	#print logfilelist
	
	for f in logfilelist:
		print "Processing file %s" % f
		command = "grep ERROR %s" % f
		errorlist = execcommand(command)
		errorlist = strip(errorlist)
		errorlist = split(errorlist, "\n")
		for err in errorlist:
			if "?" in err:
				err = split(err, "?")[1]
				err = strip(err)
				err = err + "\n"
				if err not in knownerrors:
					knownerrors.append(err)
					#print "New error found: %s" % err

	f = open("/usr2/oper/fsns_known_err", 'w')
	f.writelines(knownerrors)
	f.close()
	
	sys.exit(0)
	
def execcommand(command):
	#print "  > %s" % command
        proc = subprocess.Popen(command, shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output,stderr = proc.communicate()
        return output
        status = proc.poll()
	"""
	proc = subprocess.Popen(command, shell=True,stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	while True:
		output = proc.stdout.readline()
		if output == '' and proc.poll() is not None:
			break
		if output:
			print output.strip()
	rc = proc.poll()
	"""

def signal_handler(signal, frame):
	print
	print "-----------------------------------------------------------"
        print "Ctrl+C pressed, cancelling..."
	print "-----------------------------------------------------------"
        sys.exit(0)

if __name__=="__main__":
        main(sys.argv)

