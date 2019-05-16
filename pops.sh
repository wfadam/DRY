#!/bin/bash

set -u

function errOut {
        echo -e "${FUNCNAME[0]} : \n\t$1\n" 1>&2;
        exit 1;
}

[[ $# -lt 3 ]] && errOut "\nUsage:\n\t$(basename $0) <employeeID> <get|put> "'"\\\\pops\\Shared\\Production Test Programs\\path-to-your-program\\abc.zip"'"\n"

readonly id="$1"
readonly cmd="$2"
readonly popsUrl="$3"
readonly unixUrl=$(echo $popsUrl | tr '\' '/')
readonly fileName=$(basename "$unixUrl")
readonly tmpFilePrefix=x$fileName
readonly remotePath=$(dirname "$unixUrl" | sed 's/\/pops\/shared\///i')
readonly midPath='/dev/shm'
readonly midHost='10.196.154.13'


# error proof
[[ "$cmd" =~ "^(put|get)$" ]] || errOut "command \"$cmd\" is not supported"
echo "$unixUrl" | grep --color -P '/\s+|\s+/' && errOut "space is detected near /"


# data transmission
case $cmd in
put)
        [[ -f "$fileName" ]] || errOut "Cannot find $fileName"
        #split -b 10m "$fileName" $tmpFilePrefix; ls $tmpFilePrefix* | parallel --no-notice scp {} kei@$midHost:$midPath; rm -f $tmpFilePrefix*
        split -b 10m "$fileName" $tmpFilePrefix; ls $tmpFilePrefix* | xargs -P 8 -I % scp % kei@$midHost:$midPath; rm -f $tmpFilePrefix*
        ssh -t kei@$midHost "\
                cd $midPath;\
                cat $tmpFilePrefix* > $fileName;\
                smbclient //pops/shared -U \"sdcorp/$id\" -c \"$cmd $fileName\" --directory \"$remotePath\"; rm -f $tmpFilePrefix* $fileName"
;;
get)
        ssh -t kei@$midHost "\
                cd $midPath;\
                smbclient //pops/shared -U \"sdcorp/$id\" -c \"$cmd $fileName\" --directory \"$remotePath\"" || errOut "Cannot find remote file $fileName"
        scp kei@$midHost:$midPath/$fileName .
        ssh -t kei@$midHost "\
                rm -f $midPath/$fileName"
;;
esac


# another way
# [[ $UID == 0 ]] || errOut "You need to be a root"

