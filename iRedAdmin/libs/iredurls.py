#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import iredconf

urls_ldap = (
        # Make url ending with or without '/' going to the same class.
        "/(.*)/", "mbase.redirect",

        '/', 'mldap.login',
        '/login', 'mldap.login',
        '/logout', 'mldap.logout',
        '/preference/change_passwd', 'mldap.change_passwd',
        '/preferences', 'mldap.preferences',

        '/dashboard', 'mldap.dashboard',

        # Domain related.
        '/domain/list', 'mldap.domain_list',
        '/domain/add', 'mldap.domain_add',

        # Admin related.
        '/admin/list', 'mldap.admin_list',
        '/admin/add', 'mldap.admin_add',

        # User related.
        '/user/list', 'mldap.user_list',
        '/user/delete', 'mldap.user_delete',

        # Group related.
        '/group/list', 'mldap.group_list',

        # Policyd related spam control.
        '/antispam', 'libs.policyd.antispam',
        '/antispam/blacklist', 'libs.policyd.blacklist',
        '/antispam/whitelist', 'libs.policyd.whitelist',
        '/antispam/whitelist/add', 'libs.policyd.whitelist_add',
        )

urls_mysql = ()

if iredconf.BACKEND == 'ldap':
    urls = urls_ldap
else:
    urls = urls_mysql
