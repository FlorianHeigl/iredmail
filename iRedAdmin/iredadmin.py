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

# i18n directory.
localedir = curdir + '/i18n'

# Append current file localtion to sys path.
for libdir in ['libs', 'config']:
    sys.path.append(curdir + '/' + libdir)

# Import iRedAdmin config file.
import iredconf

# i18n support in Python script and webpy template file.
gettext.install('iredadmin', localedir, unicode=True)   
gettext.translation('iredadmin', localedir, languages=[iredconf.LANG]).install(True)

os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

render = web.template.render(curdir + '/templates/' + iredconf.SKIN, globals={'_': _})

class hello:
    def GET(self):
        return render.index(name=_("Message"))

# Run with buildin http server.
#app = web.application(urls, globals())
#if __name__ == "__main__":
#    app.run()

# Run with Apache + mod_wsgi.
application = web.application(urls, globals()).wsgifunc()
