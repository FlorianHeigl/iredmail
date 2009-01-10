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

        '/', 'login',
        '/login', 'login',
        '/logout', 'logout',
        '/dashboard', 'dashboard',
        '/domains', 'domains',
        )

app = web.application(urls, globals())

# File location directory.
rootdir = os.path.abspath(os.path.dirname(__file__))
sys.path.append(rootdir)

# i18n directory.
localedir = rootdir + '/i18n'

# Append current file localtion to sys path.
for libdir in ['libs', 'config']:
    sys.path.append(rootdir + '/' + libdir)

# Import iRedAdmin config file.
import iredconf

# Backend.
backend = iredconf.BACKEND

if backend == 'mysql':
    import mysqlconf as bkconf
    import mysqloperation as bkoperation
elif backend == 'ldap':
    import ldapconf as bkconf
    import ldapoperation as bkoperation

# Currently, sessions doesn't work in debug mode.
web.config.debug = iredconf.DEBUG

# Internal error.
#app.internalerror = web.debugerror

# Directory to be used as the Python egg cache directory.
# Note that the directory specified must exist and be writable by the
# user that the daemon process run as. 
os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# Sessions.
if web.config.get('_session') is None:
    if iredconf.SESSION_STORE == 'mysql':
        sessionDB = web.database(
                host = iredconf.DB_SERVER_ADDR,
                port = int(iredconf.DB_SERVER_PORT),
                dbn = iredconf.SESSION_DB_DBN,
                db = iredconf.SESSION_DB_NAME,
                user = iredconf.SESSION_DB_USER,
                pw = iredconf.SESSION_DB_PASSWD,
                )
        sessionStore = web.session.DBStore(sessionDB, iredconf.SESSION_DB_TABLE_SESSION)
    elif iredconf.SESSION_STORE == 'shelf':
        import shelve
        sessionStore = web.session.ShelfStore(shelve.open('session.shelf'))
    else:
        sessionStore = web.session.DiskStore(rootdir + '/sessions')

    # Initialize session.
    session = web.session.Session(app, sessionStore,
            initializer={
                'cookie_name': iredconf.PROG,
                'username': None,
                'userdn': None,
                'password': None,
                'logged': 0,
                }
            )

    web.config._session = session
else:
    session = web.config._session

# i18n support in Python script and webpy template file.
# TODO: per-user language setting.
gettext.install('iredadmin', localedir, unicode=True)   
gettext.translation('iredadmin', localedir, languages=[iredconf.LANG]).install(True)

# Use webpy buildin templator.
render = web.template.render(
        rootdir + '/templates/' + iredconf.SKIN,    # template dir.
        base='layout',      # Use 'layout.html' as site layout template.
        globals={'_':_, 'session': session},    # Used for i18n.
        )

# Customize page not found error.
def notfound():
    return web.notfound(render.notfound())

app.notfound = notfound

# Login form and validators.
notnull = form.Validator(_('Empty is not allowed.'), bool)
vusername = form.regexp(r".*@.*\..*", _('Must be a valid email address'))

login_form = form.Form(
        form.Textbox('username', notnull, vusername, description=_('Username: '), id='username'),
        form.Password('password', notnull, description=_('Password: '), id='password'),
        form.Checkbox('remUsername', description=_('Remember me: '), value='checked'),
        #form.Checkbox('secureLogin', description=_('Login via SSL: '), value='checked'),
        form.Button("submit", type="submit", description=_('Login'), id='submit'),
        validators = [
            form.Validator(_('Must be a valid email address.'), lambda i: len(i.username) >= 6),
            ]
        )

class redirect:
    '''Make url ending with or without '/' going to the same class.
    '''
    def GET(self, path):
        web.seeother('/' + path)

def logged(session):
    if "logged" in session:
        if session["logged"] == 1 and session['username'] != None and \
                session['userdn'] != None and session['password'] != None:
            return True
        else:
            return False
    else:
        return False

class login:
    def GET(self):
        if logged(session):
            web.seeother('./dashboard')
        else:
            # Show login page.
            f = login_form()
            return render.login(form=f, msg=None)
            #return render.login(form=f, msg=web.ctx.protocol)

    def POST(self):
        f = login_form()
        if not f.validates():
            return render.login(form=f, msg=None)
        else:
            # Get username, password.
            i = web.input()
            username = i.username
            password = i.password

            # Convert email to ldap dn.
            userdn = ldapoperation.convEmailToDN(username)

            l = ldapoperation.ldapOperation()

            if l.authUser(userdn, password) == True:
                session['username'] = username
                session['userdn'] = userdn
                session['password'] = password
                session['logged'] = 1
                web.seeother('./dashboard')
            else:
                return render.login(form=f, msg=_('Username or password is incorrect'))

class logout:
    def GET(self):
        session.kill()
        web.seeother('./login')

class dashboard:
    #@decorator
    def GET(self):
        return render.dashboard()

class domains:
    def GET(self):
        return render.domains()

# Run with Apache + mod_wsgi.
if __name__ == '__main__':
    app.run()
else:
    application = app.wsgifunc() 
