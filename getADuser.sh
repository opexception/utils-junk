#!/usr/bin/env bash

#
# query AD for a given user's account details.
#

#ldapsearch -h nwd2dc1.ad.analog.com -x -Drmaracle@ad.analog.com -W -b dc=ad,dc=analog,dc=com samaccountname=fszorc

QUESTION=$1

CMD="ldapsearch -h nwd2dc1.ad.analog.com -x -D${USER}@ad.analog.com -W -b dc=ad,dc=analog,dc=com samaccountname=${QUESTION}"

${CMD}
