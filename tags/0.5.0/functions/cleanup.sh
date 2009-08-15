#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------
# Misc.
# -------------------------------------------
disable_selinux()
{
    ECHO_INFO "Disable SELinux."
    [ -f /etc/selinux/config ] && perl -pi -e 's#^(SELINUX=)(.*)#${1}disabled#' /etc/selinux/config

    echo 'export status_disable_selinux="DONE"' >> ${STATUS_FILE}
}

remove_sendmail()
{
    # Remove sendmail.
    eval ${LIST_ALL_PKGS} | grep sendmail >/dev/null 2>&1

    if [ X"$?" == X"0" ]; then
        echo -n "Would you like to *REMOVE* sendmail now? [Y|n]"
        read ANSWER
        case $ANSWER in
            N|n )
                ECHO_INFO "Disable sendmail, it is replaced by Postfix." && \
                eval ${disable_service} sendmail && \
                export HAS_SENDMAIL='YES'
                ;;
            Y|y|* )
                eval ${remove_pkg} sendmail && \
                export HAS_SENDMAIL='NO'
                ;;
        esac
    else
        :
    fi

    echo 'export status_remove_sendmail="DONE"' >> ${STATUS_FILE}
}

re_generate_iredmail_repo()
{
    # Re-generate yum repo file.
    cat > ${LOCAL_REPO_FILE} <<EOF
[${LOCAL_REPO_NAME}]
name=${LOCAL_REPO_NAME}
baseurl=${YUM_UPDATE_REPO}
enabled=1
gpgcheck=0
priority=1
EOF

    echo 'export status_re_generate_iredmail_repo="DONE"' >> ${STATUS_FILE}
}

replace_iptables_rule()
{
    ECHO_QUESTION "Would you like to use iptables rules shipped within iRedMail now?"
    ECHO_QUESTION -n "File: ${IPTABLES_CONFIG}. [Y|n]"
    read ANSWER
    case $ANSWER in
        N|n ) ECHO_INFO "Skip iptable rules." ;;
        Y|y|* ) 
            ECHO_INFO "Copy iptables sample rules: ${IPTABLES_CONFIG}."
            backup_file ${IPTABLES_CONFIG}
            cp -f ${SAMPLE_DIR}/iptables.rules ${IPTABLES_CONFIG}

            if [ X"${HTTPD_PORT}" != X"80" ]; then
                perl -pi -e 's#(.*)80(,.*)#${1}$ENV{HTTPD_PORT}${2}#' ${IPTABLES_CONFIG}
            else
                :
            fi

            # Copy sample rc script for Debian.
            [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && \
                cp -f ${SAMPLE_DIR}/iptables.init.debian /etc/init.d/iptables && \
                chmod +x /etc/init.d/iptables

            # Mark iptables as enabled service.
            eval ${enable_service} iptables >/dev/null

            # Prompt to restart iptables.
            ECHO_QUESTION -n "Restart iptables now (with OpenSSH port 22)? [y|N]"
            read ANSWER
            case $ANSWER in
                Y|y )
                    ECHO_INFO "Restarting iptables."
                    /etc/init.d/iptables restart
                    ;;
                N|n|* )
                    export "RESTART_IPTABLES='NO'"
                    ECHO_INFO "Skip restart iptable rules."
                    ;;
            esac
            ;;
    esac

    echo 'export status_replace_iptables_rule="DONE"' >> ${STATUS_FILE}
}

replace_mysql_config()
{
    if [ X"${BACKEND}" == X"MySQL" -o X"${BACKEND}" == X"OpenLDAP" ]; then
        # Both MySQL and OpenLDAP will need MySQL database server, so prompt
        # this config file replacement.
        ECHO_QUESTION "Would you like to use MySQL configuration file shipped within iRedMail now?"
        ECHO_QUESTION -n "File: ${MYSQL_MY_CNF}. [Y|n]"
        read ANSWER
        case $ANSWER in
            N|n ) ECHO_INFO "Skip copy and modify MySQL config file." ;;
            Y|y|* )
                backup_file ${MYSQL_MY_CNF}
                ECHO_INFO "Copy MySQL sample file: ${MYSQL_MY_CNF}."
                cp -f ${SAMPLE_DIR}/my.cnf ${MYSQL_MY_CNF}

                ECHO_INFO "Enable SSL support for MySQL server."
                perl -pi -e 's/^#(ssl-cert.*=)(.*)/${1} $ENV{'SSL_CERT_FILE'}/' ${MYSQL_MY_CNF}
                perl -pi -e 's/^#(ssl-key.*=)(.*)/${1} $ENV{'SSL_KEY_FILE'}/' ${MYSQL_MY_CNF}
                perl -pi -e 's/^#(ssl-cipher.*)/${1}/' ${MYSQL_MY_CNF}
                ;;
        esac
    else
        :
    fi

    echo 'export status_replace_mysql_config="DONE"' >> ${STATUS_FILE}
}

start_postfix_now()
{
    # Start postfix without reboot your system.
    ECHO_QUESTION -n "Would you like to start postfix now? [y|N]"
    read ANSWER
    case ${ANSWER} in
        Y|y )
            # Disable SELinux.
            SETENFORCE="$(which setenforce 2>/dev/null)"
            if [ ! -z ${SETENFORCE} ]; then
                ECHO_INFO "Temporarily set SELinux policy to 'permissive'."
                ${SETENFORCE} 0
            else
                :
            fi

            # Start/Restart necessary services.
            for i in ${ENABLED_SERVICES}
            do
                service_control ${i} restart
            done
            export POSTFIX_STARTED='YES'
            ;;
        N|n|* )
            :
            ;;
    esac

    echo 'export status_start_postfix_now="DONE"' >> ${STATUS_FILE}
}

cleanup()
{
    cat <<EOF

*************************************************************************
* ${PROG_NAME}-${PROG_VERSION} installation and configuration complete.
*************************************************************************

EOF

    [ X"${DISTRO}" == X"RHEL" ] && check_status_before_run disable_selinux
    check_status_before_run remove_sendmail
    [ X"${DISTRO}" == X"RHEL" ] && check_status_before_run re_generate_iredmail_repo
    check_status_before_run replace_iptables_rule
    [ X"${DISTRO}" == X"RHEL" ] && check_status_before_run replace_mysql_config
    check_status_before_run start_postfix_now

    cat <<EOF

********************************************************************
* Congratulations, mail server setup complete. Please refer to tip
* file for more information:
*
*   - ${TIP_FILE}
*
EOF

if [ X"${POSTFIX_STARTED}" != X"YES" ]; then
    [ X"${DISTRO}" == X"RHEL" ] && export ENABLED_SERVICES="${ENABLED_SERVICES} pysieved"
    export ENABLED_SERVICES="${ENABLED_SERVICES} iptables"

    cat <<EOF
* Please reboot your system to enable mail services or start them
* manually without reboot:
*
*   # for i in ${ENABLED_SERVICES}; do /etc/init.d/\${i} restart; done
*
EOF
fi

    cat <<EOF
********************************************************************

EOF
    echo 'export status_cleanup="DONE"' >> ${STATUS_FILE}
}

