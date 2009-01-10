#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

PROG = 'iRedAdmin'

# Default skin: default.
SKIN = 'default'

# Default language: en_US, zh_CN.
LANG = 'en_US'

# Backend you used to store virtual domains and users: mysql, ldap.
BACKEND = 'ldap'

# Session store: shelf, mysql, disk.
SESSION_STORE = 'disk'

# MySQL configure.
DB_SERVER_ADDR = 'localhost'
DB_SERVER_PORT = 3306

# Session relate config.
SESSION_DB_DBN = 'mysql'
SESSION_DB_NAME = 'iredadmin'
SESSION_DB_USER = 'iredadmin'
SESSION_DB_PASSWD = 'passwd'
SESSION_DB_TABLE_SESSION = 'sessions'

# Run webpy in debug mode: True, False.
DEBUG = True
