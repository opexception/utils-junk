#!/bin/bash

# Define the subnet by octet 
OCTET_1=10
OCTET_2=66
OCTET_3=8

# The reverse zone we want to find IPs in.
revzone="${OCTET_3}.${OCTET_2}.${OCTET_1}.in-addr.arpa."

# Dump existing address' last octet to an array
addrs=( $(dig axfr ${revzone} | grep PTR | awk -F. '{print $1}' | sort -n) )

# for each octet from 1-254, find which ones are not present in DNS
for i in $(seq 1 254)
    do
        for j in ${addrs[@]}
            do
                if [ "$j" == "${addrs[-1]}" ]
                    then
                        if [ $i == $j ]
                            then break
                            else echo "${OCTET_1}.${OCTET_2}.${OCTET_3}.${i}"
                        fi
                fi
                if [ "$i" == "$j" ]
                    then break
                    else continue
                fi
            done
    done