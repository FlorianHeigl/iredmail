#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

# -------------------------------------------
# Misc.
# -------------------------------------------
cleanup_disable_selinux()
{
    ECHO_INFO "Disable SELinux in /etc/selinux/config."
    [ -f /etc/selinux/config ] && perl -pi -e 's#^(SELINUX=)(.*)#${1}disabled#' /etc/selinux/config

    setenforce 0 >/dev/null 2>&1

    echo 'export status_cleanup_disable_selinux="DONE"' >> ${STATUS_FILE}
}

cleanup_remove_sendmail()
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

    echo 'export status_cleanup_remove_sendmail="DONE"' >> ${STATUS_FILE}
}

cleanup_replace_iptables_rule()
{
    # Get SSH listen port, replace default port number in iptable rule file.
    export sshd_port="$(grep '^Port' ${SSHD_CONFIG} | awk '{print $2}' )"
    if [ X"${sshd_port}" == X"" -o X"${sshd_port}" == X"22" ]; then
        # No port number defined, use default (22).
        export sshd_port='22'
    else
        # Replace port number in iptable rule file.
        perl -pi -e 's#(.*multiport.*,)22 (.*)#${1}$ENV{sshd_port} ${2}#' ${SAMPLE_DIR}/iptables.rules
    fi

    ECHO_QUESTION "Would you like to use firewall rules shipped within iRedMail now?"
    ECHO_QUESTION -n "File: ${IPTABLES_CONFIG}, with SSHD port: ${sshd_port}. [Y|n]"
    read ANSWER
    case $ANSWER in
        N|n ) ECHO_INFO "Skip firewall rules." ;;
        Y|y|* ) 
            ECHO_INFO "Copy firewall sample rules: ${IPTABLES_CONFIG}."
            backup_file ${IPTABLES_CONFIG}
            cp -f ${SAMPLE_DIR}/iptables.rules ${IPTABLES_CONFIG}

            if [ X"${HTTPD_PORT}" != X"80" ]; then
                perl -pi -e 's#(.*)80(,.*)#${1}$ENV{HTTPD_PORT}${2}#' ${IPTABLES_CONFIG}
            else
                :
            fi

            # Copy sample rc script for Debian.
            [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && \
                cp -f ${SAMPLE_DIR}/iptables.init.debian ${DIR_RC_SCRIPTS}/iptables && \
                chmod +x ${DIR_RC_SCRIPTS}/iptables

            # Mark iptables as enabled service.
            eval ${enable_service} iptables >/dev/null

            # Prompt to restart iptables.
            ECHO_QUESTION -n "Restart firewall now (with SSHD port ${sshd_port})? [y|N]"
            read ANSWER
            case $ANSWER in
                Y|y )
                    ECHO_INFO "Restarting firewall ..."
                    ${DIR_RC_SCRIPTS}/iptables restart
                    ;;
                N|n|* )
                    export "RESTART_IPTABLES='NO'"
                    ECHO_INFO "Skip restart firewall."
                    ;;
            esac
            ;;
    esac

    [ X"${KERNEL_NAME}" == X"Linux" ] && export ENABLED_SERVICES="${ENABLED_SERVICES} iptables"

    echo 'export status_cleanup_replace_iptables_rule="DONE"' >> ${STATUS_FILE}
}

cleanup_replace_mysql_config()
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

    echo 'export status_cleanup_replace_mysql_config="DONE"' >> ${STATUS_FILE}
}

cleanup_upgrade_php_pear()
{
    if [ X"${BACKEND}" == X"OpenLDAP" -a X"${USE_RCM}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ECHO_INFO "Upgrading php-pear (pear upgrade pear)..."
            pear upgrade --force pear >/dev/null
        fi

        ECHO_INFO "Installing php Net_LDAP2 ..."
        pear install ${SRC_PEAR_NET_LDAP2} >/dev/null
    fi

    echo 'export status_cleanup_upgrade_php_pear="DONE"' >> ${STATUS_FILE}
}

cleanup_start_postfix_now()
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

            # FreeBSD
            if [ X"${DISTRO}" == X"FREEBSD" ]; then
                # Update clamav before start clamav-clamd service.
                ECHO_INFO "Update ClamAV database..."
                freshclam

                # Load kernel module 'accf_http' before start.
                kldload accf_http

                # Stop sendmail.
                killall sendmail
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

    echo 'export status_cleanup_start_postfix_now="DONE"' >> ${STATUS_FILE}
}

cleanup_sa_preconfig()
{
    # Required on FreeBSD to start Amavisd-new.
    ECHO_INFO "Fetching SpamAssassin rules (sa-update) ..."
    /usr/local/bin/sa-update >/dev/null

    ECHO_INFO "Compiling SpamAssassin ruleset into native code (sa-compile), be patient..."
    /usr/local/bin/sa-compile >/dev/null

    echo 'export status_cleanup_sa_preconfig="DONE"' >> ${STATUS_FILE}
}

cleanup()
{
    cat <<EOF

*************************************************************************
* ${PROG_NAME}-${PROG_VERSION} installation and configuration complete.
*************************************************************************

EOF

    [ X"${DISTRO}" == X"RHEL" ] && check_status_before_run cleanup_disable_selinux
    check_status_before_run cleanup_remove_sendmail
    [ X"${KERNEL_NAME}" == X"Linux" ] && check_status_before_run cleanup_replace_iptables_rule
    [ X"${DISTRO}" == X"RHEL" ] && check_status_before_run cleanup_replace_mysql_config
    check_status_before_run cleanup_upgrade_php_pear
    check_status_before_run cleanup_start_postfix_now
    [ X"${DISTRO}" == X"FREEBSD" ] && check_status_before_run cleanup_sa_preconfig

    # Send tip file to the mail server admin and/or first mail user.
    tip_recipient="${FIRST_USER}@${FIRST_DOMAIN}"
    [ ! -z "${MAIL_ALIAS_ROOT}" -a X"${MAIL_ALIAS_ROOT}" != X"${tip_recipient}" ] && \
        tip_recipient="${tip_recipient},${MAIL_ALIAS_ROOT}"

    cat > /tmp/.tips.eml <<EOF
From: root@${HOSTNAME}
To: ${tip_recipient}
Subject: iRedMail tips for mail server administrator

EOF

    cat ${TIP_FILE} >> /tmp/.tips.eml
    sendmail -t ${tip_recipient} < /tmp/.tips.eml &>/dev/null && rm -f /tmp/.tips.eml &>/dev/null

    cat > /tmp/.links.eml <<EOF
From: root@${HOSTNAME}
To: ${tip_recipient}
Subject: Useful resources for iRedMail administrator

EOF
    cat ${DOC_FILE} >> /tmp/.links.eml
    sendmail -t ${tip_recipient} < /tmp/.links.eml &>/dev/null && rm -f /tmp/.links.eml &>/dev/null

    cat <<EOF

********************************************************************
* Congratulations, mail server setup complete. Please refer to tip
* file for more information:
*
*   - ${TIP_FILE}
*
* And it's sent to your mail account ${tip_recipient}.
*
EOF

    if [ X"${DISTRO}" != X"FREEBSD" ]; then
        cat <<EOF
* If you want to remove and re-install iRedMail, here are steps:
*   - Run script to remove main components installed by iRedMail:
*       # wget http://iredmail.googlecode.com/hg/extra/clear_iredmail.sh
*       # mv clear_iredmail.sh tools/ && cd tools/
*       # bash clear_iredmail.sh
*   - Remove iRedMail installation process status:
*       # rm -f ${STATUS_FILE}
*   - Install iRedMail like you did before.
*
EOF
fi

if [ X"${POSTFIX_STARTED}" != X"YES" -a X"${DISTRO}" != X"FREEBSD" ]; then
    cat <<EOF
* Please reboot your system to enable mail related services or start them
* manually without reboot:
*
EOF

    # Prompt to disable selinux.
    if [ ! -z ${SETENFORCE} ]; then
        cat <<EOF
*   # ${SETENFORCE} 0
EOF
    fi

    cat <<EOF
*   # for i in ${ENABLED_SERVICES}; do ${DIR_RC_SCRIPTS}/\${i} restart; done
*
EOF
fi

if [ X"${DISTRO}" == X"FREEBSD" ]; then
    # Reboot freebsd to enable mail related services, because sendmail is
    # binding to port '25'.
    cat <<EOF
* Please reboot your system to enable mail related services.
*
EOF
fi

    cat <<EOF
********************************************************************

EOF
    echo 'export status_cleanup="DONE"' >> ${STATUS_FILE}
}

