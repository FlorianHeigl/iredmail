#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import os, sys
import web

# File location directory.
rootdir = os.path.abspath(os.path.dirname(__file__)) + '/'
#sys.path.append(rootdir)

# Append current file localtion to sys path.
for libdir in ['libs', 'config', 'models',]:
    sys.path.append(rootdir + libdir)

# Import iRedAdmin config file.
import iredbase

app = iredbase.app
app.notfound = iredbase.notfound
session = web.config.get('_session')

# Directory to be used as the Python egg cache directory.
# Note that the directory specified must exist and be writable by the
# user that the daemon process run as. 
os.environ['PYTHON_EGG_CACHE'] = '/tmp/.iredadmin-eggs'

if __name__ == '__main__':
    # Use webpy builtin http server.
    app.run()
else:
    # Run app under Apache + mod_wsgi.
    application = app.wsgifunc() 
