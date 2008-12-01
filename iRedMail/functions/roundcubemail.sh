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

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
/* Create database and grant privileges. */
CREATE DATABASE ${RCM_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${RCM_DB}.* TO ${RCM_DB_USER}@localhost IDENTIFIED BY '${RCM_DB_PASSWD}';


/* Import Roundcubemail SQL template. */
USE ${RCM_DB};
SOURCE ${RCM_HTTPD_ROOT}/SQL/mysql5.initial.sql;

FLUSH PRIVILEGES;
EOF

    # Do not grant privileges while backend is not MySQL.
    if [ X"${BACKEND}" == X"MySQL" ]; then
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
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

    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"mysql://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'RCM_DB'}";#' db.inc.php

    perl -pi -e 's#(.*default_host.*= )(.*)#${1}"$ENV{'IMAP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_server.*= )(.*)#${1}"$ENV{'SMTP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_user.*= )(.*)#${1}"%u";#' main.inc.php
    perl -pi -e 's#(.*smtp_pass.*= )(.*)#${1}"%p";#' main.inc.php
    perl -pi -e 's#(.*smtp_auth_type.*= )(.*)#${1}"LOGIN";#' main.inc.php
    perl -pi -e 's#(.*create_default_folders.*)(FALSE)(.*)#${1}TRUE${3}#' main.inc.php

    # Set defeault domain.
    perl -pi -e 's#(.*username_domain.*=)(.*)#${1} "$ENV{FIRST_DOMAIN}";#' main.inc.php
    perl -pi -e 's#(.*locale_string.*)(en)(.*)#${1}$ENV{RCM_DEFAULT_LOCALE}${3}#' main.inc.php
    perl -pi -e 's#(.*timezone.*)(intval.*)#${1}8; //${2}#' main.inc.php
    perl -pi -e 's#(.*enable_spellcheck.*)(TRUE)(.*)#${1}FALSE${3}#' main.inc.php
    perl -pi -e 's#(.*default_charset.*=)(.*)#${1}"UTF-8";#' main.inc.php

    # Set useragent, add project info.
    perl -pi -e 's#(.*rcmail_config.*useragent.*=).*#${1} "RoundCube WebMail";#' main.inc.php

    # Disable multiple identities. roundcube-0.2 only.
    #perl -pi -e 's#(.*multiple_identities.*=).*true;#${1} false;#' main.inc.php

    ECHO_INFO "Create directory alias for Roundcubemail."
    cat > ${HTTPD_CONF_DIR}/roundcubemail.conf <<EOF
${CONF_MSG}
Alias /mail "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
Alias /webmail "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
Alias /roundcube "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
EOF

    # Roundcubemail-0.1.1 only.
    ECHO_INFO "Patch: Add missing localization items and fix incorrect items for zh_CN."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/zh_CN.labels.inc.patch >/dev/null

    ECHO_INFO "Patch: Fix IMAP folder name with Chinese characters."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_national_imap_folder_name.patch >/dev/null

    # This was fixed in roundcubemail-0.2.
    ECHO_INFO "Patch: Attachment display and save with Chiense characters."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_PEAR_Mail_Mail_Mime_addAttachment_basename.patch >/dev/null

    ECHO_INFO "Patch: Change Password and Setting Mail Forwarding."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_chpwd_forward.patch >/dev/null

    cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_chpwd_forward_skins.patch >/dev/null

    ECHO_INFO "Patch: Vacation plugin."
    # Create symbol link to sieve_dir.
    cd ${RCM_HTTPD_ROOT} && \
    ln -s ${SIEVE_DIR} sieve

    # Function patch: vacation.
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_vacation.patch >/dev/null

    # Skin patch: vacation.
    cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_vacation_skin_default.patch >/dev/null

    ECHO_INFO "Patch: Performance Improvement for Roundcubemail-0.1.1."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/performance-jh1.diff >/dev/null

    ECHO_INFO "Patch: Display Username."
    cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/display_username.patch >/dev/null && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/display_username_skin_default.patch >/dev/null

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        ECHO_INFO "Disable change password and mail forwarding featues."
        cd ${RCM_HTTPD_ROOT} && \
        perl -pi -e 's#(.*save-passwd.*)#//${1}#' index.php
        perl -pi -e 's#(.*include.*passwd.*)#//${1}#' index.php

        perl -pi -e 's#(.*save-forwards.*)#//${1}#' index.php
        perl -pi -e 's#(.*include.*forwards.*)#//${1}#' index.php

        ECHO_INFO "Setting global LDAP address book in Roundcube."
        cd ${RCM_HTTPD_ROOT}/config/ && \
        perl -pi -e 's#\?\>##' main.inc.php
        cat >> main.inc.php <<EOF
# Global LDAP Address Book.
\$rcmail_config['ldap_public']["${PROG_NAME}"] = array(
    'name'          => 'Global Address Book',
    'hosts'         => array("${LDAP_SERVER_HOST}"),
    'port'          => ${LDAP_SERVER_PORT},
    'base_dn'       => "${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN},${LDAP_BASEDN}",
    'bind_dn'       => "${LDAP_BINDDN}",
    'bind_pass'     => "${LDAP_BINDPW}",
    'ldap_version'  => "${LDAP_BIND_VERSION}",       // using LDAPv3
    'search_fields' => array('mail', 'cn'),  // fields to search in
    'name_field'    => 'cn',    // this field represents the contact's name
    'email_field'   => 'mail',  // this field represents the contact's e-mail
    'surname_field' => 'sn',    // this field represents the contact's last name
    'firstname_field' => 'gn',  // this field represents the contact's first name
    'scope'         => 'sub',   // search mode: sub|base|list
    'filter'        => "(&(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_STATUS}=active))",      // used for basic listing (if not empty) and will be &'d with search queries. example: status=act
    'fuzzy_search'  => true);   // server allows wildcard search

// end of config file
?>
EOF
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
WebMail(Roundcubemail):
    * Configuration files:
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/config/
    * URL:
        - http://$(hostname)/mail/
        - http://$(hostname)/webmail/
    * See also:
        - ${HTTPD_CONF_DIR}/roundcubemail.conf
        - ${RCM_HTTPD_ROOT}/skins/${rcm_skin_cn}

EOF

    echo 'export status_rcm_config="DONE"' >> ${STATUS_FILE}
}
