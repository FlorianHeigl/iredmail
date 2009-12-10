#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -----------------------
# Roundcube.
# -----------------------
rcm_install()
{
    ECHO_INFO "==================== Roundcube Webmail ===================="

    if [ X"${DISTRO}" != X"FREEBSD" ]; then
        cd ${MISC_DIR}

        # Extract source tarball.
        extract_pkg ${RCM_TARBALL} ${HTTPD_SERVERROOT}

        # Create symbol link, so that we don't need to modify apache
        # conf.d/roundcubemail.conf file after upgrade this component.
        ln -s ${RCM_HTTPD_ROOT} ${RCM_HTTPD_ROOT_SYMBOL_LINK} 2>/dev/null

        ECHO_INFO "Set correct permission for Roundcubemail: ${RCM_HTTPD_ROOT}."
        chown -R ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${RCM_HTTPD_ROOT}
        chown -R ${HTTPD_USER}:${HTTPD_GROUP} ${RCM_HTTPD_ROOT}/{temp,logs}
        chmod 0000 ${RCM_HTTPD_ROOT}/{CHANGELOG,INSTALL,LICENSE,README,UPGRADING,installer,SQL}
    fi

    # Patches.
    if [ X"${DISTRO}" != X"FREEBSD" ]; then
        # Patch for roundcube-0.3.1 only.
        cd ${RCM_HTTPD_ROOT}/
        patch -p0 < ${PATCH_DIR}/roundcubemail/managesieve_rule_width_on_safari.patch >/dev/null 2>&1
    fi

    cd ${RCM_HTTPD_ROOT}/config/
    cp -f db.inc.php.dist db.inc.php
    cp -f main.inc.php.dist main.inc.php

    echo 'export status_rcm_install="DONE"' >> ${STATUS_FILE}
}

rcm_config_managesieve()
{
    ECHO_INFO "Enable and config plugin: managesieve."
    cd ${RCM_HTTPD_ROOT}/config/ && \
    perl -pi -e 's#(.*rcmail_config.*plugins.*=.*array\()(.*\).*)#${1}"managesieve",${2}#' main.inc.php

    export MANAGESIEVE_BINDADDR MANAGESIEVE_PORT
    cd ${RCM_HTTPD_ROOT}/plugins/managesieve/ && \
    cp config.inc.php.dist config.inc.php && \
    perl -pi -e 's#(.*managesieve_port.*=).*#${1} $ENV{'MANAGESIEVE_PORT'};#' config.inc.php
    perl -pi -e 's#(.*managesieve_host.*=).*#${1} "$ENV{'MANAGESIEVE_BINDADDR'}";#' config.inc.php
    perl -pi -e 's#(.*managesieve_usetls.*=).*#${1} false;#' config.inc.php
    perl -pi -e 's#(.*managesieve_default.*=).*#${1} "$ENV{GLOBAL_SIEVE_FILE}";#' config.inc.php

    echo 'export status_rcm_config_managesieve="DONE"' >> ${STATUS_FILE}
}

rcm_config_password()
{
    ECHO_INFO "Enable and config plugin: password."
    cd ${RCM_HTTPD_ROOT}/config/ && \
    perl -pi -e 's#(.*rcmail_config.*plugins.*=.*array\()(.*\).*)#${1}"password",${2}#' main.inc.php

    cd ${RCM_HTTPD_ROOT}/plugins/password/ && \
    cp config.inc.php.dist config.inc.php

    perl -pi -e 's#(.*password_confirm_current.*=).*#${1} true;#' config.inc.php
    perl -pi -e 's#(.*password_minimum_length.*=).*#${1} 6;#' config.inc.php
    perl -pi -e 's#(.*password_require_nonalpha.*=).*#${1} false;#' config.inc.php

    if [ X"${BACKEND}" == X"MySQL" ]; then
        perl -pi -e 's#(.*password_driver.*=).*#${1} "sql";#' config.inc.php
    elif [ X"${BACKEND}" == X"OpenLDAP" ]; then
        perl -pi -e 's#(.*password_driver.*=).*#${1} "ldap";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_host.*=).*#${1} "$ENV{LDAP_SERVER_HOST}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_port.*=).*#${1} "$ENV{LDAP_SERVER_PORT}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_starttls.*=).*#${1} false;#' config.inc.php
        perl -pi -e 's#(.*password_ldap_version.*=).*#${1} "3";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_basedn...=).*#${1} "$ENV{LDAP_BASEDN}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_method.*=).*#${1} "user";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_adminDN.*=).*#${1} "null";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_adminPW.*=).*#${1} "null";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_userDN_mask...=).*#${1} "$ENV{LDAP_ATTR_USER_RDN}=%login,$ENV{LDAP_ATTR_GROUP_RDN}=$ENV{LDAP_ATTR_GROUP_USERS},$ENV{LDAP_ATTR_DOMAIN_RDN}=%domain,$ENV{LDAP_BASEDN}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_encodage.*=).*#${1} "ssha";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_pwattr.*=).*#${1} "userPassword";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_force_replace.*=).*#${1} false;#' config.inc.php
    else
        :
    fi

    echo 'export status_rcm_config_password="DONE"' >> ${STATUS_FILE}
}

rcm_config()
{
    ECHO_INFO "Import MySQL database and privileges for Roundcubemail."

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
/* Create database and grant privileges. */
CREATE DATABASE ${RCM_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${RCM_DB}.* TO ${RCM_DB_USER}@localhost IDENTIFIED BY '${RCM_DB_PASSWD}';


/* Import Roundcubemail SQL template. */
USE ${RCM_DB};
SOURCE ${RCM_HTTPD_ROOT}/SQL/mysql.initial.sql;

FLUSH PRIVILEGES;
EOF

    # Do not grant privileges while backend is not MySQL.
    if [ X"${BACKEND}" == X"MySQL" ]; then
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
/*
  Grant privileges for Roundcubemail, so that user can change
  their own password and setting mail forwarding.
*/
GRANT UPDATE,SELECT ON ${VMAIL_DB}.mailbox TO ${RCM_DB_USER}@localhost;
GRANT INSERT,UPDATE,SELECT ON ${VMAIL_DB}.alias TO ${RCM_DB_USER}@localhost;

FLUSH PRIVILEGES;
EOF
    else
        :
    fi

    ECHO_INFO "Configure database for Roundcubemail: ${RCM_HTTPD_ROOT}/config/*."

    cd ${RCM_HTTPD_ROOT}/config/

    export RCM_DB_USER RCM_DB_PASSWD RCMD_DB MYSQL_SERVER 

    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"mysqli://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'RCM_DB'}";#' db.inc.php

    # Disable installer.
    perl -pi -e 's#(.*enable_installer.*= )(.*)#${1}FALSE;#' main.inc.php

    # Log file related.
    perl -pi -e 's#(.*log_driver.*=).*#${1} "syslog";#' main.inc.php
    perl -pi -e 's#(.*syslog_id.*=).*#${1} "roundcube";#' main.inc.php
    # syslog_facility should be a constant, not string. (Do *NOT* use quote.)
    perl -pi -e 's#(.*syslog_facility.*=).*#${1} LOG_MAIL;#' main.inc.php
    perl -pi -e 's#(.*log_logins.*=).*#${1} TRUE;#' main.inc.php

    # Automatically create a new ROUNDCUBE USER when log-in the first time.
    perl -pi -e 's#(.*auto_create_user.*= )(.*)#${1}TRUE;#' main.inc.php

    # Set defeault domain.
    export FIRST_DOMAIN
    #perl -pi -e 's#(.*imap_auth_type.*= )(.*)#${1}"check";#' main.inc.php
    perl -pi -e 's#(.*username_domain.*=)(.*)#${1} "$ENV{'FIRST_DOMAIN'}";#' main.inc.php

    # SMTP server setting.
    perl -pi -e 's#(.*default_host.*= )(.*)#${1}"$ENV{'IMAP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_server.*= )(.*)#${1}"$ENV{'SMTP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_user.*= )(.*)#${1}"%u";#' main.inc.php
    perl -pi -e 's#(.*smtp_pass.*= )(.*)#${1}"%p";#' main.inc.php
    #perl -pi -e 's#(.*smtp_auth_type.*= )(.*)#${1}"LOGIN";#' main.inc.php

    # Set default language and charset..
    perl -pi -e 's#(.*language.*= )(.*)#${1}"$ENV{'DEFAULT_LANG'}";#' main.inc.php
    perl -pi -e 's#(.*default_charset.*=).*#${1} "UTF-8";#' main.inc.php
    # Set timezone for Chinese users.
    [ X"${DEFAULT_LANG}" == X"zh_CN" -o X"${DEFAULT_LANG}" == X"zh_TW" ] && perl -pi -e 's#(.*timezone.*=).*#${1} 8;#' main.inc.php

    # Set useragent, add project info.
    perl -pi -e 's#(.*useragent.*=).*#${1} "RoundCube WebMail";#' main.inc.php

    # Spellcheck.
    perl -pi -e 's#(.*enable_spellcheck.*=).*#${1} FALSE;#' main.inc.php

    # Check all folders for recent messages.
    perl -pi -e 's#(.*check_all_folders.*=)(.*)#${1} TRUE;#' main.inc.php

    # Automatic create and protect default IMAP folders.
    perl -pi -e 's#(.*create_default_folders.*=)(.*)#${1} TRUE;#' main.inc.php
    perl -pi -e 's#(.*protect_default_folders.*=)(.*)#${1} TRUE;#' main.inc.php

    # Quota zero as unlimited.
    perl -pi -e 's#(.*quota_zero_as_unlimited.*=)(.*)#${1} TRUE;#' main.inc.php

    # Attachment name type: Outlook style.
    perl -pi -e 's#(.*mime_param_folding.*=).*#${1} 1;#' main.inc.php

    # Enable multiple identities.
    perl -pi -e 's#(.*identities_level.*=).*#${1} 0;#' main.inc.php

    # Enable preview pane by default.
    perl -pi -e 's#(.*preview_pane.*=).*#${1} TRUE;#' main.inc.php

    # Quota zero as unlimited, used to fit dovecot setting.
    perl -pi -e 's#(.*quota_zero_as_unlimited.*=).*#${1} TRUE;#' main.inc.php

    # Sort messages list by message index instead of message date.
    perl -pi -e 's#(.*index_sort.*=).*#${1} TRUE;#' main.inc.php

    # Delete always.
    # This make client users confused why mail not been deleted as 'EXPECT'.
    perl -pi -e 's#(.*delete_always.*=).*#${1} TRUE;#' main.inc.php

    ECHO_INFO "Create directory alias for Roundcubemail."
    cat > ${HTTPD_CONF_DIR}/roundcubemail.conf <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
Alias /mail "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
Alias /webmail "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
Alias /roundcube "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
<Directory "${RCM_HTTPD_ROOT_SYMBOL_LINK}/">
    Options -Indexes
</Directory>
EOF

    # Make Roundcube can be accessed via HTTPS.
    perl -pi -e 's#(</VirtualHost>)#Alias /mail "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}
    perl -pi -e 's#(</VirtualHost>)#Alias /webmail "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}
    perl -pi -e 's#(</VirtualHost>)#Alias /roundcube "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}

    ECHO_INFO "Patch: Display Username."
    perl -pi -e 's#(.*taskbar">)#${1}\n<span style="padding-right: 3px;"><roundcube:object name="username" /></span>#' ${RCM_HTTPD_ROOT}/skins/default/includes/taskbar.html

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        export LDAP_SERVER_HOST LDAP_SERVER_PORT LDAP_BIND_VERSION LDAP_BASEDN LDAP_ATTR_DOMAIN_RDN LDAP_ATTR_USER_RDN
        cd ${RCM_HTTPD_ROOT}/config/
        ECHO_INFO "Setting global LDAP address book in Roundcube."

        # Remove PHP end of file mark first.
        cd ${RCM_HTTPD_ROOT}/config/ && perl -pi -e 's#\?\>##' main.inc.php

        cat >> main.inc.php <<EOF
# Global LDAP Address Book. Contains domain users.
\$rcmail_config['ldap_public']["${FIRST_DOMAIN}"] = array(
    'name'          => 'Global Address Book',
    'hosts'         => array("${LDAP_SERVER_HOST}"),
    'port'          => ${LDAP_SERVER_PORT},
    'use_tls'       => false,

    // ---- Used to search accounts only in the same domain. ----
    'user_specific' => true, // If true the base_dn, bind_dn and bind_pass default to the user's IMAP login.
    'base_dn'       => "${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}",
    'bind_dn'       => "${LDAP_ATTR_USER_RDN}=%u@%d,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}",

    // ---- Uncomment below lines to search whole LDAP tree ----
    //'base_dn'       => "${LDAP_BASEDN}",
    //'bind_dn'       => "${LDAP_BINDDN}",
    //'bind_pass'     => "${LDAP_BINDPW}",

    'writable'      => false, // Indicates if we can write to the LDAP directory or not.
    // If writable is true then these fields need to be populated:
    // LDAP_Object_Classes, required_fields, LDAP_rdn
    //'LDAP_Object_Classes' => array("top", "inetOrgPerson", "${LDAP_OBJECTCLASS_MAILUSER}"), // To create a new contact these are the object classes to specify (or any other classes you wish to use).
    //'required_fields'     => array("cn", "sn", "mail"),     // The required fields needed to build a new contact as required by the object classes (can include additional fields not required by the object classes).
    //'LDAP_rdn'      => "${LDAP_ATTR_USER_RDN}", // The RDN field that is used for new entries, this field needs to be one of the search_fields, the base of base_dn is appended to the RDN to insert into the LDAP directory.
    'ldap_version'  => "${LDAP_BIND_VERSION}",       // using LDAPv3
    'search_fields' => array('mail', 'cn', 'givenName', 'sn'),  // fields to search in
    'name_field'    => 'cn',    // this field represents the contact's name
    'email_field'   => 'mail',  // this field represents the contact's e-mail
    'surname_field' => 'sn',    // this field represents the contact's last name
    'firstname_field' => 'givenName',  // this field represents the contact's first name
    'sort'          => 'cn',    // The field to sort the listing by.
    'scope'         => 'sub',   // search mode: sub|base|list
    'filter'        => "(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DISPLAYED_IN_ADDRBOOK})(|(&(objectClass=${LDAP_OBJECTCLASS_MAILGROUP})(${LDAP_ATTR_GROUP_HASMEMBER}=${LDAP_VALUE_GROUP_HASMEMBER}))(objectClass=${LDAP_OBJECTCLASS_MAILALIAS})(objectClass=${LDAP_OBJECTCLASS_MAILUSER})))", // Search mail users, lists, aliases.
    'fuzzy_search'  => true);   // server allows wildcard search

// end of config file
?>
EOF

        # List global address book in autocomplete_addressbooks, contains domain users and groups.
        perl -pi -e 's#(.*autocomplete_addressbooks.*=)(.*)#${1} array("sql", "$ENV{'FIRST_DOMAIN'}");#' main.inc.php

    #elif [ X"${BACKEND}" == X"MySQL" ]; then
        # Set correct username, password and database name.
    #    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"mysqli://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'VMAIL_DB'}";#' plugins/changepasswd/config.inc.php
    else
        :
    fi

    # Log file related.
    #ECHO_INFO "Setting up syslog configration file for Roundcube."
    #echo -e "user.*\t\t\t\t\t\t-${RCM_LOGFILE}" >> ${SYSLOG_CONF}

    #touch ${RCM_LOGFILE}
    #chown ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${RCM_LOGFILE}
    #chmod 0600 ${RCM_LOGFILE}

    cat >> ${TIP_FILE} <<EOF
WebMail(Roundcubemail):
    * Configuration files:
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/config/
    * URL:
        - http://${HOSTNAME}/mail/
        - http://${HOSTNAME}/webmail/
    * Login account:
        - Username: ${FIRST_USER}@${FIRST_DOMAIN}, password: ${FIRST_USER_PASSWD_PLAIN}
    * See also:
        - ${HTTPD_CONF_DIR}/roundcubemail.conf

EOF

    echo 'export status_rcm_config="DONE"' >> ${STATUS_FILE}
}
