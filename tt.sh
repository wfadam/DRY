#!/bin/bash
set -u

#
# Designed to break down test time between 2 files
# Usage:
#       ./tt.sh FH_rev01.txt FH_rev02.txt
#

inf="$1"
inf2="$2"

mdf=`mktemp`
mdf2=`mktemp`

function filter {
    f="$1"
    LANG=C \
    grep -a \
        -e 'Test Time:' \
        -e 'Execution time:' "$f" \
    | sed \
        -e 's/TestItem:/ /g' \
        -e 's/Test Time:/ /g' \
        -e 's/End Of Flow/End_Of_Flow /g' \
        -e 's/Execution time:/Total_Time /g' \
        -e 's/\[s\]/ /g' 
}

#---------------- Execution Start ------------- 

filter "$inf"  > "$mdf"
filter "$inf2" > "$mdf2"

echo "TEST_NAME  LEFT_TIME  |  R-L  |  RIGHT_TIME  TEST_NAME"
paste "$mdf" "$mdf2" \
| awk 'function abs(x){return ((x < 0.0) ? -x : x)} \
{ \
    tdif = $4 - $2; \
    if ( abs(tdif) >= 60 ) tdif="[" tdif "]"; \
    print $1 " " $2 " | " tdif " | " $4 " " $3 \
}' 

\rm -f "$mdf" "$mdf2"
#EOF
