#!/bin/bash
selfname=`basename $0`

basepro=`basename $PWD`
ls $basepro*.asc
if [[ $? -ne "0" ]]; then
	echo
	echo "Socket source file(.asc) can not be found"
	echo
	exit
fi

function help {
	echo "Usage:"
	echo "	$selfname 1 3 4 2 "
	echo "Note: argument is site dut#"
}


if [[ $1 == "-h" ]]; then
	help
	exit
fi


site2sys=(`awk '/SITE1\>/{print $5 , $1}' $basepro*.asc  | sed 's/\(SYSTEM\)*DUT//g' | sort -n | awk '{print $2}'`)

echo ${site2sys[@]}


ksdut --disable-all > /dev/null
args=""
for dn in $*
do
	if [[ $args == "" ]]; then
		args=${site2sys[$dn-1]}
	else	
		args=$args,${site2sys[$dn-1]}
	fi
done
ksdut --enable $args
if [[ $? -ne "0" ]]; then
	ksdut --enable-all
fi
