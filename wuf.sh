#!/bin/bash
set -u

function errOut {
	echo
	echo "Command exits due to $@"
	echo
	exit 1
}

function getFlow {
	if [ "$1" == "Debug" ]; then
		echo "$1"
	else
		echo "$1" | tr 'a-z' 'A-Z'
	fi
}

function isOffline {
	[[ `kwho` == *"not used"* ]]
}

function isInUse {
	currPWD=`kpwd  | tail -n 1`
	currSTAT=`kstat  | tail -n 1`
	if  [ "$currSTAT" == *"TESTING"* ] || [ "$currPWD" != `pwd` ]; then
		echo
		echo "============================== TESTER IN USE =============================="
		echo "  $currPWD"
		echo "  $currSTAT"
		echo "==========================================================================="
		echo
	fi
	[[ "$currSTAT" == *"TESTING"* ]]
}

function startEnv {
	rm -rf .atfsutu/
	rm -rf ../.metadata/
	echo -n "Starting "
	startk >/dev/null && (utu_cpnl &>/dev/null& utu_tt &>/dev/null&)
}

function recover {
	yes | wu r >/dev/null
	echo
}

function setDlog {
	flow="$1"
	pro="$2"
	time=`date +%m%d%H%M`

	dir="./"
	if [ -d "datalogs" ]; then
		dir="datalogs/"
	fi

	rm -f "$dir".*{err,RTE}.txt
	ksplogend &>/dev/null
	kerrlogend &>/dev/null

	ksplogstart  "$dir" "$flow"_"$pro"_"$time"
	kerrlogstart "$dir" ."$flow"_"$pro"_"$time" &>/dev/null

	klog --dc on &>/dev/null
}

function setSoc {
	sockname="$1".soc
	socktype=$(file -ib $sockname)
	if [[ $socktype == *gzip* ]]; then
		kselectsocket $sockname
	else
		kselectsocket `cat $sockname`
	fi
}

function setSysVar {
	ksystemvariable --add ECOTS_SD_DATALOGDISP ON \
		--add ECOTS_SD_STEP "$flowName" \
		--add ECOTS_SD_RESCREEN 0
}

function readyToStart {
	pwd
	echo -n "__100%__ sure to start testing ? (y/n) : "
	read yn
	[ 'y' == $yn ]
}

function verifyProgram {
	# Verify program package
	[ -f javaapi/"$classFile"                ] || errOut "missing javaapi/ or class file !!"
	[ 1 -eq `ls javaapi/${wildName} | wc -w` ] || errOut "more than one entry classes are found : " `ls javaapi/${wildName}`
	[ -f "$proName".soc                      ] || errOut "missing socket file : "$proName".soc !!"
}


################ Start Execution ##################
isOffline && startEnv 
isInUse && errOut "program is testing"

readyToStart
if [ $? -eq 0 ]; then
	
	# Parse Information
	wildName=`basename $PWD`*.class
	classFile=`basename javaapi/${wildName}`
	proName=`basename "$classFile" .class`	#another method ${classFile%.*}
	
	verifyProgram
	wu s	# save current session
	
	flowName="FH"
	[ $# -ne "0" ] && flowName=`getFlow "$1"`
	
	setDlog "$flowName" "$proName"
	setSysVar &>/dev/null
	
	kcd $PWD &>/dev/null
	kproset javaapi."$proName".class &>/dev/null
	setSoc "$proName" &>/dev/null
	
	kproreset && kclear && kprostart &
	sleep 1
	echo "Test program is started ... "
fi

####################### END #######################

