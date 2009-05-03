#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import web
from web import form, ctx

session = web.config.get('_session')

class redirect:
    '''Make url ending with or without '/' going to the same class.
    '''
    def GET(self, path):
        web.seeother('/' + path)
#
# Decorators
#
def protected(func):
    def proxyfunc(self, *args, **kw):
        if session.get('username') != None and session.get('logged') == True:
            return func(self, *args, **kw)
        else:
            session.kill()
            return web.seeother(ctx.homepath + '/login')
    return proxyfunc

def check_global_admin(func):
    def proxyfunc(self, *args, **kw):
        if session.get('domainGlobalAdmin') == 'yes':
            return func(self, *args, **kw)
        else:
            return web.seeother(ctx.homepath + '/dashboard')
    return proxyfunc
