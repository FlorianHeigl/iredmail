#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

#saveerr = sys.stderr
#ferr= open('output.log', 'a')
sys.stderr = open('output.log', 'w')

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

sys.stderr = sys.__stderr__

server.quit()
