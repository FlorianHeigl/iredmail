# ---------------------------------------------------------
# SqruirrelMail.
# ---------------------------------------------------------
enable_sm_plugins()
{
    # We do *NOT* use 'conf.pl' to enable plugins, because it's not easy to
    # control in non-interactive mode, so we use 'perl' to modify the config
    # file directly.

    
    # Disable all exist plugins first.
    perl -pi -e 's|(^\$plugins.*)|#${1}|' ${SM_CONFIG}

    if [ ! -z "${ENABLED_SM_PLUGINS}" ]; then
        ECHO_INFO "Enable SquirrelMail plugins: ${ENABLED_SM_PLUGINS}."

        counter=0

        for i in ${ENABLED_SM_PLUGINS}; do
            echo "\$plugins[${counter}]='$(echo $i)';" >> ${SM_CONFIG}
            counter=$((counter+1))
        done
    else
        :
    fi

    echo 'export status_enable_sm_plugins="DONE"' >> ${STATUS_FILE}
}

sm_install()
{
    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${SM_TARBALL}

    ECHO_INFO "Move squirrelmail to httpd SERVERROOT: ${SM_HTTPD_ROOT}."
    mv squirrelmail-${SM_VERSION} ${SM_HTTPD_ROOT}

    ECHO_INFO "Set correct permission for squirrelmail: ${SM_HTTPD_ROOT}."
    chown -R apache:apache ${SM_HTTPD_ROOT}
    chmod -R 755 ${SM_HTTPD_ROOT}
    chmod 0000 ${SM_HTTPD_ROOT}/{AUTHORS,ChangeLog,COPYING,INSTALL,README,ReleaseNotes,UPGRADE}

    ECHO_INFO "Create directory alias for squirrelmail in Apache: ${HTTPD_DOCUMENTROOT}/mail/."
    cat > ${HTTPD_CONF_DIR}/squirrelmail.conf <<EOF
${CONF_MSG}
Alias /mail "${HTTPD_SERVERROOT}/squirrelmail-${SM_VERSION}/"
Alias /webmail "${HTTPD_SERVERROOT}/squirrelmail-${SM_VERSION}/"
EOF

    ECHO_INFO "Create directories to storage squirrelmail data and attachments: ${SM_DATA_DIR}, ${SM_ATTACHMENT_DIR}."

    mkdir -p ${SM_DATA_DIR} ${SM_ATTACHMENT_DIR}
    chown apache:apache ${SM_DATA_DIR} ${SM_ATTACHMENT_DIR}
    chmod 730 ${SM_ATTACHMENT_DIR}

    cat >> ${TIP_FILE} <<EOF
WebMail(SquirrelMail):
    * Configuration files:
        - ${HTTPD_SERVERROOT}/squirrelmail-${SM_VERSION}/
        - ${HTTPD_SERVERROOT}/squirrelmail-${SM_VERSION}/config/config.php
    * URL:
        - http://$(hostname)/mail/
        - http://$(hostname)/webmail/
    * See also:
        - ${HTTPD_CONF_DIR}/squirrelmail.conf

EOF

    echo 'export status_sm_install="DONE"' >> ${STATUS_FILE}
}

sm_config()
{
    ECHO_INFO "Setting up configuration file for SquirrelMail."
    ${SM_CONF_PL} >/dev/null <<EOF
2
1
$(hostname)
A
4
127.0.0.1
B
4
127.0.0.1
R
4
1
${SM_DATA_DIR}
2
${SM_ATTACHMENT_DIR}
R
6
1
+
${LDAP_SERVER_HOST}
${LDAP_BASEDN}
${LDAP_SERVER_PORT}
utf-8
Global LDAP Address Book

${LDAP_BINDDN}
${LDAP_BINDPW}
3
d
R
10
1
${SM_DEFAULT_LOCALE}
2
${SM_DEFAULT_CHARSET}
R
D
dovecot

S

Q
EOF

    echo 'export status_sm_config="DONE"' >> ${STATUS_FILE}
}

#
# For SquirrelMail translations.
#

convert_translation_locale()
{
    # convert_locale zh_CN zh_CN.GB2312 zh_CN.UTF8 gb2312 utf-8
    #                $1    $2           $3         $4     $5
    export language="$1"
    export locale_old="$2"
    export locale_new="$3"
    export charset_old="$4"
    export charset_new="$5"

    ECHO_INFO "Convert translation locale: $language"
    ECHO_INFO "LOCALE: $2 -> $3. CHARSET: $4 -> $5."

    if [ -d ${SM_HTTPD_ROOT}/locale/${language}/ ]; then
        cd ${SM_HTTPD_ROOT}/locale/${language}/LC_MESSAGES/
        cp squirrelmail.po squirrelmail.po.${charset_old}
        iconv -f ${charset_old} -t ${charset_new} squirrelmail.po.${charset_old} > squirrelmail.po

        cd ${SM_HTTPD_ROOT}/locale/${language}/
        cp setup.php setup.php.bak
        perl -pi -e 's/(.*)$ENV{"charset_old"}(.*)/$1$ENV{"charset_new"}$2/' setup.php
        perl -pi -e 's/(.*)$ENV{"locale_old"}(.*)/$1$ENV{"locale_new"}$2/' setup.php
    fi

    if [ -d ${SM_HTTPD_ROOT}/help/${language} ]; then

        cd ${SM_HTTPD_ROOT}/help/${language}

        for i in $(ls *); do
            cp $i $i.bak
            iconv -f ${charset_old} -t ${charset_new} $i.bak >$i
        done
    fi

    cd ${SM_HTTPD_ROOT}/functions/
    cp i18n.php i18n.php.bak
    perl -pi -e 's/(.*)$ENV{"charset_old"}(.*)/$1$ENV{"charset_new"}$2/' i18n.php
    perl -pi -e 's/(.*)$ENV{"locale_old"}(.*)/$1$ENV{"locale_new"}$2/' i18n.php

    echo 'export status_convert_translation_locale="DONE"' >> ${STATUS_FILE}
}

sm_translations()
{
    cd ${MISC_DIR}

    extract_pkg ${SM_TRANSLATIONS_TARBALL} /tmp
    
    ECHO_INFO "Copy SquirrelMail translations to ${SM_HTTPD_ROOT}/"
    cp -rf /tmp/locale/* ${SM_HTTPD_ROOT}/locale/
    cp -rf /tmp/images/* ${SM_HTTPD_ROOT}/images/
    cp -rf /tmp/help/* ${SM_HTTPD_ROOT}/help/

    convert_translation_locale 'zh_CN' 'zh_CN.GB2312' 'zh_CN.UTF8' 'gb2312' 'utf-8'
    convert_translation_locale 'zh_TW' 'zh_CN.BIG5' 'zh_CN.UTF8' 'big5' 'utf-8'

    echo 'export status_sm_translations="DONE"' >> ${STATUS_FILE}
}

#
# For squirrelmail plugin: change_ldappass.
#

sm_plugin_change_ldappass()
{
    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_CHANGE_LDAPPASS_TARBALL}

    ECHO_INFO "Move plugin to: ${SM_PLUGIN_DIR}."
    mv change_ldappass ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}
    chmod -R 0755 ${SM_PLUGIN_DIR}

    cd ${SM_PLUGIN_DIR}/change_ldappass/

    ECHO_INFO "Generate configration file: ${SM_PLUGIN_DIR}/change_ldappass/config.php."
    cat >${PLUGIN_CHANGE_LDAPPASS_CONFIG} <<EOF
<?php
${CONF_MSG}
\$ldap_server = 'ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}';
\$ldap_protocol_version = ${LDAP_BIND_VERSION};
\$ldap_password_field = "${LDAP_ATTR_USER_PASSWD}";
\$ldap_user_field = "${LDAP_ATTR_USER_DN_NAME}";
\$ldap_base_dn = '${LDAP_BASEDN}';
\$ldap_filter = "(&(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_STATUS}=active)(${LDAP_ATTR_USER_ENABLE_IMAP}=yes))";
\$query_dn="${LDAP_BINDDN}";
\$query_pw="${LDAP_BINDPW}";
\$ldap_bind_as_manager = false;
\$ldap_bind_as_manager = false;
\$ldap_manager_dn='';
\$ldap_manager_pw='';
\$change_smb=false;
\$debug=false;
EOF

    chown apache:apache ${PLUGIN_CHANGE_LDAPPASS_CONFIG}
    chmod 644 ${PLUGIN_CHANGE_LDAPPASS_CONFIG}

    echo 'status_sm_plugin_change_ldappass="DONE"' >> ${STATUS_FILE}
}

#
# For squirrelmail plugin: change_ldappass.
#

sm_plugin_compatibility()
{
    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_COMPATIBILITY_TARBALL}

    ECHO_INFO "Move plugin to: ${SM_PLUGIN_DIR}."
    mv compatibility ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}/compatibility/
    chmod -R 0755 ${SM_PLUGIN_DIR}/compatibility/

    echo 'export status_sm_plugin_compatibility="DONE"' >> ${STATUS_FILE}
}

#
# For squirrelmail plugin: Check Quota.
#

sm_plugin_check_quota()
{
    # Installation.
    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_CHECK_QUOTA_TARBALL}

    ECHO_INFO "Move plugin to: ${SM_PLUGIN_DIR}."
    mv check_quota ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}/check_quota/
    chmod -R 0755 ${SM_PLUGIN_DIR}/check_quota/

    # Configure.
    ECHO_INFO "Generate configuration file for plugin: check_quota."
    cp ${SM_PLUGIN_DIR}/check_quota/config.sample.php ${SM_PLUGIN_DIR}/check_quota/config.php
    chown -R apache:apache ${SM_PLUGIN_DIR}/check_quota/config.php
    chmod -R 0755 ${SM_PLUGIN_DIR}/check_quota/config.php

    ECHO_INFO "Configure plugin: check_quota."
    perl -pi -e 's/(.*)(quota_type)(.*)0;/${1}${2}${3}1;/' ${SM_PLUGIN_DIR}/check_quota/config.php

    echo 'export status_sm_plugin_check_quota="DONE"' >> ${STATUS_FILE}
}

#
# For SquirrelMail plugin: select_language.
#

sm_plugin_select_language()
{
    ECHO_INFO "Install SquirrelMail plugin: select language."

    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_SELECT_LANGUAGE_TARBALL} ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}/select_language
    chmod -R 755 ${SM_PLUGIN_DIR}/select_language

    echo 'export status_sm_plugin_select_language="DONE"' >> ${STATUS_FILE}
}

#
# For SquirrelMail plugin: autosubscribe.
#
sm_plugin_autosubscribe()
{
    ECHO_INFO "Install SquirrelMail plugin: autosubscribe."

    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_AUTOSUBSCRIBE_TARBALL} ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}/autosubscribe
    chmod -R 755 ${SM_PLUGIN_DIR}/autosubscribe

    cat > ${SM_PLUGIN_DIR}/autosubscribe/config.php <<EOF
<?php
\$autosubscribe_folders='Junk';
\$autosubscribe_special_folders='Sent,Drafts,Trash';
\$autosubscribe_all_delay = 0;
?>
EOF

    echo 'export status_sm_plugin_autosubscribe="DONE"' >> ${STATUS_FILE}
}

#
# For SquirrelMail plugin: email_footer.
#
sm_plugin_email_footer()
{
    ECHO_INFO "Install SquirrelMail plugin: Email Footer."

    cd ${MISC_DIR}
    extract_pkg ${PLUGIN_EMAIL_FOOTER_TARBALL} ${SM_PLUGIN_DIR}
    chown -R apache:apache ${SM_PLUGIN_DIR}/email_footer
    chmod -R 755 ${SM_PLUGIN_DIR}/email_footer

    cd ${SM_PLUGIN_DIR}/email_footer/ && \
    cp config.sample.php config.php && \
    perl -pi -e 's#^(=.*)#="";#' config.php && \
    perl -pi -e 's#^(\..*)##' config.php

    echo 'export status_sm_plugin_email_footer="DONE"' >> ${STATUS_FILE}
}


# --------------------
# Install all plugins.
# --------------------
sm_plugin_all()
{
    # Install all plugins.
    check_status_before_run sm_plugin_change_ldappass
    check_status_before_run sm_plugin_compatibility
    check_status_before_run sm_plugin_check_quota
    check_status_before_run sm_plugin_select_language
    check_status_before_run sm_plugin_autosubscribe
    check_status_before_run sm_plugin_email_footer

    # Enable all defined plugins.
    check_status_before_run enable_sm_plugins

    echo 'export status_sm_plugin_all="DONE"' >> ${STATUS_FILE}
}
