#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# Filename: create_mail_user_OpenLDAP.py
# Author:   Zhang Huangbin (michaelbibby#gmail.com)
# Lastest update:   2009.06.15
# Purpose: Add new OpenLDAP user for postfix mail server.
#
# Shipped within iRedMail project:
#   * http://code.google.com/p/iredmail/

# --------------------------- WARNING ------------------------------
# This script only works under iRedMail >= 0.3.3 due to ldap schema
# changes.
# ------------------------------------------------------------------

# ---------------------------- USAGE -------------------------------
# Put your user list in a csv format file, e.g. users.csv, and then
# import users listed in the file:
#
#   $ sudo python create_mail_user_OpenLDAP.py users.csv
#
# ------------------------------------------------------------------

import os
import sys

try:
    import ldap
    import ldif
except ImportError:
    print '''
    Error: You don't have python-ldap installed, Please install it first.
    
    You can install it like this:

    - On RHEL/CentOS 5.x:

        $ sudo yum install python-ldap

    - On Debian & Ubuntu:

        $ sudo apt-get install python-ldap
    '''
    sys.exit()


# LDAP server address.
LDAP_URI = 'ldap://127.0.0.1:389'

# LDAP base dn.
BASEDN = 'o=domains,dc=iredmail,dc=org'

# LDAP bind dn & password.
#BINDDN = 'cn=Manager,dc=iredmail,dc=org'
BINDDN = 'cn=vmailadmin,dc=iredmail,dc=org'
BINDPW = 'passwd'

# Storage base directory.
STORAGE_BASE_DIRECTORY = '/home/vmail'

# Hashed maildir: True, False.
# Example:
#   domain: domain.ltd,
#   user:   zhang (zhang@domain.ltd)
#
#       - hashed: d/do/domain.ltd/z/zh/zha/zhang/
#       - normal: domain.ltd/zhang/
HASHED_MAILDIR = True

def usage():
    print '''
CSV file format:

    domain name, username, password, common name, quota, groups

Example #1:
    iredmail.org, zhang, secret_pw, Zhang Huangbin, 1024, group1:group2
Example #2:
    iredmail.org, zhang, secret_pw, Zhang Huangbin, , ,
Example #3:
    iredmail.org, zhang, secret_pw, , 1024, group1:group2
     
Note:
    - Domain name, username and password are REQUIRED, others are optinal:
        + common name.
            * It will be the same as username if it's empty.
            * Non-ascii character is allowed in this field, they will be
              encoded automaticly. Such as Chinese, Korea, Japanese, etc.
        + quota. It will be 0 (unlimited quota) if it's empty.
        + groups.
            * valid group name (hr@a.cn): hr
            * incorrect group name: hr@a.cn
            * Do *NOT* include domain name in group name, it will be
              appended automaticly.
            * Multiple groups must be seperated by colon.
    - Leading and trailing Space will be ignored.
'''

def removeSpaceAndDot(string):
    """Remove leading and trailing dot and all whitespace."""
    return str(string).strip(' .').replace(' ', '')

def convEmailToUserDN(email):
    """Convert email address to ldap dn of normail mail user."""
    email = str(email).strip()
    if len(email.split('@')) == 2:
        user, domain = email.split('@')
    else:
        return False

    # User DN format.
    # mail=user@domain.ltd,domainName=domain.ltd,[LDAP_BASEDN]
    dn = 'mail=%s,ou=Users,domainName=%s,%s' % ( email, domain, BASEDN)

    return dn

def ldif_mailuser(domain, username, passwd, cn, quota=1024, groups=''):
    domain = str(domain)
    if quota.strip() == '':
        quota = 0
    else:
        quota = int(quota)
    username = removeSpaceAndDot(str(username))
    if cn.strip() == '': cn = username
    mail = username.lower() + '@' + domain
    dn = convEmailToUserDN(mail)
    if groups.strip() != '':
        groups = groups.strip().split(':')
        print groups
        for i in range(len(groups)):
            groups[i] = groups[i] + '@' + domain
        print groups

    if HASHED_MAILDIR is True:
        # Hashed. Length of domain name are always >= 2.
        maildir_domain = "%s/%s/%s/" % (domain[:1], domain[:2], domain)
        if len(username) >= 3:
            maildir_user = "%s/%s/%s/%s/" % (username[:1], username[:2], username[:3], username)
        elif len(username) == 2:
            maildir_user = "%s/%s/%s/%s/" % (
                    username[:1],
                    username[:],
                    username[:] + username[-1],
                    username,
                    )
        else:
            maildir_user = "%s/%s/%s/%s/" % (
                    username[0],
                    username[0] * 2,
                    username[0] * 3,
                    username,
                    )
        mailMessageStore = maildir_domain + maildir_user
    else:
        mailMessageStore = "%s/%s/" % (domain, username)

    homeDirectory = STORAGE_BASE_DIRECTORY + '/' + mailMessageStore

    ldif = [
        ('objectCLass',         ['inetOrgPerson', 'mailUser', 'shadowAccount']),
        ('mail',                [mail]),
        ('userPassword',        [str(passwd)]),
        ('mailQuota',           [str(quota)]),
        ('cn',                  [cn]),
        ('sn',                  [username]),
        ('uid',                 [username]),
        ('storageBaseDirectory', [STORAGE_BASE_DIRECTORY]),
        ('mailMessageStore',    [mailMessageStore]),
        ('homeDirectory',       [homeDirectory]),
        ('accountStatus',       ['active']),
        ('mtaTransport',        ['dovecot']),
        ('enabledService',      ['mail', 'smtp', 'pop3', 'imap', 'deliver', 'forward',
                                'senderbcc', 'recipientbcc', 'managesieve',
                                'displayedInGlobalAddressBook',]),
        ('memberOfGroup',       groups),
        ]

    print ldif
    return dn, ldif

if len(sys.argv) != 2 or len(sys.argv) > 2:
    print """Usage: $ python %s users.csv""" % ( sys.argv[0] )
    usage()
    sys.exit()
else:
    CSV = sys.argv[1]
    if not os.path.exists(CSV):
        print '''Erorr: file not exist:''', CSV
        sys.exit()

ldif_file = CSV + '.ldif'

# Remove exist LDIF file.
if os.path.exists(ldif_file):
    print '''Remove exist file:''', ldif_file
    os.remove(ldif_file)

# Read user list.
userList = open(CSV, 'r')

# Convert to LDIF format.
for entry in userList.readlines():
    domain, username, passwd, cn, quota, groups = entry.split(',')
    dn, data = ldif_mailuser(domain, username, passwd, cn, quota, groups)

    # Write LDIF data.
    result = open(ldif_file, 'a')
    ldif_writer=ldif.LDIFWriter(result)
    ldif_writer.unparse(dn, data)

# Prompt to import user data.
'''
print """User data are store in %s, you can verify it before import it.
Would you like to import them now?""" % (ldif_file)

answer = raw_input('[Y|n] ').lower().strip()

if answer == '' or answer == 'y':
    # Import data.
    conn = ldap.initialize(LDAP_URI)
    conn.set_option(ldap.OPT_PROTOCOL_VERSION, 3)   # Use LDAP v3
    conn.bind_s(BINDDN, BINDPW)
    conn.unbind()
else:
    pass
'''
