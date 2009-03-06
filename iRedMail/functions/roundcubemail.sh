#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -----------------------
# Roundcube.
# -----------------------
rcm_install()
{
    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${RCM_TARBALL} ${HTTPD_SERVERROOT}

    ECHO_INFO "Set correct permission for Roundcubemail: ${RCM_HTTPD_ROOT}."
    chown -R root:root ${RCM_HTTPD_ROOT}
    chown -R apache:apache ${RCM_HTTPD_ROOT}/{temp,logs}
    chmod 0000 ${RCM_HTTPD_ROOT}/{CHANGELOG,INSTALL,LICENSE,README,UPGRADING,installer,SQL}

    echo 'export status_rcm_install="DONE"' >> ${STATUS_FILE}
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
    cp -f db.inc.php.dist db.inc.php
    cp -f main.inc.php.dist main.inc.php

    cd ${RCM_HTTPD_ROOT}/config/

    export RCM_DB_USER RCM_DB_PASSWD RCMD_DB MYSQL_SERVER 

    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"mysqli://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'RCM_DB'}";#' db.inc.php

    # Disable installer.
    perl -pi -e 's#(.*enable_installer.*= )(.*)#${1}FALSE;#' main.inc.php
    perl -pi -e 's#(.*check_all_folders.*= )(.*)#${1}TRUE;#' main.inc.php

    perl -pi -e 's#(.*default_host.*= )(.*)#${1}"$ENV{'IMAP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_server.*= )(.*)#${1}"$ENV{'SMTP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_user.*= )(.*)#${1}"%u";#' main.inc.php
    perl -pi -e 's#(.*smtp_pass.*= )(.*)#${1}"%p";#' main.inc.php
    perl -pi -e 's#(.*smtp_auth_type.*= )(.*)#${1}"LOGIN";#' main.inc.php
    perl -pi -e 's#(.*create_default_folders.*)(FALSE)(.*)#${1}TRUE${3}#' main.inc.php

    # Set defeault domain.
    export FIRST_DOMAIN
    perl -pi -e 's#(.*username_domain.*=)(.*)#${1} "$ENV{'FIRST_DOMAIN'}";#' main.inc.php
    perl -pi -e 's#(.*locale_string.*)(en)(.*)#${1}$ENV{'DEFAULT_LANG'}${3}#' main.inc.php
    perl -pi -e 's#(.*timezone.*=).*#${1} 8;#' main.inc.php
    perl -pi -e 's#(.*enable_spellcheck.*=).*#${1} FALSE;#' main.inc.php
    perl -pi -e 's#(.*default_charset.*=).*#${1} "UTF-8";#' main.inc.php

    # Set useragent, add project info.
    perl -pi -e 's#(.*useragent.*=).*#${1} "RoundCube WebMail";#' main.inc.php

    # Disable multiple identities.
    perl -pi -e 's#(.*identities_level.*=).*#${1} 3;#' main.inc.php

    # Enable preview pane by default.
    perl -pi -e 's#(.*preview_pane.*=).*#${1} TRUE;#' main.inc.php

    # Log file related.
    perl -pi -e 's#(.*log_driver.*=).*#${1} "syslog";#' main.inc.php
    perl -pi -e 's#(.*syslog_id.*=).*#${1} "roundcube";#' main.inc.php
    perl -pi -e 's#(.*syslog_facility.*=).*#${1} "LOG_USER";#' main.inc.php
    perl -pi -e 's#(.*log_logins.*=).*#${1} TRUE;#' main.inc.php

    ECHO_INFO "Create directory alias for Roundcubemail."
    cat > ${HTTPD_CONF_DIR}/roundcubemail.conf <<EOF
${CONF_MSG}
Alias /mail "${RCM_HTTPD_ROOT}/"
Alias /webmail "${RCM_HTTPD_ROOT}/"
Alias /roundcube "${RCM_HTTPD_ROOT}/"
<Directory "${RCM_HTTPD_ROOT}/">
    Options -Indexes
</Directory>
EOF

    # Make Roundcube can be accessed via HTTPS.
    sed -i 's#\(</VirtualHost>\)#Alias /mail '${RCM_HTTPD_ROOT}'/\n\1#' ${HTTPD_SSL_CONF}
    sed -i 's#\(</VirtualHost>\)#Alias /webmail '${RCM_HTTPD_ROOT}'/\n\1#' ${HTTPD_SSL_CONF}
    sed -i 's#\(</VirtualHost>\)#Alias /roundcube '${RCM_HTTPD_ROOT}'/\n\1#' ${HTTPD_SSL_CONF}

    #ECHO_INFO "Patch: Display Username."
    #cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    #patch -p0 < ${PATCH_DIR}/roundcubemail/display_username.patch >/dev/null && \
    #patch -p0 < ${PATCH_DIR}/roundcubemail/display_username_skin_default.patch >/dev/null

    ECHO_INFO "Patch: Fix 'Undefined index' error in 0.2-stable."
    cd ${RCM_HTTPD_ROOT}/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/0.2-stable_undefined_index_error.patch >/dev/null

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        #ECHO_INFO "Patch: Change LDAP password."
        #cd ${RCM_HTTPD_ROOT}/ && \
        #patch -p1 < ${PATCH_DIR}/roundcubemail/0.2-stable_change_ldap_passwd.patch >/dev/null

        ECHO_INFO "Setting global LDAP address book in Roundcube."

        # Remove PHP end of file mark first.
        cd ${RCM_HTTPD_ROOT}/config/ && perl -pi -e 's#\?\>##' main.inc.php

        cat >> main.inc.php <<EOF
# Global LDAP Address Book.
\$rcmail_config['ldap_public']["${RCM_ADDRBOOK_NAME}"] = array(
    'name'          => 'Global Address Book',
    'hosts'         => array("${LDAP_SERVER_HOST}"),
    'port'          => ${LDAP_SERVER_PORT},
    'use_tls'       => false,
    //'user_specific' => true, // If true the base_dn, bind_dn and bind_pass default to the user's IMAP login.
    //'base_dn'       => "${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}",
    'base_dn'       => "${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}",
    'bind_dn'       => "${LDAP_BINDDN}",
    'bind_pass'     => "${LDAP_BINDPW}",
    'writable'      => false, // Indicates if we can write to the LDAP directory or not.
    // If writable is true then these fields need to be populated:
    // LDAP_Object_Classes, required_fields, LDAP_rdn
    //'LDAP_Object_Classes' => array("top", "inetOrgPerson", "${LDAP_OBJECTCLASS_USER}"), // To create a new contact these are the object classes to specify (or any other classes you wish to use).
    //'required_fields'     => array("cn", "sn", "mail"),     // The required fields needed to build a new contact as required by the object classes (can include additional fields not required by the object classes).
    //'LDAP_rdn'      => "${LDAP_ATTR_USER_DN_NAME}", // The RDN field that is used for new entries, this field needs to be one of the search_fields, the base of base_dn is appended to the RDN to insert into the LDAP directory.
    'ldap_version'  => "${LDAP_BIND_VERSION}",       // using LDAPv3
    'search_fields' => array('mail', 'cn', 'gn', 'sn'),  // fields to search in
    'name_field'    => 'cn',    // this field represents the contact's name
    'email_field'   => 'mail',  // this field represents the contact's e-mail
    'surname_field' => 'sn',    // this field represents the contact's last name
    'firstname_field' => 'gn',  // this field represents the contact's first name
    'sort'          => 'cn',    // The field to sort the listing by.
    'scope'         => 'sub',   // search mode: sub|base|list
    'filter'        => "(&(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER}))",
    'fuzzy_search'  => true);   // server allows wildcard search

// end of config file
?>
EOF
        # List global address book in autocomplete_addressbooks.
        perl -pi -e 's#(.*autocomplete_addressbooks.*=)(.*)#${1} array("sql", "$ENV{'RCM_ADDRBOOK_NAME'}");#' main.inc.php

    elif [ X"${BACKEND}" == X"MySQL" ]; then
        #ECHO_INFO "Patch: Change MySQL password and mail forwarding setting."
        :
    else
        :
    fi

    # Log file related.
    ECHO_INFO "Setting up syslog configration file for Roundcube."
    echo -e "user.*\t\t\t\t\t\t-${RCM_LOGFILE}" >> ${SYSLOG_CONF}

    touch ${RCM_LOGFILE}
    chown root:root ${RCM_LOGFILE}
    chmod 0600 ${RCM_LOGFILE}

    ECHO_INFO "Setting logrotate for roundcube log file."
    cat > ${RCM_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${RCM_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 root root
    missingok

    # Use bzip2 for compress.
    compresscmd $(which bzip2)
    uncompresscmd $(which bunzip2)
    compressoptions -9
    compressext .bz2 

    postrotate
        /usr/bin/killall -HUP syslogd
    endscript
}
EOF

    cat >> ${TIP_FILE} <<EOF
WebMail(Roundcubemail):
    * Configuration files:
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/config/
    * URL:
        - http://${HOSTNAME}/mail/
        - http://${HOSTNAME}/webmail/
    * Log file related:
        - ${SYSLOG_CONF}
        - ${RCM_LOGFILE}
        - ${RCM_LOGROTATE_FILE}
    * See also:
        - ${HTTPD_CONF_DIR}/roundcubemail.conf

EOF

    echo 'export status_rcm_config="DONE"' >> ${STATUS_FILE}
}
