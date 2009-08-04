#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import sys
import web
from web import render
from web import iredconfig as cfg
from controllers import base
from controllers.ldap.core import dbinit
from libs.ldaplib import domain, user, iredutils

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
    def GET(self, domain=None):
        domain = web.safestr(domain.split('/')[0])
        if domain is '' or domain is None:
            web.seeother('/domains?msg=NO_SUCH_DOMAIN')

        users = userLib.list(domain=domain)
        if users is not False:
            return render.users(users=users, domain=domain, msg=None)
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
                quota = web.safestr(i.get('quota', cfg.general.get(default_quota)))

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

        self.domains = domainLib.list(attrs=['domainName'])
        domains = []
        for d in self.domains:
            if d[1].has_key('domainName'):
                domains += d[1].get('domainName')
        return render.user_create(domainName=domainName, domains=domains)

    @base.protected
    def POST(self, domain):
        i = web.input(enabledService=[])
        mod_attrs = iredutils.get_mod_attrs(accountType='user', data=i)
        web.seeother('/domains')
