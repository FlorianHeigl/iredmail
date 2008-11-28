#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os
import sys

# webpy.
import web
from web.contrib.template import render_mako

urls = (
    '/.*', 'hello',
    )

# File location directory.
curdir = os.path.dirname(__file__)

# Append current file localtion to sys path.
for libdir in ['libs', 'config']:
    sys.path.append(curdir + '/' + libdir)

import iredconf

os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

# input_encoding and output_encoding is important for unicode
# template file. Reference:
# http://www.makotemplates.org/docs/documentation.html#unicode
render = render_mako(
        directories=[os.path.join(curdir, 'templates/' + iredconf.SKIN).replace('\\','/'),],
        input_encoding='utf-8',
        output_encoding='utf-8',
        )

class hello:
    def GET(self):
        return render.index(msg=curdir)

# Run with buildin http server.
#app = web.application(urls, globals())
#if __name__ == "__main__":
#    app.run()

# Run with Apache + mod_wsgi.
application = web.application(urls, globals()).wsgifunc()
