#!/bin/bash
#
# Grep DNS
#

# Setup debugging
debugging=0 # 1=debug on, 0=debug off

dns_dir="/net/adsdns-m1.adsdesign.analog.com/var/named"


debugit()
    { # Output debug messages if the debugging flag is set.
      # Prints any/all arguments to stdout if debugging is on.
    if [ ${debugging} == 1 ]
        then echo "DEBUG: $@"
    fi
    }


disp_help()
    { # Print script help to screen, and exit.
      # Optional argument will set exit value.
        echo
        echo "This utility must be run from an admin node."
        echo "usage: $0 {SUBDOMAIN} {VALUE}"
        echo -e "\te.g. $0 csdesign rmaracle-lx01"
        echo
        echo "Basic regex are understood in VALUE"
        echo -e "\te.g. $0 csdesign rmaracle-lx0."
        echo "Or"
        echo -e "\te.g. $0 csdesign '.*-lx..'"
        echo
        if [ $# = 1 ]
            then
                if [[ $1 =~ '^[0-9]+$' ]]
                    then exit $1
                    else exit 2
                fi
            else
                exit
        fi
    }


# Get some details about the host we're running on.
thisHost=$(hostname)
debugit "hostname command reports this hostname is: ${thisHost}"
if [[ ${thisHost} = *.* ]]
    then
        thisShortName=${thisHost%%.*}
        debugit "I think this host's short name is: ${thisShortName}"
        thisDomain=${thisHost#*.}
        debugit "I think this host's domain name is: ${thisDomain}"
    elif [ -z ${thisHost} ]
        then
            debugit "Could not reliably determine the FQDN of localhost"
            thisShortName="NULL"
            thisDomain="NULL"
        else
            thisShortName=${thisHost}
            debugit "I think this host's short name is: ${thisShortName}"
            thisDomain="NULL"
            debugit "Cannot determine domain name of localhost"
fi

# Make sure we're running on an admin node.
if [[ ${thisShortName} != *admin* ]]
    then
        debugit "\"${thisShortName}\" does not look like an admin node to me."
        disp_help 1
    else
        debugit "\"${thisShortName}\" looks like an admin node to me."
fi

if [ $# -gt 1 ]
    then
        zone=$1
        shift
    else
        disp_help 1
fi

start_dir=$(pwd)

cd ${dns_dir}

for arg in "$@"
    do
        egrep "${arg}" ${zone}.zone
    done

cd ${start_dir}
