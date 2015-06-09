#!/bin/bash
set -u

# The script is for program setup
# Author: Feng WU
# Rev 0.10	11:04pm, 7/31/2013
# Rev 0.20	05:04pm, 12/02/2013
# Rev 0.30	22:03pm, 10/02/2014
# Rev 0.31	12:30pm, 12/30/2014
#		Can run multiple flows in order

function errOut {
	>&2 echo -e "\nStops due to :\n\t$@"
	exit 1
}

function getFlow {
	flowName="FH"
	if [ "$1" == "Debug" ]; then
		flowName="$1"
	else
		flowName=`echo "$1" | tr 'a-z' 'A-Z'`
	fi
}

function isOffline {
	[[ `kwho` == *"not used"* ]]
}

function isInUse {
	local currPWD=`kpwd  | tail -n 1`
	local currSTAT=`kstat  | tail -n 1`
	if  [ "$currSTAT" == *"TESTING"* ] || [ "$currPWD" != "$PWD" ]; then
		echo "============================== TESTER IN USE =============================="
		echo "Program : $currPWD"
		echo "status  : $currSTAT"
		echo "==========================================================================="
	fi
	[[ "$currSTAT" == *"TESTING"* ]]
}

function startEnv {
	rm -rf .atfsutu/
	echo -n "Starting "
	startk >/dev/null && (utu_cpnl &>/dev/null& utu_tt &>/dev/null&)
}

function setDlog {
	local cnt="$1"
	local time=`date +%m%d%H%M`

	local dir="./"
	if [ -d "datalogs" ]; then
		dir="datalogs/"
	fi

	rm -f "$dir".*{err,RTE}.txt
	ksplogend &>/dev/null
	kerrlogend &>/dev/null

	ksplogstart   "$dir"   "$flowName"_"$cnt"_"$proName"_"$time"
	kerrlogstart  "$dir"  ."$flowName"_"$cnt"_"$proName"_"$time" &>/dev/null

	klog --dc on &>/dev/null
}

function setSoc {
	local sockname="$1"
	local socktype=$(file -ib $sockname)
	if [[ $socktype == *gzip* ]]; then
		kselectsocket $sockname
	else
		kselectsocket `cat $sockname`
	fi
}

function setSysVar {
	ksystemvariable --add ECOTS_SD_DATALOGDISP ON \
		--add ECOTS_SD_STEP "$flowName" \
		--add ECOTS_SD_RESCREEN 0 \
	&> /dev/null
}

function readyToStart {
	pwd
	echo -n "__100%__ sure to start testing ? (y/n) : "
	read yn
	[ 'y' == $yn ]
}

function getProName {
	verify "$PWD"
	local baseName=`basename "$PWD"`
	local socFile=`ls $baseName*.soc`
	[[ 1 -eq `echo "$socFile" | wc -w` ]] || errOut "less/more than one .soc file found \n$socFile"

	verify "$socFile"
	proName=${socFile%.*}
	[ -f javaapi/"$proName".class  ] || errOut "missing javaapi/ or $proName.class !!"
}

function verify {
	local inStr="$1"
	case "$inStr" in
		*\ * )
			errOut "SPACE is NOT allowed in \"$inStr\"" ;;
	esac
}

function setCpnl {
	kcd "$PWD"                       &>/dev/null
	kproset javaapi."$proName".class &>/dev/null
	setSoc "$proName".soc            &>/dev/null
}

function clearPro {
	ksetuserpro --clear &> /dev/null
	kproreset && kclear
}

function startPro {
	clearPro
	kprostart & local pid=$!
	echo "Test program is started ... "
	wait $pid
}

function preCheck {
	isOffline && startEnv 
	isInUse && errOut "tester is running a program right now"
	readyToStart || exit 1
	wu s	# save current session
}

function flowLoop {
	local cnt=1;
	for fl in "$@";
	do
		getFlow "$fl"
		setSysVar
		setDlog "$cnt"
		startPro || errOut "test program is halted by command or error"
		((cnt++))
	done;
}

function usage {
cat << EOF
Usage:
    $0          : run FH as default
    $0 CC SH FH : run CC, SH, FH in order 
EOF
exit 1;
}

################ Start Execution ##################
case "$1" in
	-h ) usage ;; 
esac
preCheck
getProName
setCpnl
flowLoop "$@" &

####################### EOF #######################

