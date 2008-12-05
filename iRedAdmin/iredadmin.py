#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os
import sys
import gettext
import web
from web import form

urls = (
        # Make url ending with or without '/' going to the same class.
        "/(.*)/", "redirect",

        '/login', 'login',
        '/logout', 'logout',
        )

app = web.application(urls, globals())

# Currently, sessions doesn't work in debug mode.
web.config.debug = False

# Internal error.
#app.internalerror = web.debugerror

# File location directory.
rootdir = os.path.dirname(__file__)

# i18n directory.
localedir = rootdir + '/i18n'

# Append current file localtion to sys path.
for libdir in ['libs', 'config']:
    sys.path.append(rootdir + '/' + libdir)

# Import iRedAdmin config file.
import iredconf

# i18n support in Python script and webpy template file.
# TODO: per-user language setting.
gettext.install('iredadmin', localedir, unicode=True)   
gettext.translation('iredadmin', localedir, languages=[iredconf.LANG]).install(True)

# Directory to be used as the Python egg cache directory.
# Note that the directory specified must exist and be writable by the
# user that the daemon process run as. 
os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# Use webpy templator.
render = web.template.render(rootdir + '/templates/' + iredconf.SKIN, globals={'_':_})

# Customize page not found error.
def notfound():
    return web.notfound("Sorry, the page you were looking for was not found.")

app.notfound = notfound

# Sessions.
sessionDB = web.database(
        host = iredconf.DB_SERVER_ADDR,
        port = int(iredconf.DB_SERVER_PORT),
        dbn = iredconf.SESSION_DB_DBN,
        db = iredconf.SESSION_DB_NAME,
        user = iredconf.SESSION_DB_USER,
        pw = iredconf.SESSION_DB_PASSWD,
        )

if web.config.get('_session') is None:
    sessionStore = web.session.DBStore(sessionDB, iredconf.SESSION_DB_TABLE_SESSION)
    # Initialize.
    session = web.session.Session(app, sessionStore, initializer={'username': 'Anonymous'})
    web.config._session = session
else:
    session = web.config._session

class redirect:
    '''Make url ending with or without '/' going to the same class.
    '''
    def GET(self, path):
        web.seeother('/' + path)

def logged(session):
    if "logged" in session:
        if session["logged"] == 1:
            return True
        else:
            return False
    else:
        return False

class login:
    # Login form
    vusername = form.regexp(r".*@.*", _('Must be a valid email address'))
    login_form = form.Form(
            form.Textbox('username', vusername, description=_('Username:')),
            form.Password('password', description=_('Password:')),
            form.Button("submit", type="submit", description=_('Login')),
            )

    def GET(self):
        # Show login page.
        f = self.login_form()
        return render.login(form=f)

    def POST(self):
        f = self.login_form()
        if not f.validates():
            return render.login(f)
        else:
            web.seeother('./login')


# Run with Apache + mod_wsgi.
application = app.wsgifunc() 
