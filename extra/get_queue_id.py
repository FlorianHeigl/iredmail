#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, re, cStringIO

output = cStringIO.StringIO()

# Redirect sys.stderr to StringIO.
# Note: Must redirect before import smtplib.
sys.stderr = output

import smtplib

fromaddr = 'www@a.cn'
toaddrs  = 'www@a.cn'
msg = """From: %s
To: %s

This is a test msg.""" % (fromaddr, list(toaddrs))

server = smtplib.SMTP('localhost')
server.set_debuglevel(1)

#sys.stderr = open('output.log', 'a')
server.sendmail(fromaddr, toaddrs, msg)

# Restore sys.stderr.
sys.stderr = sys.__stderr__

server.quit()

#print output.getvalue()

r = re.compile('data:.*queued as (.*)\'.*send.*', re.DOTALL)
queueid = r.findall(output.getvalue())
print "Queue ID:", queueid[0]
