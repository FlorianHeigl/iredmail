#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import ldap

# ----------------------------------------------------------------------------
# OpenLDAP Server config.
# ---------------------------------------------------------------------------
# Default structure in iRedMail schema.
#   dc=example,dc=com                       # LDAP_SUFFIX
#     |- cn=vmai
#     |- cn=vmailadmin
#     |- o=domainAdmins                     # Container used to store domain admin accounts.
#         |- mail=admin@domain.ltd          # Domain admin.
#         |- mail=postmaster@domain2.ltd
#     |- o=domains
#         |- domainName=hello.com
#         |- domainName=world.com           # Virtual domain.
#                 |- mail=user1@world.com   # Virtual mail user.
#                 |- mail=user2@world.com
#                 |- mail=user3@world.com
# ---------------------------------------------------------
# LDAP URI. Use 'ldaps' for TLS support.
LDAP_SERVER_URI = 'ldap://r6:389/'
LDAP_USE_TLS = 'NO'     # Values: YES, NO.
LDAP_SUFFIX = 'dc=iredmail,dc=org'

# Bind.
LDAP_BIND_DN = 'cn=vmailadmin,' + LDAP_SUFFIX
LDAP_BIND_PW = 'passwd'

# Base DN.
LDAP_BASEDN = 'o=domains,' + LDAP_SUFFIX
# Domain admin container.
LDAP_DOMAINADMIN_DN = 'o=domainAdmins,' + LDAP_SUFFIX

# Default size limit: 500.
LDAP_SIZELIMIT = '10'

LDAP_DOMAIN_SEARCH_SCOPE = ldap.SCOPE_ONELEVEL  # Search scope: one
LDAP_USER_SEARCH_SCOPE = ldap.SCOPE_SUBTREE     # Search scope: sub

# User dn example:
#   mail=www@domain.ltd,domainName=domain.ltd,[LDAP_BASEDN]
LDAP_ATTR_USER_RDN = 'mail'
LDAP_ATTR_DOMAIN_RDN = 'domainName'

# Domain related.
LDAP_DOMAIN_FILTER = '(objectClass=mailDomain)'
LDAP_DOMAIN_SEARCH_ATTRS = [
        # Normal attributes.
        'domainName', 'domainAdmin', 'mtaTransport', 'domainStatus', 'enabledService',
        # Internal/System attributes.
        'createTimestamp', 'modifyTimeStamp', 'hasSubordinates',
        ]

# Domain admin related.
LDAP_ATTR_GLOBAL_ADMIN = 'domainGlobalAdmin'
LDAP_DOMAINADMIN_SEARCH_FILTER = '(objectClass=mailAdmin)'
LDAP_DOMAINADMIN_SEARCH_ATTRS = ['mail', 'accountStatus', 'domainGlobalAdmin', 'enabledService']

# User related.
LDAP_USER_FILTER = '(objectClass=mailUser)'
LDAP_USER_SEARCH_ATTRS = ['mail', 'accountStatus', 'enabledService', 'createTimestamp', 'modifyTimeStamp', 'mailQuota']
LDAP_USER_ATTR_PASSWORD = 'userPassword'
