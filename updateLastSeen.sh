#!/bin/bash

FILENAME="/volume1/homes/admin/domoticz/last_seen_tag"

while true; do

	stdbuf -i0 -o0 -e0 /bin/hcitool lescan | while read -r line; do
		TIMESTAMP=`date +%s`;
		stringarray=($line)
		if [[ ${stringarray[0]} == ??:??:??:??:??:?? ]]
		then
			if grep -Rq "${stringarray[0]}" $FILENAME
			then
				#found in file : update timestamp
			    sed -i "s/.* ${stringarray[0]}/$TIMESTAMP ${stringarray[0]}/" $FILENAME
				# not found in file
			else
			    # not found in file : append
				echo $TIMESTAMP ${stringarray[0]} >> $FILENAME
			fi
		fi

	done
	hciconfig hci0 down
	hciconfig hci0 up
done

