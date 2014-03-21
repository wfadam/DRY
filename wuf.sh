#!/bin/bash
set -u

# The script is for program setup
# Date: 11:04pm, 7/31/2013, Kunshan, China
# Date: 05:04pm, 12/02/2013, Shanghai, China

function errOut {
	echo "$@"
	exit 1
}

function getFlow {
	if [ "$1" == "Debug" ]; then
		echo "$1"
	else
		echo "$1" | tr 'a-z' 'A-Z'
	fi
}

function testEnv {
	if [[ `kwho` == *"not used"* ]]; then
		echo "Kei System Software is NOT running"
		return 1
	fi
}

function startEnv {
	rm -rf .atfsutu
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
	ksplogend  &>/dev/null
	kerrlogend &>/dev/null
	if [ -d "datalogs" ]; then
		ksplogstart datalogs "$flow"_"$pro"_"$time"
		kerrlogstart datalogs ."$flow"_"$pro"_"$time" &>/dev/null
	else
		ksplogstart . "$flow"_"$pro"_"$time"
		kerrlogstart . ."$flow"_"$pro"_"$time" &>/dev/null
	fi

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

################ Start Execution ##################
testEnv || startEnv

# Parse program name
wildName=`basename $PWD`*.class
classFile=`basename javaapi/${wildName}`
proName=`basename "$classFile" .class`	#another method ${classFile%.*}

# Verify program package
[    -f javaapi/"$classFile"             ] || errOut "Missing javaapi/ or class file !!"
[ 1 -eq `ls javaapi/${wildName} | wc -w` ] || errOut "More than one main classes are found : " `ls javaapi/${wildName}`
[    -f "$proName".soc                   ] || errOut "Missing socket file : "$proName".soc !!"

# Save current Kei setting
wu s

# Setup
flowName="FH"
[ $# -ne "0" ] && flowName=`getFlow "$1"`

setDlog "$flowName" "$proName"
setSysVar &>/dev/null

kcd $PWD &>/dev/null
kproset javaapi."$proName".class &>/dev/null
setSoc "$proName" &>/dev/null

# Start testing
echo -n "Are you sure to start testing ? (y/n) : "
read yn
if [ $yn == 'y' ]; then
	kproreset && kclear && kprostart &
	sleep 1
	echo "Test program is started ... "
fi

####################### END #######################
