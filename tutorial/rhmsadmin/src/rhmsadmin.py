#!/usr/bin/env python
# encoding: utf-8

import os
import sys
import web
from web.contrib.template import render_mako
from web import form
import gettext

sys.path.extend([
    os.path.join(os.path.dirname(__file__)),
    os.path.join(os.path.dirname(__file__), 'libs'),
    ])

import rhmsadminconfig

sys.stdout = sys.stderr
languagedir = 'languages'
skindir = 'skins/'
templatedir = skindir + rhmsadminconfig.skin + '/templates'

gettext.translation(
        'rhmsadmin',
        os.path.join(os.path.dirname(__file__), languagedir),
        languages=rhmsadminconfig.language,
        codeset='utf-8').install(True),

urls = (
    '(/)', 'Login',
    '(/dashboard)', 'Dashboard',
    '(/domains)', 'AllDomains',
    '(/users)', 'AllUsers',
    '(/about)', 'About',
    '(/about/license)', 'AboutLicense',
    '(/login)', 'Login',
    '(/logout)', 'Logout',
)

render = render_mako(
        directories=[os.path.join(os.path.dirname(__file__), templatedir).replace('\\','/'),],
        input_encoding='utf-8',
        output_encoding='utf-8',
        encoding_errors='replace',
        )

# Dashboard.
class Dashboard:
    def GET(self, url):
        return render.dashboard(url=url)

# Domains.
class AllDomains:
    def GET(self, url):
        return render.domains(url=url)

# Users.
class AllUsers:
    def GET(self, url):
        return render.users(url=url)

# About info.
class About:
    def GET(self, url):
        return render.about(url=url)

class AboutLicense:
    def GET(self, url):
        return render.about_license(url=url)

# Login.
class Login:
    def GET(self, url):
        return render.login(url=url)

    def POST(self, url):
        i = web.input()
        if i.username and i.password:
            # Set session/cookie.
            web.Redirect('/dashboard')
        else:
            web.Redirect('/login')

# Logout.
class Logout:
    def GET(self, url):
        return render.logout(url=url)


"""
app = web.application(urls, globals())
if __name__ == '__main__':
    app.run()
"""

# For Apache + mod_wsgi.
web.internalerror = web.debugerror
application = web.application(urls, globals(), autoreload=True).wsgifunc()
