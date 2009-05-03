#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os, sys
import os.path
import ConfigParser

import web
from web.contrib.template import render_jinja
from web import form, ctx

import gettext
from gettext import gettext as _

import iredconf
import iredurls     # URLs map.

# Directory to be used as the Python egg cache directory.
# Note that the directory specified must exist and be writable by the
# user that the daemon process run as. 
os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# File location directory.
rootdir = os.path.abspath(os.path.dirname(__file__)) + '/../'

# Append modules file localtion to sys path.
for libdir in ['libs', 'config', 'models',]:
    sys.path.append(rootdir + libdir)

app = web.application(iredurls.urls, globals(), autoreload=True)

# Sessions, stored in sql database..
if web.config.get('_session') is None:
    sessionDB = web.database(
            host    = iredconf.DB_SERVER_ADDR,
            port    = int(iredconf.DB_SERVER_PORT),
            dbn     = iredconf.SESSION_DB_DBN,
            db      = iredconf.SESSION_DB_NAME,
            user    = iredconf.SESSION_DB_USER,
            pw      = iredconf.SESSION_DB_PASSWD,
            )
    sessionStore = web.session.DBStore(sessionDB, iredconf.SESSION_DB_TABLE_SESSION)

    # Initialize session.
    session = web.session.Session(app, sessionStore,
            initializer={
                'cookie_name': iredconf.PROG,
                'username': None,
                'userdn': None,
                'logged': False,
                }
            )
    web.config._session = session
else:
    session = web.config._session

# i18n support in Python script and webpy template file.
# TODO: per-user language setting.
lang = gettext.translation('iredadmin', rootdir + 'i18n', languages=[iredconf.LANG])

# Use JinJa2 template.
render = render_jinja(
        rootdir + 'templates/' + iredconf.SKIN +  '/' + iredconf.BACKEND,     # template dir.
        extensions = ['jinja2.ext.i18n'],           # Jinja2 extensions.
        encoding = 'utf-8',                         # Encoding.
        globals = {
            'skin': iredconf.SKIN,  # Used for static files.
            'session': session,     # Used for session.
            'ctx': ctx,             # Used to get 'homepath'.
            },
        )
render._lookup.install_gettext_translations(lang)

# Customize page not found error.
def notfound():
    return web.notfound(render.pageNotFound())

# Currently, sessions doesn't work in debug mode.
"""
if iredconf.DEBUG is True:
    web.config.debug = True

    # Internal error.
    app.internalerror = web.debugerror
else:
    web.config.debug = False
"""
web.config.debug = False
