from multiprocessing import Pool
from multiprocessing.dummy import Pool as ThreadPool 
import pexpect
import sys

machines = ['es2', 'es10', 'es13', 'es14', 'es18', 'es19', 'es21', 'es22', 'es23', 'es24' ]

def login(host):
	child = pexpect.spawn ('ssh root@'+host)
	i = child.expect (['yes','assword'])
	if i==0:
		child.sendline ('yes')
		child.expect ('assword')
		child.sendline ('*********')
	elif i==1:
		child.sendline ('*********')
	child.expect ('Last login')
	return child

def doSomething(m, child):
	rlst = []
	child.sendline ('kpwd | tail -n 1')
	child.expect (['No.*', '/home/.*'])
	rlst.append( m + " -> " + child.after[:-2] )	# [:-2] avoids line feed

	child.sendline ('kstat | tail -n 1')
	child.expect (['No.*', 'Site.*'])
	rlst.append( m + " -> " + child.after[:-2] )

	child.sendline ('wu t')
	child.expect (['PAST.*', 'Command.*', 'Kei.*'])
	rlst.append( m + " -> " + child.after[:-2] )

	print "\n".join( rlst ) + "\n"

def check(m):
	child = login( m )
	#child.logfile = sys.stdout
	doSomething(m, child )
	child.close()

#check('es18')
##Single Thread
#map( check, machines )

pool = ThreadPool() # Multi Threads
#pool = Pool() # Multi Processes
pool.map( check, machines )
pool.close()
pool.join()


#ssh -fN -Des21:8088 kei@10.195.226.215

