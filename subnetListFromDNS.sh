#!/bin/bash

# Run from master centralized DNS server

cd /etc/named/conf/masters || (echo "Run from your master DNS server"; exit)

get_site_name()
    { # translate a DNS zone name to a SITE name
    local SITE
    case $1 in
        "adral.analog.com")
            SITE="RALEIGH"
        ;;
        "adsd.analog.com")
            SITE="SAN_DIEGO"
        ;;
        "adsdesign.analog.com")
            SITE="WILMINGTON"
        ;;
        "adsiv.analog.com")
            SITE="SAN_JOSE"
        ;;
        "chedesign.analog.com")
            SITE="CHELMSFORD"
        ;;
        "cld.analog.com")
            SITE="GREENSBORO"
        ;;
        "csdesign.analog.com")
            SITE="COLORADO_SPRINGS"
        ;;
        "hit.local")
            SITE="OTTAWA_LEGACY"
        ;;
        "hittite")
            SITE="CHELMSFORD_LEGACY"
        ;;
        "hmcco.local")
            SITE="COLORADO_SPRINGS_LEGACY"
        ;;
        "lmdesign.analog.com")
            SITE="LONGMONT"
        ;;
        "njdesign.analog.com")
            SITE="NEW_JERSEY"
        ;;
        "nwldesign.analog.com")
            SITE="NW_LABS"
        ;;
        "ottdesign.analog.com")
            SITE="OTTAWA"
        ;;
        "stdesign.analog.com")
            SITE="BELLEVUE"
        ;;
        "tdcdesign.analog.com")
            SITE="TORONTO"
        ;;
    esac
    echo ${SITE}
}

subnets=()

lines=( $(egrep -v "^#" *.conf | grep "addr.arpa" | sed 's/\.conf:zone\s*"/ /g ; s/"\s*IN\s*{//g' | awk '{print $1":"$2}') )

for line in "${lines[@]}"
    do
        subnet=()
        rev_subnet=""
        sn=$(echo ${line} | cut -d":" -f2)
        zone=$(echo ${line} | cut -d":" -f1)
        sn_split=( ${sn//./ } )
        for octet in ${sn_split[@]}
            do
                if [ "${octet}" == "in-addr" ]
                    then
                        continue
                    elif [ "${octet}" == "arpa" ]
                        then
                            continue
                    else
                        subnet=( ${subnet[@]} ${octet} )
                fi
            done
        for (( index=${#subnet[@]}-1; index>=0; index-- ))
            do
                rev_subnet="${rev_subnet}.${subnet[${index}]}"
            done
        rev_subnet="${rev_subnet#.}.*"
        site=$(get_site_name ${zone})
        echo "SITE ${site} ${rev_subnet}"
    done

