#!/bin/bash

# The script is for program config saving/recovering
# Author: Feng WU
# Rev 0.1	11:04pm, 7/31/2013, Kunshan, China
# Rev 0.2	05:04pm, 12/02/2013, Shanghai, China
# Rev 0.3	01:08am, 10/03/2014, Kunshan, China
#		Refactored


readonly conf=.wuconf

function saveToFile {
	local currKPWD=`kpwd | tail -n 1`
	[ "$currKPWD" == "$PWD" ] && return 0

	local currSESN=`kwho | awk '/since/{print $1}'`
	local currPRO=`kproset | tail -n 1`
	local currSOC=`kselectsocket | tail -n 1`
	local currLogFile=`ksplogstatus | awk '/\<Sys\>/{print $5}'`
	local logDir=`dirname $currLogFile`
	local baseLogName=`basename $currLogFile`
	local flow=`ksystemvariable | awk '/ECOTS_SD_STEP/{print $2}'`

	>"$conf"
	append "ksystemvariable --add ECOTS_SD_STEP $flow" 
	append "kcd $currKPWD"
	append "kproset $currPRO"
	append "kselectsocket $currSOC"
	append "ksplogstart $logDir ${baseLogName%-$currSESN*}"
}

function append {
	echo "$@" >> "$conf"
}

function errOut {
	#must begin with "Command" for calling from poll.py 
	echo -e "\nCommand exits due to :\n\t$@"
	exit 1
}

function usage {
	local self=`basename $0`
	echo "Usage:"
	echo "	$self s -> Save current settings"
	echo "	$self r -> Recover saved settings"
	echo "	$self t -> Check time stamp of current datalogs"
	exit 1
}

function dispTime {
	local fname=`ksplogstatus | tail -n -1 | awk '{print $5}'`
	[ -f $fname ] || errOut "$currLogFile cannot be found"
	local last=`date +%s -r $fname`
	local curr=`date +%s`
	local pastime=$((curr-last))
	local pastHrs=`expr $pastime \/ 3600 `
	local pastMin=`expr \( $pastime \/ 60 \) \% 60 `
	local pastSec=`expr $pastime \% 60 `
	echo PAST $pastHrs"h"$pastMin"m"$pastSec"s" $fname
}

function testEnv {
	kpwd &> /dev/null
}

function recover {
	[ -f "$conf" ] || errOut "$conf cannot be found"
	source "$conf"
}

############################### Execution starts ##################################
[ $# -gt 0 ] || usage 
testEnv || exit 1

case "$1" in
	s ) saveToFile ;; 
	r ) recover    ;; 
	t ) dispTime   ;; 
	* ) usage      ;; 
esac
