#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------
# Functions to install and configure ExtMail.
# -------------------------------------------

extmail_install()
{
    cd ${MISC_DIR}

    ECHO_INFO "Create necessary directory and extract ExtMail: ${EXTMAIL_TARBALL}..."
    [ -d ${EXTSUITE_HTTPD_ROOT} ] || mkdir -p ${EXTSUITE_HTTPD_ROOT}
    extract_pkg ${EXTMAIL_TARBALL} ${EXTSUITE_HTTPD_ROOT}
    cd ${EXTSUITE_HTTPD_ROOT} && mv extmail-${EXTMAIL_VERSION} extmail

    ECHO_INFO "Set correct permission for ExtMail: ${EXTSUITE_HTTPD_ROOT}."
    chown root:root ${EXTSUITE_HTTPD_ROOT}
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${EXTMAIL_HTTPD_ROOT}
    chmod -R 0755 ${EXTSUITE_HTTPD_ROOT}
    chmod 0000 ${EXTMAIL_HTTPD_ROOT}/{AUTHORS,ChangeLog,CREDITS,dispatch.*,INSTALL,README.*}

    ECHO_INFO "Patch ExtMail, make it create user maildir automatic."
    cd ${EXTMAIL_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/extmail/auto_create_maildir.patch >/dev/null 2>&1

    ECHO_INFO "Fix incorrect quota display."
    perl -pi -e 's#(.*ENV.*QUOTA.*mailQuota})(.*0S.*)#${1}*1024000${2}#' ${EXTMAIL_HTTPD_ROOT}/libs/Ext/App.pm

    echo 'export status_extmail_install="DONE"' >> ${STATUS_FILE}
}

extmail_config_basic()
{
    ECHO_INFO "Enable virtual host in Apache."
    perl -pi -e 's/#(NameVirtualHost)/${1}/' ${HTTPD_CONF}

    ECHO_INFO "Create Apache directory alias for ExtMail."
    cat > ${HTTPD_CONF_DIR}/extmail.conf <<EOF
${CONF_MSG}
<VirtualHost *:80>
    ServerName ${HOSTNAME}
    DocumentRoot ${HTTPD_DOCUMENTROOT}

    ScriptAlias /extmail/cgi ${EXTMAIL_HTTPD_ROOT}/cgi
    Alias /extmail ${EXTMAIL_HTTPD_ROOT}/html
EOF

    if [ X"${USE_RCM}" != X"YES" -a X"${USE_SM}" == X"YES" ]; then
        cat >> ${HTTPD_CONF_DIR}/extmail.conf <<EOF
    Alias /mail ${EXTMAIL_HTTPD_ROOT}/html
    Alias /webmail ${EXTMAIL_HTTPD_ROOT}/html
EOF
    else
        cat >> ${HTTPD_CONF_DIR}/extmail.conf <<EOF
    #Alias /mail ${EXTMAIL_HTTPD_ROOT}/html
    #Alias /webmail ${EXTMAIL_HTTPD_ROOT}/html
EOF
    fi

        cat >> ${HTTPD_CONF_DIR}/extmail.conf <<EOF
    SuexecUserGroup ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}

    <Directory "${EXTMAIL_HTTPD_ROOT}/">
        Options -Indexes
    </Directory>
    <Directory "${EXTMAIL_HTTPD_ROOT}/html/">
        Options -Indexes
    </Directory>
</VirtualHost>
EOF

    # Make ExtMail can be accessed via HTTPS.
    sed -i 's#\(</VirtualHost>\)#Alias /extmail '${EXTMAIL_HTTPD_ROOT}'/\n\1#' ${HTTPD_SSL_CONF}

    ECHO_INFO "Basic configuration for ExtMail."
    cd ${EXTMAIL_HTTPD_ROOT} && cp -f webmail.cf.default ${EXTMAIL_CONF}

    # Set default user language.
    perl -pi -e 's#(SYS_USER_LANG.*)en_US#${1}$ENV{'DEFAULT_LANG'}#' ${EXTMAIL_CONF}

    # Set mail attachment size.
    perl -pi -e 's#^(SYS_MESSAGE_SIZE_LIMIT.*=)(.*)#${1} $ENV{'MESSAGE_SIZE_LIMIT'}#' ${EXTMAIL_CONF}

    export VMAIL_USER_HOME_DIR
    perl -pi -e 's#(SYS_MAILDIR_BASE.*)/home/domains#${1}$ENV{VMAIL_USER_HOME_DIR}#' ${EXTMAIL_CONF}

    #ECHO_INFO "Enable USER_LANG."
    #perl -pi -e 's/#(.*lang.*usercfg.*lang.*USER_LANG.*)/${1}/' App.pm

    ECHO_INFO "Clear default account in global address book."
    echo '' > ${EXTMAIL_HTTPD_ROOT}/globabook.cf

    ECHO_INFO "Disable some functions we don't support yet."
    cd ${EXTMAIL_HTTPD_ROOT}/html/default/
    perl -pi -e 's#(.*filter.cgi.*)#\<\!--${1}--\>#' OPTION_NAV.html

    # For ExtMail-1.0.5. We don't have 'question/answer' field in SQL template, add it.
    if [ X"${BACKEND}" == X"MySQL" ]; then
        ECHO_INFO "Add missing SQL columns for ExtMail: mailbox.question, mailbox.answer."
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
USE ${VMAIL_DB};

ALTER TABLE mailbox ADD question text NOT NULL DEFAULT '';
ALTER TABLE mailbox ADD answer text NOT NULL DEFAULT '';
EOF
    else
        :
    fi

    echo 'export status_extmail_config_basic="DONE"' >> ${STATUS_FILE}
}

extmail_config_mysql()
{
    ECHO_INFO "Configure ExtMail for MySQL support.."
    cd ${EXTMAIL_HTTPD_ROOT}

    export MYSQL_SERVER
    export MYSQL_ADMIN_PW
    perl -pi -e 's#(SYS_MYSQL_USER.*)db_user#${1}$ENV{'MYSQL_ADMIN_USER'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_PASS.*)db_pass#${1}$ENV{'MYSQL_ADMIN_PW'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_DB.*)extmail#${1}$ENV{'VMAIL_DB'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_HOST.*)localhost#${1}$ENV{'MYSQL_SERVER'}#' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_MYSQL_ATTR_CLEARPW.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_ATTR_DISABLEWEBMAIL.*)disablewebmail#${1}disableimap#' ${EXTMAIL_CONF}

    echo 'export status_extmail_config_mysql="DONE"' >> ${STATUS_FILE}
}

extmail_config_ldap()
{
    ECHO_INFO "Configure ExtMail for LDAP support."
    cd ${EXTMAIL_HTTPD_ROOT}

    export LDAP_BASEDN LDAP_ADMIN_DN LDAP_ADMIN_PW LDAP_SERVER_HOST 
    perl -pi -e 's#(SYS_AUTH_TYPE.*)mysql#${1}ldap#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_BASE)(.*)#${1} = $ENV{'LDAP_BASEDN'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_RDN)(.*)#${1} = $ENV{'LDAP_ADMIN_DN'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_PASS.*=)(.*)#${1} $ENV{'LDAP_ADMIN_PW'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_HOST.*=)(.*)#${1} $ENV{'LDAP_SERVER_HOST'}#' ${EXTMAIL_CONF}

    export LDAP_ATTR_DOMAIN_DN_NAME LDAP_ATTR_USER_STATUS 
    perl -pi -e 's#(SYS_LDAP_ATTR_DOMAIN.*=)(.*)#${1} $ENV{'LDAP_ATTR_DOMAIN_DN_NAME'}#' ${EXTMAIL_CONF}

    perl -pi -e 's/^(SYS_LDAP_ATTR_CLEARPW.*)/#${1}/' ${EXTMAIL_CONF}
    #perl -pi -e 's/^(SYS_LDAP_ATTR_NDQUOTA.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLEWEBMAIL.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLENETDISK.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLEPWDCHANGE.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_ATTR_ACTIVE.*=)(.*)#${1} $ENV{'LDAP_ATTR_USER_STATUS'}#' ${EXTMAIL_CONF}

    # Disable password retrieve attributes.
    perl -pi -e 's/^(SYS_LDAP_ATTR_PWD_QUESTION.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_PWD_ANSWER.*)/#${1}/' ${EXTMAIL_CONF}

    echo 'export status_extmail_config_ldap="DONE"' >> ${STATUS_FILE}
}

extmail_config()
{
    check_status_before_run extmail_config_basic

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        check_status_before_run extmail_config_ldap
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        check_status_before_run extmail_config_mysql
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
ExtMail:
    * Configuration files:
        - ${EXTMAIL_CONF}
    * Reference:
        - ${HTTPD_CONF_DIR}/extmail.conf
    * URL:
        - ${HOSTNAME}/extmail
EOF

    echo 'export status_extmail_config="DONE"' >> ${STATUS_FILE}
}
