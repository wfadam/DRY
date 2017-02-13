#!/bin/env bash
set -u

#  DESCRIPTION:  a bash script that packages up Advantest Test Programs for program release.
#
#  USAGE: ./release.sh
#    - be sure to execute this script in the same directory as the tXXXXXX/
#
#  RELEASE NOTES:
#	00 (01/16/12): Initial Release
#	22 (02/08/17): [FW] Refactor to unify the logic for both T73 and T31
#	23 (02/13/17): [FW] Bugfix to narrow down search region in source code for 'defly|4db'

function errOut {
        echo -e "${FUNCNAME[0]} : \n\t$1\n" 1>&2;
        exit 1;
}

readonly socFile=`find . -mindepth 2 -maxdepth 2 -name "*.soc"`;
readonly proName=`basename "$socFile" | sed 's/.soc//g'`;
readonly tXXXXXX=`dirname "$socFile"| xargs basename`;
readonly zipDir="$PWD";
readonly tpDir="$zipDir"_tp;

function del {
	for f in "$@"; do
		find . -name "$f" -exec rm \-rf {} \;
	done;
}

function mustDelList {
cat << EOF
	*.java
	*.prep
	*.asc
	*.c
	*.h
	*.SYS
	.metadata
	workspace
	bin
EOF
}

function checkSoc {
	files=($socFile);
	[[ "${#files[@]}" == 1 ]] || errOut "Need one .soc file in $PWD/tXXXXXX/\n$socFile";
}

function checkBalance {
	isBad=0;
	xfr="$1";
	shift;
	for file in "$@"; do
		eval ls "$xfr" &> /dev/null;
		[[ $? == 0 ]] && continue;
		isBad=$((isBad+1));
		echo -e "$file"
	done;
	[[ $isBad == 0 ]] || errOut "Forgot to compile above $isBad source files\n  OR\n\tClean the unused sources by command\n\trelease | xargs rm";
}

function checkProRev {
	ls  "$tXXXXXX"/javaapi/"$proName".class &> /dev/null;
	[[ $? == 0 ]] || errOut "Can not find $tXXXXXX/javaapi/$proName.class\n\tvia\n\t$socFile";
}

function checkJava {
	checkBalance '${file/.java/.class}' \
	`find "$tXXXXXX"/javaapi -name "*.java"`;
}

function checkPattern {
	checkBalance '${file/.asc/.mpa}' \
	`find "$tXXXXXX" -name "*.asc" | xargs -d '\n' grep -l '^MPAT '`;
}

function genTpZip {
	tmpDir=$(mktemp -d -p /tmp);
	cp -rp "$zipDir"/"$tXXXXXX" "$tmpDir";

	cd "$tmpDir" && del `mustDelList` &> /dev/null;
	tar czf "$proName".tgz "$tXXXXXX";
	rm -f "$tpDir".zip;
	zip -ry "$tpDir".zip "$proName".tgz &> /dev/null;
	rm -rf "$tmpDir";
	cd "$zipDir" &> /dev/null
}

function genSrcZip {
	make clean -C "$zipDir"/"$tXXXXXX" &> /dev/null;
	cd `dirname "$zipDir"` && rm -f "$zipDir".zip && zip -ry "$zipDir".zip `basename "$zipDir"` &> /dev/null;
	cd "$zipDir" &> /dev/null
}

function checkDefly {
	LC_ALL=C find "$tXXXXXX" -iregex '.*.\(java\|asc\)'  \
	| xargs -d '\n' grep -Pirn --color '(\/\/|;).*(defly|4db)' \
	&& errOut "Forgot to remove the temporary code ?";
}

function run {
	i=1;
	total="$#";
	for step in "$@"; do
		echo "$i/$total: $step" 1>&2;
		eval "$step";
		i=$((i+1));
	done;
}

##### Execution starts here #####
run \
checkSoc \
checkProRev \
checkDefly \
checkJava \
checkPattern \
genTpZip \
genSrcZip \

##### EOF #####
