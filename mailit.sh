#!/usr/bin/env bash

TO="lichao.li@analog.com,mike.bauldry@analog.com,glenn.templeman@analog.com,robert.maracle@analog.com"
FROM="linux-2fa-team@analog.com"
SUBJECT="A possible email template?"
FILE="cadEmailTemplate.html"

BODY=$(< $FILE)

# echo -e "From: $FROM
# To: $TO
# MIME-Version: 1.0
# Content-Type: text/html 
# Subject: $SUBJECT

# <pre>
# ${BODY}
# </pre>"|/usr/sbin/sendmail -t

echo -e "From: $FROM
To: $TO
MIME-Version: 1.0
Content-Type: text/html 
Subject: $SUBJECT

${BODY}"|/usr/sbin/sendmail -t  
