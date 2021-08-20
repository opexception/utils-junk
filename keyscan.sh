#!/bin/bash

# Output files
OUT_GLOBAL=./ssh_known_hosts.global
OUT_LOCAL=./ssh_known_hosts.local
DOMAIN="csdesign.analog.com"

# Init dictionaries
declare -A IPS
declare -A KEYS


# Funtion(s)
get_key()
    {
        local host
        local scan
        local scrape
        local thekey

        host=$1

        scan=( $(2>/dev/null ssh-keyscan ${host}.${DOMAIN} | grep -Ev "^#") )

        if (( $? ))
            then
                scrape=( $(2>/dev/null grep ${host} /cad/adi/admin/ssh/domains/csdesign.analog.com/ssh_known_hosts) )
                if (( $? ))
                    then
                        thekey="x"
                    else
                        thekey="${scrape[2]}"
                fi
            else
                thekey="${scan[2]}"
        fi

        echo ${thekey}
    }


# build dictionay of new hostnames and IPs
for line in $(cat ~/cshosts)
    do
        IPS[${line#*,}]=${line%%,*}
    done

# build dictionary of ssh host keys
for host in ${!IPS[@]}
    do
        KEYS[${host}]=$(get_key ${host})
    done

# write out files
for host in ${!IPS[@]}
    do
        if [[ "${KEYS[${host}]}" == "x" ]]
            then
                echo "No key found for ${host}"
                continue
            else
                echo "${host}.${DOMAIN},${host}.${DOMAIN%%.*},${IPS[${host}]} ssh-rsa ${KEYS[${host}]}" >> ${OUT_GLOBAL}
                echo "${host},${host}.${DOMAIN%%.*},${IPS[${host}]} ssh-rsa ${KEYS[${host}]}" >> ${OUT_LOCAL}
        fi
    done






