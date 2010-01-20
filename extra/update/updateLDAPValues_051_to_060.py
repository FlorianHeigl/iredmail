#!/usr/bin/env python
# encoding: utf-8

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>
# Purpose:  Add objectClass=amavisAccount for all mail user which
#           required in iRedMail-0.6.0.

import sys
import ldap

# Note:
#   * bind_dn must have write privilege on LDAP server.
uri = 'ldap://127.0.0.1:389'
basedn = 'o=domains,dc=iredmail,dc=org'
bind_dn = 'cn=vmailadmin,dc=iredmail,dc=org'
bind_pw = 'passwd'

# Initialize LDAP connection.
conn = ldap.initialize(uri=uri, trace_level=0,)

# Bind.
conn.bind_s(bind_dn, bind_pw)

# Get all mail users.
allUsers = conn.search_s(
        basedn,
        ldap.SCOPE_SUBTREE,
        "(objectClass=mailUser)",
        ['mail',],
        )

# Debug.
#print >> sys.stderr, allUsers

# Counter.
count = 1

for user in allUsers:
    dn = user[0]
    mail = user[1]['mail'][0]

    try:
        conn.modify_s(self.dn, [(ldap.MOD_ADD, 'objectClass', 'amavisAccount')])
        print >> sys.stderr, """Updated user (%d): %s""" % (count, mail)
    except ldap.TYPE_OR_VALUE_EXISTS:
        pass
    except Exception, e:
        print >> sys.stderr, """Error while updating user (%s): %s""" % (mail, str(e))

    count += 1

# Unbind connection.
conn.unbind()

print >> sys.stderr, 'Updated.'
