from multiprocessing import Pool
from multiprocessing.dummy import Pool as ThreadPool 
import subprocess
import pexpect
import sys
import os

machines = ['es2', 'es10', 'es13', 'es14', 'es18', 'es19', 'es21', 'es22', 'es23', 'es24', 'es32', 'es33', 'es36']

def login(host):
	child = pexpect.spawn ('ssh root@'+host, timeout=1)
	i = child.expect (['yes','assword'])
	if i==0: # first time login
		child.sendline ('yes')
		child.expect ('assword')
		child.sendline ('*')
	elif i==1:
		child.sendline ('*')
	child.expect ('Last login')
	return child

def doSomething(host, child):
	rlst = []
	child.sendline ('kpwd | tail -n 1')
	#child.expect (['No.*', '/home/.*'])
	child.expect (['kpwd:.*', '/home/.*'])
	rlst.append( host + " -> " + child.after[:-2] )	# [:-2] avoids line feed

	child.sendline ('kstat | tail -n 1')
	child.expect (['No.*', 'Site.*'])
	rlst.append( host + " -> " + child.after[:-2] )

	child.sendline ('wu t')
	child.expect (['PAST.*', 'Command.*', 'Kei.*', 'cannot'])
	rlst.append( host + " -> " + str(child.after.split(' ')[1:2]))

	print "\n".join( rlst ) + "\n"

def check(host):
	if 0==isAlive(host):
		child = login( host )
		#child.logfile = sys.stdout
		doSomething(host, child )
		child.close()
	else:
		print host, "is down!\n"

def isAlive(host):
	return  subprocess.call(["ping","-c1","-W1",host], stdout=subprocess.PIPE, stderr=subprocess.PIPE)


#check('es18')
##Single Thread
#map( check, machines )
pool = ThreadPool() # Multi Threads
#pool = Pool() # Multi Processes
pool.map( check, machines )
pool.close()
pool.join()
