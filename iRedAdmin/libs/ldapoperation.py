#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import ldapconf
import ldap

def convEmailToDN(email):
    user, domain = email.split('@')

    # User dn example:
    #   mail=www, domainName=iredmail.org, LDAP_BASEDN
    dn = '%s=%s,%s=%s,%s' % (ldapconf.attrDNName, email,
            ldapconf.attrDomainName, domain,
            ldapconf.LDAP_BASEDN)

    return dn

class ldapInit:
    def __init__(self):
        self.conn = ldap.initialize(ldapconf.LDAP_SERVER_URI)

        if ldapconf.LDAP_USE_TLS == 'YES':
            try:
                self.conn.start_tls_s()
            except ldap.LDAPError, e:
                return e

    def __del__(self):
        self.conn.unbind()

    def authUser(self, dn, pw):
        try:
            # synchronous bind.
            self.conn.simple_bind_s(dn, pw)
            return True
        except ldap.LDAPError, e:
            return False

class ldapAuthUser(ldapInit):
    pass

class ldapOperation:
    def __init__(self):
        self.conn = ldap.initialize(ldapconf.LDAP_SERVER_URI)

        if ldapconf.LDAP_USE_TLS == 'YES':
            try:
                self.conn.start_tls_s()
            except ldap.LDAPError, e:
                return e

    def __del__(self):
        self.conn.unbind()

    def authUser(self, dn, pw):
        try:
            # synchronous bind.
            self.conn.simple_bind_s(dn, pw)
            return True
        except ldap.LDAPError, e:
            return False
