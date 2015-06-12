#!/bin/bash
set -u

# The script is for program setup
# Author: Feng WU
# Rev 0.10	11:04pm, 7/31/2013
# Rev 0.20	05:04pm, 12/02/2013
# Rev 0.30	22:03pm, 10/02/2014
# Rev 0.31	12:30pm, 12/30/2014
#		Can run multiple flows in order
# Rev 0.32	01:47pm, 06/09/2015
#		Can run flows from the released tp.zip
# Rev 0.33	02:15pm, 06/12/2015
#		Support legacy and new program names ( before , 1Z and beyond )

readonly sep='af'
readonly baseEx='[tw][a-z0-9]{6}'
readonly oldEx='[a-z0-9]{2}_[a-z0-9]{2}(en[a-z0-9])?'
readonly newEx='[a-z0-9]{4}(en[a-z0-9])?_[a-z0-9]{4}'
readonly proEx='\<'${baseEx}${sep}'('${oldEx}'|'${newEx}')\>'

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
		[[ "$flowName" =~ "^[A-Z]{2}$" ]] || errOut "Wrong flow name $flowName"
	fi
	echo Identified $flowName
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

function isNameValid {
	[[ "$1" =~ "$proEx" ]]
}

function getProName {
	verify "$PWD"
	local bName=`basename "$PWD"`
	local socFile=`ls $bName*.soc`
	[[ 1 -eq `echo "$socFile" | wc -w` ]] || errOut "less/more than one .soc file found \n$socFile"
	verify "$socFile"
	proName=${socFile%.*}
	isNameValid "$proName" || errOut "illegal program name $proName"
	[ -f javaapi/"$proName".class  ] || errOut "missing javaapi/ or $proName.class !!"
	echo -e "\nAbout to execute $PWD/javaapi/"$proName".class\n"
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
	while [[ $# > 0 ]]
	do
	case "$1" in
		-f )
			shift		# skip the item after "-f"
			shift ;;	# prepare for the next item for check
		*)
			getFlow "$1"
			setSysVar
			setDlog "$cnt"
			startPro || errOut "test program is halted by command or error"
			((cnt++))
			shift ;;
		esac
	done;
}

function unzipTp {
	local zipName="$1"
	[[ "$zipName" =~ ".*_tp.zip$" ]] || errOut "expecting *_tp.zip but not $zipName"

	proName=`unzip -t "$zipName" | egrep -o "${proEx}.tgz" | egrep -o "${proEx}"`
	isNameValid "$proName" || errOut "illegal program name $proName in *_tp.zip"

	unzip -p "$zipName" | tar xzf - 

	readonly baseName=`echo "$proName" | egrep -o "${baseEx}"`
	readonly binDir="$PWD"/"$baseName"
}

function usage {
cat << EOF
Usage:
  # run FH as default
      \$ $0         			
  
  # run multiple flows in order
      \$ $0 SH fh			
  
  # run multiple flows on binary tp.zip
      \$ $0 sh fh -f *_tp.zip	

  # Program name should comply with regex
	$proEx

  # Examples of valid/invalid programs
	txxxxxxafxx_xx		<- valid
	wxxxxxxafxx_xx		<- valid
	txxxxxxafxx_xxenx	<- valid
	txxxxxxafxxxx_768a	<- valid
	txxxxxxafxxxxenx_768a	<- valid
	txxxxxxfhxx_xx		<- invalid
    Legend:
        x: a digit or lowercase letter

EOF
exit 0;
}

function parseArg {
	while [[ $# > 0 ]]
	do
	case "$1" in
		-h )
			usage ;; 
		-f )	# run program from binary release
			shift
			unzipTp "$1" 
			cd "$binDir" ;;
		* )
			shift ;;
	esac
	done
}

################ Start Execution ##################

parseArg $@
getProName
preCheck
setCpnl
flowLoop $@ &

####################### EOF #######################

