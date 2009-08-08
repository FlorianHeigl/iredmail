#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import sys
import ldap
import web
from libs.ldaplib import core, attrs, iredutils

session = web.config.get('_session')

class User(core.LDAPWrap):
    def __del__(self):
        pass

    # List all users under one domain.
    def list(self, domain):
        self.domain = domain
        self.domainDN = iredutils.convDomainToDN(self.domain)

        # Check whether user is admin of domain.
        if self.check_domain_access(self.domainDN, session.get('username')):
            # Search users under domain.
            try:
                self.users = self.conn.search_s(
                        'ou=Users,' + self.domainDN,
                        ldap.SCOPE_SUBTREE,
                        '(objectClass=mailUser)',
                        attrs.USER_SEARCH_ATTRS,
                        )

                self.updateAttrSingleValue(self.domainDN, 'domainCurrentUserNumber', len(self.users))

                return self.users
            except ldap.NO_SUCH_OBJECT:
                self.conn.add_s(
                        'ou=Users,'+ self.domainDN,
                        iredldif.ldif_group('Users'),
                        )
                return []
            except ldap.SIZELIMIT_EXCEEDED:
                return 'SIZELIMIT_EXCEEDED'
            except Exception, e:
                return str(e)
        else:
            return False

    # Get values of user dn.
    def profile(self, dn):
        self.user_profile = self.conn.search_s(
                str(dn),
                ldap.SCOPE_BASE,
                '(objectClass=mailUser)',
                attrs.USER_ATTRS_ALL,
                )

        return self.user_profile

    def add(self, dn, ldif):
        print >> sys.stderr, 'dn:', dn, '\nldif:', ldif
