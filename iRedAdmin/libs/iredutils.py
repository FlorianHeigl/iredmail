#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import ldapconf

def convEmailToAdminDN(email):
    """Convert email address to ldap dn."""
    email = email.strip()
    user, domain = email.split('@')

    # Admin DN format.
    # mail=user@domain.ltd,[LDAP_DOMAINADMIN_DN]
    admindn = '%s=%s,%s' % ( ldapconf.LDAP_ATTR_USER_RDN, email, ldapconf.LDAP_DOMAINADMIN_DN)

    return admindn

def removeSpaceAndDot(string):
    """Remove leading and trailing dot and all whitespace."""
    return str(string).strip(' .').replace(' ', '')
