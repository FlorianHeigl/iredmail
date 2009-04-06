#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os
import sys
import web
import ldap
from gettext import gettext as _

import ldapconf
import iredconf
import iredutils

# Define and return LDIF structure of domain.
def ldif_domain(domainName):
    ldif = [
            ('objectCLass',     ['mailDomain']),
            ('domainName',      [domainName]),
            ('mtaTransport',    ['dovecot']),
            ('domainStatus',    ['active']),
            ('enabledService',  ['mail']),
            ]

    return ldif

def ldif_ou(name):
    ldif = [
            ('objectCLass',     ['organizationalUnit']),
            ('ou',              [name]),
            ]

    return ldif

# Define and return LDIF structure of domain admin.
def ldif_admin(admin, passwd, domainGlobalAdmin):
    ldif = [
            ('objectCLass',     ['mailAdmin']),
            ('mail',            [str(admin)]),
            ('userPassword',    [str(passwd)]),
            ('accountStatus',   ['active']),
            ('domainGlobalAdmin',   [str(domainGlobalAdmin)]),
            ]

    return ldif

# Define and return LDIF structure of mail user.
def ldif_user(domainName, username, passwd, quota):
    domain = domainName
    quota = str(quota*1048576)  # quota = UserInput (MB) * 1048576 (1MB)
    mail = username + '@' + domain

    if iredconf.MAILBOX_STYLE == 'hashed':
        if len(username) < 2:
            mailMessageStore = "%s/%s/%s/%s/" % (domain, username[:1], username[:1]*2, username)
        else:
            mailMessageStore = "%s/%s/%s/%s/" % (domain, username[:1], username[:2], username)
    else:
        mailMessageStore = "%s/%s/" % (domain, username)

    homeDirectory = iredconf.MAILBOX_BASE + '/' + mailMessageStore

    ldif = [
        ('objectCLass',         ['inetOrgPerson', 'mailUser', 'shadowAccount']),
        ('mail',                [mail]),
        ('userPassword',        [str(passwd)]),
        ('mailQuota',           [quota]),
        ('cn',                  [username]),
        ('sn',                  [username]),
        ('uid',                 [username]),
        ('homeDirectory',       [homeDirectory]),
        ('mailMessageStore',    [mailMessageStore]),
        ('accountStatus',       ['active']),
        ('mtaTransport',        ['dovecot']),
        ('enabledService',      ['mail', 'smtp', 'pop3', 'imap', 'deliver']),
        ]

    return ldif

# Used for user auth.
def DBAuth(session, dn, pw):
    try:
        conn = ldap.initialize(ldapconf.LDAP_SERVER_URI)
        if ldapconf.LDAP_USE_TLS == 'YES':
            try:
                conn.start_tls_s()
            except ldap.LDAPError, e:
                return str(e)

        dn = dn.strip()
        pw = pw.strip()

        try:
            res = conn.bind_s(dn, pw)

            if res:
                # Check whether this user is a site wide global admin.
                global_admin_result = conn.search_s(
                        dn,
                        ldap.SCOPE_BASE,
                        "(objectClass=*)",
                        ['domainGlobalAdmin']
                        )
                result = global_admin_result[0][1]
                if result.has_key('domainGlobalAdmin'):
                    session['domainGlobalAdmin'] = 'yes'
                else:
                    pass

                return True
            else:
                return False
        except ldap.INVALID_CREDENTIALS:
            return _('Error: Username or password is incorrect.')
        except ldap.SERVER_DOWN:
            return _('Error: Server is down.')
        except ldap.LDAPError, e:
            #if type(e.message) == dict and e.message.has_key('desc'):
            #    return e.message['desc']
            #else:
            return _('Error: ') + str(e)
    finally:
        conn.unbind()

class DBWrap:
    def __init__(self, app, session=None, **settings):
        self._app = app
        self.session = session

        # Initialize connection.
        try:
            self.conn = ldap.initialize(ldapconf.LDAP_SERVER_URI)
        except Exception, e:
            return str(e)

        # Set default size limit.
        #self.conn.set_option(ldap.OPT_SIZELIMIT, int(ldapconf.LDAP_SIZELIMIT))

        if ldapconf.LDAP_USE_TLS == 'YES':
            try:
                self.conn.start_tls_s()
            except ldap.LDAPError, e:
                return e

        # synchronous bind.
        self.conn.bind_s(ldapconf.LDAP_BIND_DN, ldapconf.LDAP_BIND_PW)

    def __del__(self):
        self.conn.unbind()

    def check_global_admin(func):
        def proxyfunc(self, *args, **kw):
            if self.session.get('domainGlobalAdmin') == 'yes':
                return func(self, *args, **kw)
            else:
                return False
        return proxyfunc

    def check_domain_access(self, domainDN, domainName, admin):
        if self.session.get('domainGlobalAdmin') == 'yes':
            return True
        else:
            self.access = self.conn.search_s(
                    domainDN,
                    ldap.SCOPE_BASE,
                    "(&(domainName=%s)(domainAdmin=%s))" % (domainName, admin),
                    ['domainAdmin'],
                    )

            if len(self.access) == 0:        # Not domain admin.
                return False
            elif len(self.access) == 1:
                #else:
                entry = self.access[0][1]
                if entry.has_key('domainAdmin') and admin in entry.get('domainAdmin'):
                    return True
                else:
                    return False

    def init_passwd(self, dn, passwd):
        self.conn.passwd_s(dn, '', passwd)

    def change_passwd(self, username, cur_passwd, new_passwd, new_passwd_confirm):
        # Username should be dn.
        if cur_passwd == '':
            return _('Current password is empty.')
        elif new_passwd == '' or new_passwd_confirm == '':
            return _('New password is empty.')
        elif new_passwd != new_passwd_confirm:
            # Verify new password.
            return _('New passwords are not the same, please re-type them.')
        else:
            try:
                # Reference: RFC3062 - LDAP Password Modify Extended Operation
                self.conn.passwd_s(username, cur_passwd, new_passwd)
                return True
            except ldap.LDAPError, e:
                return _('Operation failed:') + str(e)

    def check_domain_exist(self, domainName):
        self.result = self.conn.search_s(
                ldapconf.LDAP_BASEDN,
                ldap.SCOPE_ONELEVEL,
                "(domainName=%s)" % (domainName),
                )

        if len(self.result) == 1:
            return True
        else:
            return False

    def domain_add(self, domainName):
        # msg: {'domainName': 'result'}
        msg = {}
        for domain in domainName:
            domain = str(domain)
            dn = "domainName=" + domain + "," + ldapconf.LDAP_BASEDN
            ldif = ldif_domain(domain)

            # ou: Groups, Users.
            dn_groups = 'ou=Groups,' + dn
            dn_users = 'ou=Users,' + dn

            ldif_groups = ldif_ou('Groups')
            ldif_users = ldif_ou('Users')

            try:
                result = self.conn.add_s(dn, ldif)
                self.conn.add_s(dn_groups, ldif_groups)
                self.conn.add_s(dn_users, ldif_users)
                msg[domain] = _('Added success')
            except ldap.ALREADY_EXISTS:
                msg[domain] = _('Already exists')
            except ldap.LDAPError, e:
                msg[domain] = str(e)

        return msg

    # List all domains.
    def domain_list(self, admin):
        # Check whether admin is a site wide admin.
        if self.session.get('domainGlobalAdmin') == 'yes':
            filter = '(objectClass=mailDomain)'
        else:
            filter = '(&(objectClass=mailDomain)(domainAdmin=%s))' % (admin)

        # List all domains under control.
        self.domains = self.conn.search_s(
                ldapconf.LDAP_BASEDN,
                ldap.SCOPE_ONELEVEL,
                filter,
                ldapconf.LDAP_DOMAIN_SEARCH_ATTRS,
                )

        return self.domains

    def delete_dn(self, dnlist, type=None):
        # msg: {'dn': 'result'}
        msg = {}
        for dn in dnlist:
            try:
                # If object is domain, we should remove user/group container first.
                if type == 'domain':
                    dn_groups = 'ou=Groups,' + str(dn)
                    dn_users = 'ou=Users,' + str(dn)
                    for i in dn_groups, dn_users:
                        try:
                            self.conn.delete_s(i)
                        except ldap.NO_SUCH_OBJECT:
                            pass
                        except ldap.LDAPError, e:
                            msg[i] = str(e)

                # Delete destination.
                self.conn.delete_s(str(dn))
                msg[dn] = _('Removed')
            except ldap.NOT_ALLOWED_ON_NONLEAF:
                msg[dn] = _('Error: Please remove all subordinate objects first')
            except ldap.NO_SUCH_OBJECT:
                msg[dn] = _('Object not exist')
            except ldap.LDAPError, e:
                msg[dn] = str(e)

        return msg

    # List all users under one domain.
    def user_list(self, domainDN, domainName):
        self.domainDN = domainDN
        self.domainName = domainName

        # Check whether user is admin of domain.
        self.access = self.check_domain_access(domainDN, domainName, self.session.get('username'))

        if self.access is True:
            # Search users under domain.
            try:
                self.users = self.conn.search_s(
                        self.domainDN,
                        ldap.SCOPE_SUBTREE,
                        "(objectClass=mailUser)",
                        ldapconf.LDAP_USER_SEARCH_ATTRS,
                        )
                return self.users
            except ldap.SIZELIMIT_EXCEEDED:
                return _('Size limit exceeded. Please decrease "sizelimit" setting in "config/ldapconf.py", or increase "sizelimit" in LDAP server side (default is 500).')
            except Exception, e:
                return _("Error: ") + str(e)
        else:
            return _('Permission deny.')

    # List all admin accounts.
    def admin_list(self):
        filter = ldapconf.LDAP_DOMAINADMIN_SEARCH_FILTER
        self.admins = self.conn.search_s(
                ldapconf.LDAP_DOMAINADMIN_DN,
                ldap.SCOPE_ONELEVEL,
                filter,
                ldapconf.LDAP_DOMAINADMIN_SEARCH_ATTRS,
                )

        return self.admins


    def admin_add(self, admin, passwd, domainGlobalAdmin):
        # msg: {'admin': 'result'}
        msg = {}
        admin = str(admin)
        dn = "mail=" + admin + "," + ldapconf.LDAP_DOMAINADMIN_DN
        ldif = ldif_admin(admin, passwd, domainGlobalAdmin)

        try:
            # Add object and initialize password.
            self.conn.add_s(dn, ldif)
            self.conn.passwd(dn, passwd, passwd)
            msg[admin] = _('Added success')
        except ldap.ALREADY_EXISTS:
            msg[admin] = _('Already exists')
        except ldap.LDAPError, e:
            msg[admin] = str(e)

        return msg

    def user_add(self, domainDN, domainName, userList, passwd, quota=100):
        msg = {}
        domainDN = str(domainDN)
        domain = str(domainName)
        quota = int(quota)

        print >> sys.stderr, userList

        for user in userList.split():
            print >> sys.stderr, user
            user = str(user)
            dn = 'mail=%s,ou=Users,%s' % (
                    user +'@'+ domain,
                    domainDN,
                    )
            ldif = ldif_user(domain, user, passwd, quota)

            try:
                result = self.conn.add_s(dn, ldif)
                msg[domain] = _('Added success')
            except ldap.ALREADY_EXISTS:
                msg[domain] = _('Already exists')
            except ldap.LDAPError, e:
                msg[domain] = str(e)

        return msg
