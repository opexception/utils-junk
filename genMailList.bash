#!/bin/bash
#
# Generate a list of email addresses based on some criteria such as:
#
#   People with an LDAP "L" attribute matching a datacenter, e.g. "Colorado Springs"
#
#   People having a VDI in DNS domain like "csdesign.analog.com"
#
###########

HOSTNAME=$(hostname)

# Remove the first ".", and everything after it from $HOSTNAME
SHORT_NAME=${HOSTNAME%%.*} 

 # Remove the first ".", and everything before it from $HOSTNAME
FULL_DOMAIN=${HOSTNAME#*.}

# Remove the first ".", and everything after it from $FULL_DOMAIN
DOMAIN=${FULL_DOMAIN%%.*} 


# Full path to the scrit that we'll use to retrieve YAML variables.
YAML_SCRIPT="/cad/adi/etc/yaml/adyaml.py"

sites=( $(${YAML_SCRIPT} -a site_dns_name -v ${DOMAIN}) )
dataCenter=$(${YAML_SCRIPT} -a datacenter_location -l ${sites[0]})
#sites=$( ${YAML_SCRIPT} -a datacenter_location -v ${dataCenter} )

###########
## Get email address for all LDAP users with "L" attribute pointing to "Colorado_Springs" datacenter
###########

read -p "Which location? [${dataCenter}]: " myLocation
if [ "${myLocation}" == "" ]
    then
        myLocation="${dataCenter}"
fi
for i in ${sites[@]}
    do
        ldapsearch -x -bou=users,ou=global,dc=analog,dc=com l=${i} mail
    done | grep 'mail: ' | awk '{print $2";"}' | grep -v zzz


###########
## Get list of email addresses for anyone with a VDI in a given domain
###########

read -p "Which domain? [${FULL_DOMAIN}]: " myDomain
if [ "${myDomain}" == "" ]
    then
        myDomain="${FULL_DOMAIN}"
fi
users=( $(dig axfr ${myDomain} | egrep ".*\-lx[0-9][0-9]" | awk -F- '{print $1}') )
for user in ${users[@]}
    do
        ldapsearch -x -bou=users,ou=global,dc=analog,dc=com uid=${user} mail
    done | grep 'mail: ' | awk '{print $2";"}' | grep -v zzz





    