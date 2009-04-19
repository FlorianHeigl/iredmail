#!/bin/sh

# Author:	Zhang Huangbin <michaelbibby (at) gmail.com>

awstats_config_basic()
{
    ECHO_INFO "==================== Awstats ===================="
    [ -f ${AWSTATS_CONF_SAMPLE} ] && dos2unix ${AWSTATS_CONF_SAMPLE} >/dev/null 2>&1

    ECHO_INFO "Generate apache config file for awstats: ${AWSTATS_HTTPD_CONF}."
    backup_file ${AWSTATS_HTTPD_CONF}

    cat > ${AWSTATS_HTTPD_CONF} <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
#Alias /awstats/icon ${AWSTATS_HTTPD_ROOT}/icon/
#ScriptAlias /awstats ${AWSTATS_HTTPD_ROOT}/
#Alias /css ${AWSTATS_HTTPD_ROOT}/css/
#Alias /js ${AWSTATS_HTTPD_ROOT}/js/
EOF

        cat >> ${AWSTATS_HTTPD_CONF} <<EOF
<Directory ${AWSTATS_HTTPD_ROOT}/>
    DirectoryIndex awstats.pl
    Options ExecCGI
    order deny,allow
    allow from all
    #allow from 127.0.0.1

    AuthName "Authorization Required"
EOF

    ECHO_INFO "Setup user auth for awstats: ${AWSTATS_HTTPD_CONF}."
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # Use LDAP auth.
        cat >> ${AWSTATS_HTTPD_CONF} <<EOF
    AuthType Basic

    AuthBasicProvider ldap
    AuthzLDAPAuthoritative   Off

    AuthLDAPUrl   ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}/o=${LDAP_ATTR_DOMAINADMIN_DN_NAME},${LDAP_SUFFIX}?${LDAP_ATTR_USER_RDN}?sub?(&(objectclass=${LDAP_OBJECTCLASS_MAILADMIN})(${LDAP_ATTR_USER_STATUS}=${LDAP_STATUS_ACTIVE}))

    AuthLDAPBindDN "${LDAP_BINDDN}"
    AuthLDAPBindPassword "${LDAP_BINDPW}"
EOF

        [ X"${LDAP_USE_TLS}" == X"YES" ] && perl -pi -e 's#(AuthLDAPUrl.*)(ldap://)(.*)#${1}ldaps://${3}#' ${AWSTATS_HTTPD_CONF}
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # Use mod_auth_mysql.
        cat >> ${AWSTATS_HTTPD_CONF} <<EOF
    AuthType Basic

    AuthMYSQLEnable on
    AuthMySQLUser ${MYSQL_BIND_USER}
    AuthMySQLPassword ${MYSQL_BIND_PW}
    AuthMySQLDB ${VMAIL_DB}
    AuthMySQLUserTable admin
    AuthMySQLNameField username
    AuthMySQLPasswordField password
EOF
    else
        # Use basic auth mech.
        cat >> ${AWSTATS_HTTPD_CONF} <<EOF
    AllowOverride AuthConfig
    AuthType Basic
    AuthUserFile ${AWSTATS_HTPASSWD_FILE}
EOF

    # Set username, password for web access.
    htpasswd -bcm ${AWSTATS_HTPASSWD_FILE} "${AWSTATS_USERNAME}" "${AWSTATS_PASSWD}" >/dev/null 2>&1

    fi

    # Close <Directory> container.
    cat >> ${AWSTATS_HTTPD_CONF} <<EOF

    Require valid-user
</Directory>
EOF

    # Make Awstats can be accessed via HTTPS.
    sed -i "s#\(</VirtualHost>\)#Alias /awstats/icon ${AWSTATS_HTTPD_ROOT}/icon/\n\1#" ${HTTPD_SSL_CONF}
    sed -i "s#\(</VirtualHost>\)#ScriptAlias /awstats ${AWSTATS_HTTPD_ROOT}/\n\1#" ${HTTPD_SSL_CONF}

    cat >> ${TIP_FILE} <<EOF
Awstats:
    * Configuration files:
        - ${AWSTATS_CONF_DIR}
        - ${AWSTATS_CONF_SAMPLE}
        - ${AWSTATS_CONF_WEB}
        - ${AWSTATS_CONF_MAIL}
        - ${AWSTATS_HTTPD_CONF}
    * Login account:
        - Username: ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}, password: ${DOMAIN_ADMIN_PASSWD}
    * URL:
        - https://${HOSTNAME}/awstats/awstats.pl
        - https://${HOSTNAME}/awstats/awstats.pl?config=${HOSTNAME}
        - https://${HOSTNAME}/awstats/awstats.pl?config=mail
    * Crontab job:
        shell> crontab -l root
    
EOF

    echo 'export status_awstats_config_basic="DONE"' >> ${STATUS_FILE}
}

awstats_config_weblog()
{
    ECHO_INFO "Config awstats to analyze apache web access log: ${AWSTATS_CONF_WEB}."
    cd ${AWSTATS_CONF_DIR} && \
    cp -f ${AWSTATS_CONF_SAMPLE} ${AWSTATS_CONF_WEB}

    perl -pi -e 's#^(SiteDomain=)(.*)#${1}"$ENV{'HOSTNAME'}"#' ${AWSTATS_CONF_WEB}

    perl -pi -e 's#^(Lang=)(.*)#${1}$ENV{'AWSTATS_LANGUAGE'}#' ${AWSTATS_CONF_WEB}

    echo 'export status_awstats_config_weblog="DONE"' >> ${STATUS_FILE}
}

awstats_config_maillog()
{
    ECHO_INFO "Config awstats to analyze postfix mail log: ${AWSTATS_CONF_MAIL}."

    cd ${AWSTATS_CONF_DIR} && \
    cp -f ${AWSTATS_CONF_SAMPLE} ${AWSTATS_CONF_MAIL}

    # Create a default config file.
    cp -f ${AWSTATS_CONF_MAIL} ${AWSTATS_CONF_DIR}/awstats.conf

    export maillogconvert_pl="$(which maillogconvert.pl)"
    perl -pi -e 's#^(LogFile=)(.*)#${1}"perl $ENV{'maillogconvert_pl'} standard < /var/log/maillog |"#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LogType=)(.*)#${1}M#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LogFormat=)(.*)#${1}"%time2 %email %email_r %host %host_r %method %url %code %bytesd"#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForBrowsersDetection=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForOSDetection=)(.*)#${1}0##' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForRefererAnalyze=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForRobotsDetection=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForWormsDetection=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForSearchEnginesDetection=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(LevelForFileTypesDetection=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowMenu=)(.*)#${1}1#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowSummary=)(.*)#${1}HB#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowMonthStats=)(.*)#${1}HB#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowDaysOfMonthStats=)(.*)#${1}HB#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowDaysOfWeekStats=)(.*)#${1}HB#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowHoursStats=)(.*)#${1}HB#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowDomainsStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowHostsStats=)(.*)#${1}HBL#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowAuthenticatedUsers=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowRobotsStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowEMailSenders=)(.*)#${1}HBML#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowEMailReceivers=)(.*)#${1}HBML#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowSessionsStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowPagesStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowFileTypesStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowFileSizesStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowBrowsersStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowOSStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowOriginStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowKeyphrasesStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowKeywordsStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowMiscStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowHTTPErrorsStats=)(.*)#${1}0#' ${AWSTATS_CONF_MAIL}
    perl -pi -e 's#^(ShowSMTPErrorsStats=)(.*)#${1}1#' ${AWSTATS_CONF_MAIL}

    perl -pi -e 's#^(Lang=)(.*)#${1}$ENV{'AWSTATS_LANGUAGE'}#' ${AWSTATS_CONF_MAIL}

    echo 'export status_awstats_config_maillog="DONE"' >> ${STATUS_FILE}
}

awstats_config_crontab()
{
    ECHO_INFO "Setting cronjob for awstats."
    cat >> ${CRON_SPOOL_DIR}/root <<EOF
1   */1   *   *   *   perl /var/www/awstats/awstats.pl -config=${HOSTNAME} -update >/dev/null
1   */1   *   *   *   perl /var/www/awstats/awstats.pl -config=mail -update >/dev/null
EOF

    echo 'export status_awstats_config_crontab="DONE"' >> ${STATUS_FILE}
}
