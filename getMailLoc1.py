#! /usr/bin/env python

import ldap, argpparse

# AD credentials to bind with
bindCreds = {'user':'YOUR-USER','password':'YOUR-PASSWORD'}

# Example account to look up:
acct = "rmaracle"

def ldap_get_user_info(creds, username, filter, attrs):
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


# Interactive Mode Values:
INT_AD_SERVER = ["nwd2dc1.ad.analog.com", "nwd2dc2.ad.analog.com", "adsjdc1.ad.analog.com", "limkdc1.ad.analog.com", "Other..."]
INT_AD_CREDS = [bindCreds['user'], "Other..."]
INT_BASE_DN = ["dc=ad,dc=analog,dc=com", "Other..."]
INT_FILTER = ["samaccountname", "mail", "manager", "name", "memberOf", "displayName", "extensionAttribute7", "extensionAttribute8", "sn", "cn", "dn"]

# Default Values:
AD_SERVER = "nwd2dc1.ad.analog.com"
AD_CREDS = "{}@ad.analog.com".format(bindCreds['user'])
BASE_DN = "dc=ad,dc=analog,dc=com"
AD_FILTER = "samaccountname"
AD_VALUE = ""
interactive_mode = 0


def main():

    parser = argparse.ArgumentParser(
        description = (
            "Search Active Directory"
            )
        )
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
        "--scan", "-s",
        help = ("Only perform the scan and create a database. Do not generate data. Use with -d, and -p"),
        action="store_true"
        )
    action_group.add_argument(
        "--generate", "-g",
        help = ("Only generate the data from an existing database. Use with -d, and -o"),
        action="store_true"
        )
    parser.add_argument(
        "--uid", "-u",
        help = (
            "The database file to use. If file does not exist, it will be created."
            ),
        default = "{}.db".format(os.path.basename(__file__))
        )
    parser.add_argument(
        "--path", "-p",
        help = ("The path that will be scanned"),
        default = "."
        )
    parser.add_argument(
        "--out", "-o",
        help = ("The output path to generate the needed data"),
        default = "./output"
        )
    parser.add_argument(
        "--age", "-a",
        help = ("Filter file records to files less than or equal to 'n' seconds of age."),
        default = "86400"
        )
    parser.add_argument(
        "--sizeOfDataSet", "-q",
        help = ("The size of the data set to generate in whole GB"),
        default = pow(1024,3)
        )
    args = parser.parse_args()
    db_file = args.database


if __name__ == '__main__':
    main()