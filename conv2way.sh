#!/bin/bash
set -u
set -e

function warning {
        echo "$1" 1>&2
}

src=$1
sed \
-e '/^MPAT\>/a ILMODE 2WAY' \
-e 's/patcommon\.asc/patcommon2way.asc/g' \
-e 's/:[ ]\+\([A-Z]\)/:\t\1/1' \
-e 's/\t[A-Z]/\t:&/2' \
-e '/:\t/a \\t\t\t\t\t\t:FAST_DUMMY' \
"$src"

warning "#########################################################"
warning "Most conversion is finished, but please also manually    "
warning "adjust XT statement in the output file                   "
warning "Original:                                                "
warning "               NOP                     DUMMMY  XT<#AA    "
warning "                                                         "
warning "2Way:                                                    "
warning "               NOP             :       DUMMMY            "
warning "                               :FAST_DUMMMY    XT<#AA    "
warning "#########################################################"
