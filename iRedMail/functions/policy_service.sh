#!/bin/sh

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com).
# Date:     2008.04.07

# ---------------------------------------------
# Postgrey.
# ---------------------------------------------
postgrey_config()
{
    # Modify initialize script.
    perl -pi -e 's#^(OPTIONS=".*)(")#${1} --greylist-text=Spammer --delay=30${2}#' /etc/init.d/postgrey

    cat >> ${TIP_FILE} <<EOF
Postgrey:
    * Configuration files:
        - ${POSTFIX_ROOTDIR}/postgrey*
    * RC script:
        - /etc/init.d/postgrey

EOF

    echo 'export status_postgrey_config="DONE"' >> ${STATUS_FILE}
}

# ---------------------------------------------
# pypolicyd-spf.
# ---------------------------------------------
pypolicyd_spf_config()
{
    ECHO_INFO "Install pypolicyd-spf for SPF."
    cd ${MISC_DIR}
    extract_pkg ${PYPOLICYD_SPF_TARBALL} && \
    cd pypolicyd-spf-${PYPOLICYD_SPF_VERSION} && \
    ECHO_INFO "Install pypolicyd-spf-${PYPOLICYD_SPF_VERSION}." && \
    python setup.py build >/dev/null && python setup.py install >/dev/null
    
    postconf -e spf-policyd_time_limit='3600'

    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
policyd-spf  unix  -       n       n       -       -       spawn
  user=nobody argv=/usr/bin/policyd-spf
EOF

    cat >> ${TIP_FILE} <<EOF
SPF(pypolicyd-spf):
    - Configuration file:
        - /etc/python-policyd-spf/policyd-spf.conf
EOF

    echo 'export status_pypolicyd_spf_config="DONE"' >> ${STATUS_FILE}
}

# ---------------------------------------------
# Policyd.
# ---------------------------------------------
policyd_user()
{
    ECHO_INFO "Add user and group for policyd: ${POLICYD_USER_NAME}:${POLICYD_GROUP_NAME}."
    groupadd ${POLICYD_GROUP_NAME}
    useradd -M -d /sbin/nologin -s /sbin/nologin -g ${POLICYD_GROUP_NAME} ${POLICYD_USER_NAME}

    echo 'export status_policyd_user="DONE"' >> ${STATUS_FILE}
}

policyd_config()
{
    ECHO_INFO "Initialize MySQL database for policyd."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
SOURCE $(rpm -ql policyd | grep 'DATABASE.mysql');
GRANT SELECT,INSERT,UPDATE,DELETE ON ${POLICYD_DB_NAME}.* TO ${POLICYD_DB_USER}@localhost IDENTIFIED BY "${POLICYD_DB_PASSWD}";
FLUSH PRIVILEGES;
EOF

    # Configure policyd.
    ECHO_INFO "Configure policyd: ${POLICYD_CONF}."

    # ---- DATABASE CONFIG ----
    export MYSQL_SERVER
    perl -pi -e 's#^(MYSQLHOST=)(.*)#${1}"$ENV{MYSQL_SERVER}"#' ${POLICYD_CONF}
    perl -pi -e 's#^(MYSQLDBASE=)(.*)#${1}"$ENV{POLICYD_DB_NAME}"#' ${POLICYD_CONF}
    perl -pi -e 's#^(MYSQLUSER=)(.*)#${1}"$ENV{POLICYD_DB_USER}"#' ${POLICYD_CONF}
    perl -pi -e 's#^(MYSQLPASS=)(.*)#${1}"$ENV{POLICYD_DB_PASSWD}"#' ${POLICYD_CONF}
    perl -pi -e 's#^(FAILSAFE=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- DAEMON CONFIG ----
    perl -pi -e 's#^(DEBUG=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(DAEMON=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(BINDHOST=)(.*)#${1}"127.0.0.1"#' ${POLICYD_CONF}
    perl -pi -e 's#^(BINDPORT=)(.*)#${1}"10031"#' ${POLICYD_CONF}

    # ---- CHROOT ----
    export policyd_user_id="$(id -u ${POLICYD_USER_NAME})"
    export policyd_group_id="$(id -g ${POLICYD_USER_NAME})"
    perl -pi -e 's#^(UID=)(.*)#${1}$ENV{policyd_user_id}#' ${POLICYD_CONF}
    perl -pi -e 's#^(GID=)(.*)#${1}$ENV{policyd_group_id}#' ${POLICYD_CONF}

    # ---- WHITELISTING ----
    perl -pi -e 's#^(WHITELISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(WHITELISTNULL=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(WHITELISTSENDER=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITE_LISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITELIST_NUMBER=)(.*)#${1}10#' ${POLICYD_CONF}

    # ---- BLACKLISTING ----
    perl -pi -e 's#^(BLACKLISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    #perl -pi -e 's#^(BLACKLIST_REJECTION=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_BLACK_LISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITELIST_NUMBER=)(.*)#${1}10#' ${POLICYD_CONF}

    # ---- BLACKLISTING HELO ----
    perl -pi -e 's#^(BLACKLIST_HELO=)(.*)#${1}1#' ${POLICYD_CONF}
    # ---- BLACKLIST SENDER ----
    perl -pi -e 's#^(BLACKLISTSENDER=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- HELO_CHECK ----
    perl -pi -e 's#^(HELO_CHECK=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- SPAMTRAP ----
    perl -pi -e 's#^(SPAMTRAPPING=)(.*)#${1}1#' ${POLICYD_CONF} 
    #perl -pi -e 's#^(SPAMTRAP_REJECTION=)(.*)#${1}"Spamtrap, go away."#' ${POLICYD_CONF} 

    # ---- GREYLISTING ----
    perl -pi -e 's#^(GREYLISTING=)(.*)#${1}1#' ${POLICYD_CONF} 
    #perl -pi -e 's#^(GREYLIST_REJECTION=)(.*)#${1}"Greylist, please try again later."#' ${POLICYD_CONF} 
    perl -pi -e 's#^(TRAINING_MODE=)(.*)#${1}0#' ${POLICYD_CONF} 
    perl -pi -e 's#^(TRIPLET_TIME=)(.*)#${1}5m#' ${POLICYD_CONF} 
    #perl -pi -e 's#^(OPTINOUT=)(.*)#${1}1#' ${POLICYD_CONF} 

    # ---- SENDER THROTTLE ----
    perl -pi -e 's#^(SENDERTHROTTLE=)(.*)#${1}1#' ${POLICYD_CONF} 
    perl -pi -e 's#^(SENDER_THROTTLE_SASL=)(.*)#${1}1#' ${POLICYD_CONF} 
    perl -pi -e 's#^(SENDER_THROTTLE_HOST=)(.*)#${1}0#' ${POLICYD_CONF} 
    perl -pi -e 's#^(SENDERMSGSIZE=)(.*)#${1}$ENV{'MESSAGE_SIZE_LIMIT'}#' ${POLICYD_CONF} 

    # ---- RECIPIENT THROTTLE ----
    perl -pi -e 's#^(RECIPIENTTHROTTLE=)(.*)#${1}1#' ${POLICYD_CONF} 

    # ---- RCPT ACL ----
    perl -pi -e 's#^(RCPT_ACL=)(.*)#${1}1#' ${POLICYD_CONF} 

    # ---- Syslog Setting ----
    if [ X"${POLICYD_SEPERATE_LOG}" == X"YES" ]; then
        perl -pi -e 's#^(SYSLOG_FACILITY=)(.*)#${1}$ENV{POLICYD_SYSLOG_FACILITY}#' ${POLICYD_CONF} 
        echo -e "local1.*\t\t\t\t\t\t-${POLICYD_LOGFILE}" >>/etc/syslog.conf
        cat > ${POLICYD_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${AMAVISD_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 amavis amavis
    missingok
    postrotate
        /sbin/killall -HUP syslogd
    endscript
}
EOF
    else
        :
    fi

    ECHO_INFO "Setting cron job for policyd user: ${POLICYD_USER_NAME}."
    crontab -u ${POLICYD_USER_NAME} $(rpm -ql policyd | grep 'policyd.cron$')

    # Tips.
    cat >> ${TIP_FILE} <<EOF
Policyd:
    * Configuration files:
        - /etc/policyd.conf
    * RC script:
        - /etc/init.d/policyd
    * Misc:
        - $(rpm -ql policyd | grep 'policyd.cron$')
        - crontab -l ${POLICYD_USER_NAME}
EOF

    if [ X"${POLICYD_SEPERATE_LOG}" == X"YES" ]; then
        cat >> ${TIP_FILE} <<EOF
    * Log file:
        - /etc/syslog.conf
        - ${POLICYD_LOGFILE}

EOF
    else
        echo -e '\n' >> ${TIP_FILE}
    fi

    echo 'export status_policyd_config="DONE"' >> ${STATUS_FILE}
}

policy_service_config()
{
    # Enable pypolicyd-spf.
    [ X"${ENABLE_SPF}" == X"YES" -a X"${SPF_PROGRAM}" == X"pypolicyd-spf" ] && \
        check_status_before_run pypolicyd_spf_config

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        check_status_before_run postgrey_config
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        check_status_before_run policyd_user
        check_status_before_run policyd_config
    else
        :
    fi

    echo 'export status_policy_service_config="DONE"' >> ${STATUS_FILE}
}
