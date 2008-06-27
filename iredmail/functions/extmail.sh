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
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${EXTSUITE_HTTPD_ROOT}/extmail/
    chmod -R 0755 ${EXTSUITE_HTTPD_ROOT}
    chmod 0000 ${EXTSUITE_HTTPD_ROOT}/extmail/{AUTHORS,ChangeLog,CREDITS,dispatch.*,INSTALL,README.*}

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
ServerName $(hostname)

DocumentRoot /var/www/html/

ScriptAlias /extmail/cgi /var/www/extsuite/extmail/cgi
Alias /extmail /var/www/extsuite/extmail/html

Alias /mail /var/www/extsuite/extmail/html
Alias /webmail /var/www/extsuite/extmail/html

SuexecUserGroup ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
</VirtualHost>
EOF

    ECHO_INFO "Basic configuration for ExtMail."
    cd ${EXTSUITE_HTTPD_ROOT}/extmail/
    cp webmail.cf.default webmail.cf

    perl -pi -e 's#(SYS_USER_LANG.*)en_US#${1}$ENV{'SYS_USER_LANG'}#' webmail.cf

    perl -pi -e 's#(SYS_MAILDIR_BASE.*)/home/domains#${1}$ENV{'VMAIL_USER_HOME_DIR'}#' webmail.cf

    ECHO_INFO "Fix incorrect quota display."
    cd ${EXTSUITE_HTTPD_ROOT}/extmail/libs/Ext/
    perl -pi -e 's#(.*mailQuota})(.*0S.*)#${1}*1024${2}#' App.pm

    #ECHO_INFO "Enable USER_LANG."
    #perl -pi -e 's/#(.*lang.*usercfg.*lang.*USER_LANG.*)/${1}/' App.pm

    ECHO_INFO "Disable some functions we don't support yet."
    cd ${EXTSUITE_HTTPD_ROOT}/extmail/html/default/
    perl -pi -e 's#(.*filter.cgi.*)#\<\!--${1}--\>#' OPTION_NAV.html

    echo 'export status_extmail_config_basic="DONE"' >> ${STATUS_FILE}
}

extmail_config_mysql()
{
    ECHO_INFO "Install dependences for MySQL support in perl."
    install_pkg libdbi-dbd-mysql perl-DBD-mysql

    ECHO_INFO "Configure ExtMail for MySQL support.."
    cd ${EXTSUITE_HTTPD_ROOT}/extmail/

    perl -pi -e 's#(SYS_MYSQL_USER.*)db_user#${1}$ENV{'MYSQL_ADMIN_USER'}#' webmail.cf
    perl -pi -e 's#(SYS_MYSQL_PASS.*)db_pass#${1}$ENV{'MYSQL_ADMIN_PW'}#' webmail.cf
    perl -pi -e 's#(SYS_MYSQL_DB.*)extmail#${1}$ENV{'VMAIL_DB'}#' webmail.cf
    perl -pi -e 's/^(SYS_MYSQL_ATTR_CLEARPW.*)/#${1}/' webmail.cf

    echo 'export status_extmail_config_mysql="DONE"' >> ${STATUS_FILE}
}

extmail_config_ldap()
{
    ECHO_INFO "Install dependences for LDAP support in perl."
    install_pkg perl-LDAP

    ECHO_INFO "Configure ExtMail for LDAP support."
    cd ${EXTSUITE_HTTPD_ROOT}/extmail/

    perl -pi -e 's#(SYS_AUTH_TYPE.*)mysql#${1}ldap#' webmail.cf
    perl -pi -e 's#(SYS_LDAP_BASE)(.*)#${1} = $ENV{'LDAP_BASEDN'}#' webmail.cf
    perl -pi -e 's#(SYS_LDAP_RDN)(.*)#${1} = $ENV{'LDAP_ADMIN_DN'}#' webmail.cf
    perl -pi -e 's#(SYS_LDAP_PASS.*=)(.*)#${1} $ENV{'LDAP_ADMIN_PW'}#' webmail.cf
    perl -pi -e 's#(SYS_LDAP_HOST.*=)(.*)#${1} $ENV{'LDAP_SERVER_HOST'}#' webmail.cf

    perl -pi -e 's#(SYS_LDAP_ATTR_DOMAIN.*=)(.*)#${1} o#' webmail.cf

    perl -pi -e 's/^(SYS_LDAP_ATTR_CLEARPW.*)/#${1}/' webmail.cf
    #perl -pi -e 's/^(SYS_LDAP_ATTR_NDQUOTA.*)/#${1}/' webmail.cf
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLEWEBMAIL.*)/#${1}/' webmail.cf
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLENETDISK.*)/#${1}/' webmail.cf
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLEPWDCHANGE.*)/#${1}/' webmail.cf

    perl -pi -e 's#(SYS_LDAP_ATTR_ACTIVE.*=)(.*)#${1} accountStatus#' webmail.cf

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
        - ${EXTSUITE_HTTPD_ROOT}/extmail/webmail.cf
    * Reference:
        - ${HTTPD_CONF_DIR}/extmail.conf
    * URL:
        - $(hostname)/mail
        - $(hostname)/webmail
EOF

    echo 'export status_extmail_config="DONE"' >> ${STATUS_FILE}
}
