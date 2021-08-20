#! /usr/bin/env python

import ldap
import logging

# AD credentials to bind with
bindCreds = {'user':'svc_adsys','password':'!2345s'}

# Example account to look up:
acct = "bwarneke"

def ldap_get_user_info(creds, username):
    """
    Get info from AD.
    creds = Dictionary, administrator credentials to bind to AD with
    username = The AD username of account to query
    """
    try:
        l = ldap.initialize('ldap://adsjdc1.ad.analog.com')
        l.protocol_version = 3
        l.set_option(ldap.OPT_REFERRALS, 0)
        dn = '{}@ad.analog.com'.format(creds['user'])
        l.simple_bind_s(dn, creds['password'])
    except ldap.INVALID_CREDENTIALS:
        print "Auth Failed"
        # logging.info("Authentication failure.")
    search_term = "(samaccountname={})".format(username)
    basedn = "DC=ad,DC=analog,DC=com"
    results = l.search_s(basedn, ldap.SCOPE_SUBTREE, search_term,
                         ['mail', 'physicalDeliveryOfficeName'])
    email = results[0][1]['mail'][0]
    location = results[0][1]['physicalDeliveryOfficeName'][0]
    # close ldap connection
    l.unbind_s()
    return email, location 

#usage example
userMail, userLoc = ldap_get_user_info(bindCreds, acct)
print "Mail: {}".format(userMail)
print "Location: {}".format(userLoc)
