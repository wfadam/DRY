#!/bin/bash
set -u

# The script is for saving/recovering current program setting 
# Date: 10:38pm, 7/31/2013, Kunshan, China
# Author: Feng WU

conf=.wuconf

function help {
	self=`basename $0`
	echo "Usage:"
	echo "	$self s -> Save current settings"
	echo "	$self r -> Recover saved settings"
	echo "	$self e -> Erase saved settings"
	echo "	$self t -> Check time stamp of current datalogs"
}

function testEnv {
	kpwd &> /dev/null
	if [[ $? != "0" ]]; then
		echo Kei System Software is NOT running
		exit 1
	fi
}

function saveEssential() {
	cmd="$1"
	if [ "$cmd" == "kcd" ];then
		echo "$cmd" `kpwd | tail -n 1` >> $conf
	else
		echo "$cmd" `"$cmd" | tail -n 1` >> $conf
	fi
}

function saveSysVar() {
	var="$1"
	rslt=`ksystemvariable | grep "$var" -A 1`
	key_value=($rslt)
	if [ "${#key_value[@]}" != "0" ]; then
		echo ksystemvariable --add "${key_value[0]}" "${key_value[1]}">> $conf
	fi
}

function saveLogSetting() {
	logfile=`ksplogstatus | awk -F '|' 'END{print $3}'`
	if [ "$logfile" != "" ];then
		logdir=`dirname $logfile`
		logbase=`basename $logfile | sed 's/\-[[:alpha:]]\+_1\-.*txt//g'`
		echo ksplogstart $logdir $logbase >> $conf
	fi
}

#---------------------------------------------------------------------------------------

[ $# -eq "0" ] && help && exit 1
testEnv || exit 1

if [[ $1 == 's' ]]; then
	if [ -f $conf ]; then
		echo "		Skip saving as file exists (T_T)"
	else
		>"$conf"
	
		saveEssential kcd
		saveEssential kproset
		saveEssential kselectsocket
	
		saveSysVar ECOTS_SD_STEP
		saveSysVar ECOTS_SD_DATALOGDISP
		
		saveLogSetting
		
		echo "		Saved current program setting (^_^)"
	fi

elif [[ $1 == 'r' ]]; then
	if [ -f $conf ]; then
		echo "Settings to be recovered:"
		echo "    " `awk '/kcd/{print $2}' $conf`
		echo "    " `awk '/kproset/{print $2}' $conf`

		echo -n "Are you sure to proceed ? (y/n) : "
		read yn
		[[ $yn == 'y' ]] && source $conf && rm -f $conf > /dev/null || exit
	else
		echo "		NOT saved yet, please (Orz)"
	fi

elif [[ $1 == 'e' ]]; then
	echo -n "Are you sure to erase saved setting ? (y/n) : "
	read yn
	[[ $yn == 'y' ]] && rm -f $conf || exit

elif [[ $1 == 't' ]]; then
	ksplogstatus | awk -F '|'  'END{print $3}' | xargs ls -l
else
	echo "Wrong arguments !"
	help
fi
####################### END #######################
