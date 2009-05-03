#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import sys
import web
from gettext import gettext as _
import iredbase
import iredutils
import mbase
import ldapoperation

session = web.config.get('_session')
app = iredbase.app
render = iredbase.render

class dashboard:
    @mbase.protected
    def GET(self):
        #self.os_uname = os.uname()
        #return render.dashboard(os_uname=self.os_uname)
        return render.dashboard()

class login:
    def GET(self):
        if session.get('username') is not None and session.get('logged') is True:
            web.seeother('./dashboard')
        else:
            # Show login page.
            return render.login() #form=f, msg=None)

    def POST(self):
        # Get username, password.
        i = web.input()

        username = i.get('username').strip()
        password = i.get('password').strip()

        # Convert email to ldap dn.
        userdn = iredutils.convEmailToAdminDN(username)

        # Return True if auth success, otherwise return error msg.
        self.auth_result = ldapoperation.DBAuth(session, userdn, password)

        if self.auth_result == True:
            session['username'] = username
            session['userdn'] = userdn
            session['logged'] = True

            web.seeother('./dashboard')
        else:
            return render.login() #form=f, msg=self.auth_result)

class logout:
    def GET(self):
        session.kill()
        web.seeother('./login')

class dbinit:
    def __init__(self):
        self.dbwrap = ldapoperation.DBWrap(app=app, session=session)

class preferences:
    @mbase.protected
    def GET(self):
        return render.preferences()

class change_passwd(dbinit):
    @mbase.protected
    def GET(self):
        return render.change_passwd()
    def POST(self):
        # Get passwords.
        i = web.input()
        self.cur_passwd = i.cur_passwd
        self.new_passwd = i.new_passwd
        self.new_passwd_confirm = i.new_passwd_confirm

        if backend == 'ldap':
            self.username = session['userdn']
        elif backend == 'mysql':
            self.username = session['username']
        else:
            pass

        self.chpwd = self.dbwrap.change_passwd(
                username = self.username,
                cur_passwd = self.cur_passwd,
                new_passwd = self.new_passwd,
                new_passwd_confirm = self.new_passwd_confirm,
                )

        if self.chpwd is True:
            return render.change_passwd(msg=_('Password changed.'))
        else:
            return render.change_passwd(msg=self.chpwd)

#
# Domain related.
#
class domain_list(dbinit):
    @mbase.protected
    def GET(self):
        i = web.input(dn=[])
        action = i.get('action', None)

        if action is None:
            msg = None
        elif action == 'delete':
            dn = i.get('dn', [])

            if len(dn) >= 1:
                # Delete dn(s).
                msg = self.dbwrap.delete_dn(dn)
            else:
                msg = {_('Empty'): _('Please select at least one domain to delete.')}

        self.domains = self.dbwrap.domain_list(admin=session.get('username'))
        return render.domain_list(domains=self.domains, msg=msg)

    @mbase.check_global_admin
    @mbase.protected
    def POST(self):
        i = web.input(dn=[])

        # Post method: add, delete.
        action = i.get('action', None)
        type = i.get('type', None)

        result = None

        if action == 'add':
            # Get domain list (python list obj).
            domainName = i.get('domainName').split()

            if len(domainName) >= 1:
                # Verify new domains -- Add -- List
                result = self.dbwrap.domain_add(domainName)
            else:
                # Show system message.
                result = {_('Empty'): _('Please input at least one domain to add.')}

        elif action == 'delete':
            dn = i.get('dn', [])

            if len(dn) >= 1:
                # Delete dn(s).
                result = self.dbwrap.delete_dn(dn, type)
            else:
                result = {_('Empty'): _('Please select at least one domain to delete.')}

        domains = self.dbwrap.domain_list(admin=session.get('username'))
        return render.domain_list(domains=domains,msg=result)

class domain_add(dbinit):
    @mbase.check_global_admin
    @mbase.protected
    def GET(self):
        return render.domain_add()

#
# User related.
#
class user_list(dbinit):
    @mbase.protected
    def GET(self):
        i = web.input()

        action = i.get('action', None)
        domainDN = i.get('dn', None)
        domainName = i.get('domainName', None)

        users = self.dbwrap.user_list(
                domainDN = domainDN,
                domainName = domainName,
                )
        return render.user_list(users=users, domainDN=domainDN, domainName=domainName, msg=None)

    @mbase.protected
    def POST(self):
        i = web.input(dn=[])

        action = i.get('action', None)
        domainDN = i.get('domainDN', None)
        domainName = i.get('domainName', None)

        msg = {}

        if domainDN is not None and domainName is not None:
            if action == 'add':
                username = i.get('username', None)
                password = i.get('password', '')
                quota = i.get('quota', 100)

                if len(username) >= 1:
                    result = self.dbwrap.user_add(
                            domainDN=domainDN,
                            domainName=domainName,
                            userList=username,
                            passwd=password,
                            quota=quota,
                            )
                    msg = result
                else:
                    msg = {'Error': 'No user.'}
            elif action == 'delete':
                dn = i.get('dn', [])

                if len(dn) >= 1:
                    result = self.dbwrap.delete_dn(dn)
                    msg = result
                else:
                    msg = {'Error': 'No user.'}
            else:
                msg = None

            users = self.dbwrap.user_list(
                    domainDN = domainDN,
                    domainName = domainName,
                    )
            return render.user_list(users=users, domainDN=domainDN, domainName=domainName, msg=msg)
        else:
            web.seeother(ctx.homepath + '/domain/list')
#
# Admin related.
#
class admin_list(dbinit):
    @mbase.check_global_admin
    @mbase.protected
    def GET(self):
        i = web.input(dn=[])

        # Post method: add, delete.
        action = i.get('action', None)

        if action is None:
            pass
        elif action == 'delete':
            dn = i.get('dn', [])

            if len(dn) >= 1:
                # Delete dn(s).
                results = self.dbwrap.delete_dn(dn)
            else:
                # Show system message.
                return render.admin_list()
        else:
            pass

        self.admins = self.dbwrap.admin_list()
        return render.admin_list(admins=self.admins)

    @mbase.check_global_admin
    @mbase.protected
    def POST(self):
        i = web.input(dn=[])

        # Post method: add, delete.
        action = i.get('action', None)

        if action == 'add':
            # Get admin list (python list obj).
            admin = i.get('admin', None)
            passwd = i.get('passwd', None)
            domainGlobalAdmin = i.get('domainGlobalAdmin', 'no')

            if admin is not None and passwd is not None:
                # Try to add it.
                results = self.dbwrap.admin_add(admin, passwd, domainGlobalAdmin)

                # List admins.
                self.admins = self.dbwrap.admin_list()
                return render.admin_list(admins=self.admins, msg=results)
            else:
                # Show system message.
                self.admins = self.dbwrap.admin_list()
                return render.admin_list(admins=self.admins, msg={_('Empty'): _('Error: You must specify at least one admin name to add')})
        elif action == 'delete':
            dn = i.get('dn', [])

            if len(dn) >= 1:
                # Delete dn(s).
                results = self.dbwrap.delete_dn(dn)

                # List admins.
                self.admins = self.dbwrap.admin_list()
                return render.admin_list(admins=self.admins, msg=results)
            else:
                # Show system message.
                return render.admin_list()
        else:
            return render.admin_list()

class admin_add(dbinit):
    @mbase.check_global_admin
    @mbase.protected
    def GET(self):
        return render.admin_add()
#
# User related.
#
class user_delete(dbinit):
    @mbase.protected
    def POST(self):
        i = web.input(dn=[])
        dn = i.dn
        return render.user_delete(dn=dn)


#
# Group related.
#
class group_list(dbinit):
    @mbase.protected
    def GET(self):
        i = web.input()
        dn = i.dn
        domain = i.domain
        return render.group_list(dn=dn, domain=domain)

#
# Policyd related.
#
class antispam(dbinit):
    @mbase.protected
    def GET(self):
        return render.antispam()

class blacklist(dbinit):
    @mbase.protected
    def GET(self):
        return render.blacklist()

class whitelist(dbinit):
    @mbase.protected
    def GET(self):
        return render.whitelist()

class whitelist_add(dbinit):
    @mbase.protected
    def GET(self):
        return render.whitelist_add()

