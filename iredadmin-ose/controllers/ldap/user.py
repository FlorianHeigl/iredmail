#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import sys
import web
from web import render
from web import iredconfig as cfg
from controllers.ldap import base
from controllers.ldap.core import dbinit
from libs.ldaplib import domain, user, iredldif, iredutils

session = web.config.get('_session')

domainLib = domain.Domain()
userLib = user.User()

#
# User related.
#
class list(dbinit):
    def __del__(self):
        pass

    @base.protected
    def GET(self, domain=''):
        domain = web.safestr(domain.split('/')[0])

        allDomains = domainLib.list()

        if domain == '' or domain is None:
            return render.users(allDomains=allDomains)

        users = userLib.list(domain=domain)
        if users is not False:
            return render.users(
                    users=users, cur_domain=domain,
                    allDomains=allDomains,
                    showLoginDate=eval(cfg.general.get('show_login_date', False)),
                    msg=None,
                    )
        else:
            web.seeother('/domains?msg=NO_SUCH_DOMAIN')

    @base.protected
    def POST(self):
        i = web.input(dn=[])

        action = web.safestr(i.get('action', None))
        domain = i.get('domain', None)

        msg = ''

        if domain is not None:
            domain = web.safestr(domain)
            domainDN = iredutils.convDomainToDN(domain)
            if action == 'add':
                username = i.get('username', None)
                password = web.safestr(i.get('password', ''))
                quota = web.safestr(i.get('quota', cfg.general.get('default_quota', '1024')))

                if username is not None:
                    result = self.dbwrap.user_add(
                            domain=domain,
                            userList=web.safestr(username),
                            passwd=password,
                            quota=int(quota),
                            )
                    msg = result
                else:
                    msg = 'NO_SUCH_USER'
            elif action == 'delete':
                dn = i.get('dn', None)

                if dn is not None:
                    result = self.dbwrap.delete_dn(dn)
                    msg = result
                else:
                    msg = 'NO_SUCH_USER'
            else:
                msg = None

            web.seeother('/user/list/' + web.safestr(domain))
        else:
            web.seeother('/domains?msg=NO_SUCH_DOMAIN')

class profile(dbinit):
    @base.protected
    def GET(self, email):
        #i = web.input()
        email = web.safestr(email)

        if len(email.split('@')) == 2:
            domain = email.split('@')[1]
            userdn = iredutils.convEmailToUserDN(email)

            if userdn:
                profile = userLib.profile(dn=userdn)
                return render.user_profile(user_profile=profile)
            else:
                web.seeother('/domains')
        else:
            web.seeother('/domains')

    @base.protected
    def POST(self):
        i = web.input()
        web.seeother('/user/list/a.cn')

class delete(dbinit):
    @base.protected
    def GET(self, username):
        web.seeother('/domains')

    @base.protected
    def POST(self, dn=[]):
        i = web.input(dn=[])
        dn = i.get('dn', None)
        domain = web.safestr(i.get('domain', None))
        result = self.dbwrap.delete_dn(dnlist=dn)
        if result:
            web.seeother('/' + domain + '/users')
        else:
            web.seeother('/domains')

class create(dbinit):
    @base.protected
    def GET(self, domainName=None):
        if domainName is None:
            domainName = ''
        else:
            domainName = web.safestr(domainName)

        default_quota = cfg.general.get('default_quota', '1024')
        return render.user_create(
                domainName=domainName,
                domains=domainLib.list(),
                default_quota=default_quota,
                )

    @base.protected
    def POST(self):
        i = web.input()

        # Get domain name, username, cn.
        domain = i.get('domainName', None)
        username = i.get('username', None)
        cn = i.get('cn', None)
        quota = i.get('quota', cfg.general.get('default_quota', '1024'))

        # Check password.
        newpw = web.safestr(i.get('newpw'))
        confirmpw = web.safestr(i.get('confirmpw'))
        if len(newpw) > 0 and len(confirmpw) > 0 and newpw == confirmpw:
            passwd = newpw
        elif domain is None or username is None:
            return render.user_create(
                    domainName=domain,
                    allDomains=domainLib.list(),
                    )

        ldif = iredldif.ldif_mailuser(
                domain=web.safestr(domain),
                username=web.safestr(username),
                cn=cn,
                passwd=passwd,
                quota=quota,)
        dn = iredutils.convEmailToUserDN(username + '@' + domain)
        result = userLib.add(dn, ldif)
        if result is True:
            web.seeother('/users/' + domain)
        elif result == 'ALREADY_EXISTS':
            web.seeother('/users/' + domain + '?msg=ALREADY_EXISTS')
        else:
            web.seeother('/users/' + domain)

class delete(dbinit):
    @base.protected
    def POST(self):
        i = web.input(mail=[])
        domain = i.get('domain', None)
        if domain is None:
            web.seeother('/users?msg=NO_DOMAIN')

        mails = i.get('mail', [])
        for mail in mails:
            dn = ldap.filter.escape_filter_chars(iredutils.convEmailToUserDN(mail))
        print >> sys.stderr, i 
        web.seeother('/users/' + web.safestr(domain))
