#!/bin/bash

DOMOTICZ_USER="xxxxxx"
DOMOTICZ_PASS="xxxxxx"
URL_DOMOTICZ="http://xxx.xxx.xxx.xxx:yyyy/json.htm?username=$DOMOTICZ_USER&password=$DOMOTICZ_PASS&type=command&param=updateuservariable&idx=PARAM_IDX&vname=PARAM_NAME&vtype=2&vvalue=PARAM_CMD"

REPEAT_MODE=1
SWITCH_MODE=0

FILENAME="/volume1/homes/admin/domoticz/last_seen_tag"

# Configure your Beacons in the TAG_DATA table with : [Name,MacAddress,Timeout,0,idx,mode]
# Name : the name of the uservariable used in Domoticz
# macAddress : upper case
# Timeout is in secondes the elapsed time  without a detetion for switching the beacon AWAY. Ie :if your beacon emits every 3 to 8 seondes, a timeout of 15 secondes seems good.
# idx of the uservariable in Domoticz for this beacon
# mode : SWITCH_MODE = One update per status change / REPEAT_MODE = continuous updating the RSSI every 3 secondes

TAG_1=("Tag_White" "45:5A:28:40:4C:FC" 30 5 $SWITCH_MODE)
#TAG_2=("Tag_Pink" "f1:0d:d6:e6:b0:b2" 30 6 $REPEAT_MODE)
#TAG_3=("Tag_Orange" "Fb:14:78:38:18:5e" 30 9 $REPEAT_MODE)
#TAG_4=("Tag_Green" "ff:ff:60:00:22:ae" 30 7 $REPEAT_MODE)

TAG_DATA=(
           TAG_1[@]           
#           TAG_2[@]
#           TAG_3[@]
#           TAG_4[@]
);

COUNT=${#TAG_DATA[@]}

LAST_UPDATED=()
LAST_STATE=()

INITIAL_LAUNCH=`date +%s`

while true; do
    sleep 1;
    for ((i=0; i<$COUNT;i++))
    do
        MUST_UPDATE=false
        TAG_NAME=${!TAG_DATA[i]:0:1}
        TAG_ADDR=${!TAG_DATA[i]:1:1}
        TAG_TIMEOUT=${!TAG_DATA[i]:2:1}
        TAG_IDX=${!TAG_DATA[i]:3:1}
        TAG_MODE=${!TAG_DATA[i]:4:1}
        TAG_LAST_SEEN=`awk "/$TAG_ADDR/{print $1}" $FILENAME  | cut -d ' ' -f 1`
        if [ -z "$TAG_LAST_SEEN" ]
        then
            TAG_LAST_SEEN=0
        fi
        TIMESTAMP=`date +%s`

        # for initial state, we must wait at least the timeout before updating domoticz if absent
        if [[ -z ${LAST_UPDATED[$i]} ]] && [[ "$TIMESTAMP" -gt "$(( $INITIAL_LAUNCH + $TAG_TIMEOUT ))" ]]
        then
            MUST_UPDATE=true
        elif [[ ! -z ${LAST_UPDATED[$i]} ]] && [[ "$TIMESTAMP" -gt "$(( $TAG_LAST_SEEN + $TAG_TIMEOUT ))" ]]
        then
            MUST_UPDATE=true
        elif [[ "$TIMESTAMP" -le "$(( $TAG_LAST_SEEN + $TAG_TIMEOUT ))" ]]
        then
            MUST_UPDATE=true
        fi

        SEND_CMD=false

        if [ $MUST_UPDATE == true ]
        then
            URL=$URL_DOMOTICZ
            URL=${URL/PARAM_IDX/$TAG_IDX}
            URL=${URL/PARAM_NAME/$TAG_NAME}

            LAST_UPDATED[$i]=$TIMESTAMP

            if [[ "$TIMESTAMP" -gt "$(( $TAG_LAST_SEEN + $TAG_TIMEOUT ))" ]]
            then
                #tag perdu
                if [[ -z ${LAST_STATE[$i]} ]] || [[ "$TAG_MODE" == "$SWITCH_MODE" && ${LAST_STATE[$i]} == true ]] || [[ "$TAG_MODE" == "$REPEAT_MODE" ]]
                then
                    SEND_CMD=true
                fi
                LAST_STATE[$i]=false
                URL=${URL/PARAM_CMD/"AWAY"}
            else
                #tag present
                if [[ -z ${LAST_STATE[$i]} ]] || [[ "$TAG_MODE" == "$SWITCH_MODE" && ${LAST_STATE[$i]} == false ]] || [[ "$TAG_MODE" == "$REPEAT_MODE" ]]
                then
                    SEND_CMD=true
                fi
                LAST_STATE[$i]=true
                URL=${URL/PARAM_CMD/"HOME"}
            fi


#           echo $URL

            if [ $SEND_CMD == true ]
            then
                curl $URL > /dev/null 2>&1
            fi
        fi
    done
done
