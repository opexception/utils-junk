#!/bin/bash

# Monitor disk space. Send email if a new alert condition is detected.

####
## Global Variables
####

# This machines hostname
THIS_HOST=$(uname -n)

# Set admin email so that you can get email.
ADMIN="robert.maracle@analog.com"

# Exclude list of unwanted monitoring, if several partions then use "|" to separate the partitions.
# An example: EXCLUDE_LIST="/dev/hdd1|/dev/hdc5"
#EXCLUDE_LIST="/cad/adi|/cad/local|/cad/div|/home"
EXCLUDE_LIST="/cad/adi|/cad/local|/cad/div|/home|map"

# Enable/Disable various alert levels, or thresholds. ALERT_LEVEL[0] is the first, or lowest threshold.
# Add as many alert levels as necessary, with increasing criticality.
# Do not leave gaps or empty values.
ALERT_LEVEL[0]=5%
ALERT_LEVEL[1]=10%

# A file to record warning history.
#DISK_ALERT_RECORD=/var/log/disk_space_alert.log
DISK_ALERT_RECORD=~/disk_space_alert.log
# File Format:
#   MOUNT_POUNT    RESULT    TRIGGER_CONDITION    ALERT_LEVEL_INDEX    DATE

# A place to store disk usage numbers
DISK_USAGE=""

# A place to store email message while evaluating
MESSAGE_BUFFER=()
MESSAGE_SUBJECT="Alert: ${THIS_HOST} - Almost out of disk space"

# A [place to store new DISK_ALERT_RECORDS while evaluating
RECORD_BUFFER=()

# Do we need to send an alert or not? Assume not. We'll change this later, if we do.
NEED_ALERT=0

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#main_prog() {
#while read output;
#do
#  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
#  partition=$(echo $output | awk '{print $2}')
#  if [ $usep -ge $ALERT ] ; then
#     echo "Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)" | \
#     mail -s "Alert: Almost out of disk space $usep%" $ADMIN
#  fi
#done
#}
#
#if [ "$EXCLUDE_LIST" != "" ] ; then
#  df -HP | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
#else
#  df -HP | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
#fi

####
## Helper Functions
####

alertOrNot()
    { # Check to see if this is a new alert, or not. A SPAM avoidance feature.
      # Reads DISK_ALERT_RECORD history from stdin
      # ARGS:
      #   $1 should be the alert level to be checked. This corresponds to the index of the "ALERT_LEVEL" list

    local checkLevel
    local currentLevel
    local line

    checkLevel=$1
    currentLevel=""

    #!!!! code here for parsing $DISK_ALERT_RECORD into $currentLevel
    # Get the latest alert level that a warning has been sent for
    while read -r line
        do
            line=( ${line} )
            if [ ${#line[@]} -ge 4 ]
                then
                    currentLevel=${line[3]}
            fi
        done

    # Return 0 if a new alert, 1 if alert has already been sent
    if [ "${currentLevel}" != "" ]
        then
            if [ ${checkLevel} -gt ${currentLevel} ]
                then return 0
                else return 1
            fi
        else
            return 0
    fi
    }


assessUnits()
    { # Is $ALERT_LEVEL value a size, or percent? (i.e. are we comparing bytes remaining on disk, or percent used of disk?)
      # If it is a size, then convert human readable units to bytes
      # ARGS:
      #   $1 should be the $ALERT_LEVEL in question, e.g. "90%" or "2G"

    local givenThreshold
    local thresholdValue
    local thresholdUnit
    local unitFactor
    givenThreshold=${1}

    # Convert any lowercase units to upper case for easier handling.
    givenThreshold=$(echo ${givenThreshold} | tr "[a-z]" "[A-Z]")

    # Separate the value and the unit.
    case ${givenThreshold} in
        *"%")
            thresholdValue=${givenThreshold%%%*}
            thresholdUnit="%"
            unitFactor="NA"
        ;;
        *"B")
            thresholdValue=${givenThreshold%%B*}
            thresholdUnit="B"
            unitFactor=$(( 2**0 ))

        ;;
        *"K")
            thresholdValue=${givenThreshold%%K*}
            thresholdUnit="K"
            unitFactor=$(( 2**10 ))
        ;;
        *"M")
            thresholdValue=${givenThreshold%%M*}
            thresholdUnit="M"
            unitFactor=$(( 2**20 ))
        ;;
        *"G")
            thresholdValue=${givenThreshold%%G*}
            thresholdUnit="G"
            unitFactor=$(( 2**30 ))
        ;;
        *"T")
            thresholdValue=${givenThreshold%%T*}
            thresholdUnit="T"
            unitFactor=$(( 2**40 ))
        ;;
        *"P")
            thresholdValue=${givenThreshold%%P*}
            thresholdUnit="P"
            unitFactor=$(( 2**50 ))
        ;;
    esac

    # Convert size values to KBytes, if not a percent
    if [[ "${thresholdUnit}" != "%" ]]
        then
            thresholdValue=$(( ${thresholdValue}*${unitFactor} ))
            thresholdValue=$(( ${thresholdValue}/1024 ))
    fi

    # bash style return of non-integers
    echo -e "${thresholdValue}\t${thresholdUnit}"
    }

getDiskUsage()
    { # Gather the actual disk usage
      # ARGS:
      #   $1 should be the unit type we're needing to evaluate
    local unit
    local diskUsage
    unit=$1

    if [[ "${unit}" == "%" ]]
        then
            if [ "$EXCLUDE_LIST" != "" ]
                then
                    diskUsage=$(df -Pk | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}')
                else
                    diskUsage=$(df -Pk | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}')
            fi
        else
            if [ "$EXCLUDE_LIST" != "" ]
                then
                    diskUsage=$(df -Pk | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $4 " " $6}')
                else
                    diskUsage=$(df -Pk | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $4 " " $6}')
            fi
    fi

    # bash style return of non-integers
    echo "${diskUsage}"

    }


analyseUsage()
    { # Determine if any usage is beyond threshold
      # Reads $DISK_USAGE from stdin
      # ARGS:
      #   $1 should be a THRESHOLD value
      #   $2 should be a THRESHOLD unit
      #   $3 should be the ALERT_LEVEL index

    local line
    local unit
    local value
    local mount
    local threshold
    local alertIndex
    local alert
    local mailMessage
    local alertRecord
    threshold=${1}
    unit=${2}
    alertIndex=${3}
    alert=0
    

    while read -r line
        do
            line=( ${line} )
            value=${line[0]}
            mount=${line[1]}
            if [[ "${unit}" != "%" ]]
                then
                    if [ ${value} -le ${threshold} ]
                        then
                            mailMessage="Running out of space \"$mount (${value}% used)\" on server ${THIS_HOST}, $(date)\n"
                            alert=1
                    fi
                else
                    value=${value%%%*}
                    if [ ${value} -ge ${threshold} ]
                        then
                            mailMessage="Running out of space \"$mount (${value}${unit} remaining)\" on server ${THIS_HOST}, $(date)\n"
                            alert=1
                    fi
            fi
            if [ ${alert} -eq 1 ]
                then
                    if grep -E "^${mount}$" ${DISK_ALERT_RECORD} | alertOrNot ${alertIndex}
                        then
                            NEED_ALERT=1
                            MESSAGE_BUFFER=( "${MESSAGE_BUFFER[@]}" "${mailMessage}" )
                            RECORD_BUFFER=( "${RECORD_BUFFER[@]}" "${mount}\t${value}\t${threshold}\t${alertIndex}\t$(date)" )
                    fi
            fi
        done
}

####
## Main Loop
####

touch ${DISK_ALERT_RECORD}

for (( ALERT_INDEX=0; ALERT_INDEX<${#ALERT_LEVEL[@]}; ALERT_INDEX++ ))
    do
        THRESHOLD=( $(assessUnits ${ALERT_LEVEL[${ALERT_INDEX}]}) )

        DISK_USAGE=$(getDiskUsage ${THRESHOLD[1]})

        echo "${DISK_USAGE}" | analyseUsage ${THRESHOLD[@]} ${ALERT_INDEX}
        echo "Need Alert: ${NEED_ALERT}"
    done
echo "Need Alert: ${NEED_ALERT}"
if (( ${NEED_ALERT} != 0 ))
    then
        for RECORD in ${RECORD_BUFFER[@]}
            do
                echo -e ${RECORD} >> ${DISK_ALERT_RECORD}
            done
        echo -e "${MESSAGE_BUFFER[@]}" | mail -s "${MESSAGE_SUBJECT}" ${ADMIN}
        echo "${ADMIN}"
        echo "${MESSAGE_SUBJECT}"
        echo -e "${MESSAGE_BUFFER[@]}"
    else
        echo "Guess no alert"
fi








