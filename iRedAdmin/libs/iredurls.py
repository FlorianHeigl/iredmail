#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import iredconf

urls_ldap = (
        # Make url ending with or without '/' going to the same class.
        "/(.*)/", "models.mbase.redirect",

        '/', 'models.mldap.login',
        '/login', 'models.mldap.login',
        '/logout', 'models.mldap.logout',
        '/preference/change_passwd', 'models.mldap.change_passwd',
        '/preferences', 'models.mldap.preferences',

        '/dashboard', 'models.mldap.dashboard',

        # Domain related.
        '/domain/list', 'models.mldap.domain_list',
        '/domain/add', 'models.mldap.domain_add',

        # Admin related.
        '/admin/list', 'models.mldap.admin_list',
        '/admin/add', 'models.mldap.admin_add',

        # User related.
        '/user/list', 'models.mldap.user_list',
        '/user/delete', 'models.mldap.user_delete',

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
