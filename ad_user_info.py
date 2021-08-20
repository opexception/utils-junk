#! /usr/bin/env python

import ldap
import sys



# AD credentials to bind with
bindCreds = {'user':'svc_adsys','password':'!2345s'}

# Example account to look up:
acct = sys.argv[1]

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
    search_term = "(samaccountname={})".format(username)
    basedn = "DC=ad,DC=analog,DC=com"
    results = l.search_s(basedn, ldap.SCOPE_SUBTREE, search_term,
                         ['mail', 'physicalDeliveryOfficeName', 'extensionAttribute1', 'extensionAttribute8', 'manager'])

    # close ldap connection
    l.unbind_s()
    return results


#usage example
adEntry = ldap_get_user_info(bindCreds, acct)
email = adEntry[0][1]['mail'][0]
location = adEntry[0][1]['physicalDeliveryOfficeName'][0]
employeeType = adEntry[0][1]['extensionAttribute1'][0]
adiEAR = adEntry[0][1]['extensionAttribute8'][0]

print "Mail: {}".format(email)
print "Location: {}".format(location)
print "Employee Number: {}".format(employeeType)
print "adiEAR: {}".format(adiEAR)

