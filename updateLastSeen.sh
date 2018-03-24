#!/bin/bash

FILENAME="/volume1/homes/admin/domoticz/last_seen_tag"

stdbuf -i0 -o0 -e0 /bin/hcitool lescan | while read -r line; do
    TIMESTAMP=`date +%s`;
    stringarray=($line)
    if [[ ${stringarray[0]} == ??:??:??:??:??:?? ]]
    then
        if grep -Rq "${stringarray[0]}" $FILENAME
        then
            #found in file : update timestamp
            sed -i "s/.* ${stringarray[0]}/$TIMESTAMP ${stringarray[0]}/" $FILENAME
        else
            # not found in file : append
            echo $TIMESTAMP ${stringarray[0]} >> $FILENAME
        fi
    fi

done
