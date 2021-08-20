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


main():
    parser = argparse.ArgumentParser(
        description = (
            "print AD attributes for given user"
            )
        )
    parser.add_argument(
        "--user", "-u",
        help = ("The NTID to look up"),
        default = "*"
        )
    parser.add_argument(
        "--firstname", "-n",
        help = ("The user's First Name")
        default = None
        )
    parser.add_argument(
        "--lastname", "-l",
        help = ("The user's Last Name")
        default = None
        )
    parser.add_argument(
        "--email", "-m",
        help = ("The user's Email Address")
        default = None
        )
    parser.add_argument(
        "--attribute", "-a",
        nargs='*'
        help = (
            "The attributes you are searching for. Can be specified more" 
            "than once to return many attributes for a single query."
            )
        )

    args = parser.parse_args()
    filters = []
    if args.user:
        filters.append("(samaccountname={})".format(args.user))
    if args.lastname:
        filters.append("(sn={})".format(args.lastname))
    if args.firstname:
        filters.append("(givename={})".format(args.firstname))
    if args.email:
        filters.append("(mail={})".format(args.email))

    if len(filters) > 1:
        for filter in filters:
            filter_string += filter
        filter_string = "(&{})".format(filter_string)
    elif len(filters) == 0:
        filters = None


    
    
    

if __name__ == '__main__':
    main()
