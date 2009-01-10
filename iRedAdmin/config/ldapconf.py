#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# ---------------------------------------------------------
# OpenLDAP Server config.
# ---------------------------------------------------------
# LDAP URI. Use 'ldaps' for TLS support.
LDAP_SERVER_URI = 'ldap://r6/'
LDAP_USE_TLS = 'NO' # Values: YES, NO.
LDAP_BASEDN = 'o=domains,dc=iredmail,dc=org'

# User dn example:
#   mail=www, domainName=iredmail.org, LDAP_BASEDN
attrDNName = 'mail'
attrDomainName = 'domainName'
