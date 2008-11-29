#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os
import sys
import gettext

# webpy.
import web

urls = (
    '/.*', 'hello',
    )

# File location directory.
curdir = os.path.dirname(__file__)

# Append current file localtion to sys path.
for libdir in ['libs', 'config']:
    sys.path.append(curdir + '/' + libdir)

# Import iRedAdmin config file.
import iredconf

render = web.template.render(curdir + '/templates/' + iredconf.SKIN)

os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# Python i18n support.
gettext.translation('iredadmin', localedir=curdir + '/i18n', languages=[iredconf.LANG]).install(True)

# i18n support in webpy template file.
web.template.Template.globals['_'] = gettext.gettext 

class hello:
    def GET(self):
        return render.index(name=_("Message"))

# Run with buildin http server.
#app = web.application(urls, globals())
#if __name__ == "__main__":
#    app.run()

# Run with Apache + mod_wsgi.
application = web.application(urls, globals()).wsgifunc()
