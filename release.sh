#!/bin/env bash
set -u
#
#  DESCRIPTION:  a bash script that packages up for program release.
#
#  USAGE: ./release.sh
#    - be sure to execute this script in the same directory as the tXXXXXX/
#
#  RELEASE NOTES:
#	22 (01/24/17): [FW] Refactor to unify the logic for both T73 and T31 

function errOut {
        echo -e "${FUNCNAME[0]} : \n\t$1\n" 1>&2
        exit 1
}

readonly socFile=`find . -mindepth 2 -maxdepth 2 -name "*.soc"`
readonly proName=`basename "$socFile" | sed 's/.soc//g'`
readonly tXXXXXX=`dirname "$socFile"| xargs basename`
readonly zipDir="$PWD"
readonly tpDir="$zipDir"_tp

function del {
	for f in "$@"; 
	do
		find . -name "$f" -exec rm \-rf {} \;
	done
}

function mustDelList {
cat << EOF
	*.java
	*.prep
	*.asc
	*.c
	*.h
	.metadata
	workspace
	bin
EOF
}

function checkSoc {
	files=($socFile)
	[[ "${#files[@]}" == 1 ]] || errOut "Need one .soc file in $PWD/tXXXXXX/\n$socFile"
}

#function checkBalance {
#	xfr="$1"
#	shift
#
#	for file in "$@";
#	do
#		eval ls "$xfr" &> /dev/null \
#		|| errOut "Missing the binary of $file\n\tOR\n\t$file is NEVER in use"
#	done;
#}

function checkBalance {
	xfr="$1";
	shift;
	isBad=0;
	for file in "$@";
	do
		eval ls "$xfr" &> /dev/null;
		if [ $? != 0 ] ;
		then
			isBad=$((isBad+1));
			echo "Missing the binary of $file"
		fi

	done;
	[[ $isBad == 0 ]] || errOut "Found $isBad files missing the binaries"
}

function checkProRev {
	eval 'ls  "$tXXXXXX"/javaapi/"$proName".class &> /dev/null'
	[[ $? == 0 ]] || errOut "Can not find $tXXXXXX/javaapi/$proName.class\n\tvia\n\t$socFile"
}

function checkJava {
	checkBalance \
	'${file/.java/.class}' \
	`find "$tXXXXXX"/javaapi -name "*.java"`
}

function checkPattern {
	checkBalance \
	'${file/.asc/.mpa}' \
	`find "$tXXXXXX" -name "*.asc" | xargs grep -l '^MPAT '`
}

function genTpZip {
	tmpDir=$(mktemp -d -p /dev/shm)
	cp -rp "$zipDir"/"$tXXXXXX" "$tmpDir"

	cd "$tmpDir" && del `mustDelList` &> /dev/null
	tar czf "$proName".tgz "$tXXXXXX"
	zip -ry "$tpDir".zip "$proName".tgz &> /dev/null
	rm -rf "$tmpDir"
}

function genSrcZip {
	make clean -C "$zipDir"/"$tXXXXXX" &> /dev/null
	zip -ry "$zipDir".zip "$zipDir" &> /dev/null
}

function checkDefly {
	LC_ALL=C find "$tXXXXXX" -iregex '.*.\(java\|asc\)'  |\
	xargs grep -Pirn --color 'defly|4db' && errOut "Should remove the debugging code"
}

function run {
	i=1;
	total="$#";
	for step in "$@";
	do
		echo "$i/$total: $step"
		eval "$step"
		i=$((i+1));
	done;
}

function procedure {
cat << EOF
	checkSoc
	checkDefly
	checkProRev
	checkJava
	checkPattern
	genTpZip
	genSrcZip
EOF
}

##### Execution starts here #####
run `procedure`;

##### EOF #####
