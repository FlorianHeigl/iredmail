#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os
import sys
import gettext
import web

# Use Mako template engine.
from web.contrib.template import render_mako

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
# TODO: per-user language setting.
gettext.install('iredadmin', localedir, unicode=True)   
gettext.translation('iredadmin', localedir, languages=[iredconf.LANG]).install(True)

# Directory to be used as the Python egg cache directory.
# Note that the directory specified must exist and be writable by the
# user that the daemon process run as. 
os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# input_encoding and output_encoding is important for unicode
# template file. Reference:
# http://www.makotemplates.org/docs/documentation.html#unicode
# TODO: per-user skin setting.
render = render_mako(
        directories=[curdir + '/templates/' + iredconf.SKIN],
        input_encoding='utf-8',
        output_encoding='utf-8',
        )


class hello:
    def GET(self):
        return render.index(name=_("Message"))

# Run with buildin http server.
#app = web.application(urls, globals())
#if __name__ == "__main__":
#    app.run()

# Run with Apache + mod_wsgi.
application = web.application(urls, globals()).wsgifunc()
