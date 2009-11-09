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
    # Get SSH listen port, replace default port number in iptable rule file.
    sshd_port="$(grep '^Port' ${SSHD_CONFIG} | awk '{print $2}' )"
    if [ X"${sshd_port}" == X"" -o X"${sshd_port}" == X"22" ]; then
        # No port number defined, use default (22).
        export sshd_port='22'
    else
        # Replace port number in iptable rule file.
        perl -pi -e 's#(.*multiport.*)22(.*)#${1}$ENV{sshd_port}${2}#' ${SAMPLE_DIR}/iptables.rules
        export sshd_port="${sshd_port}"
    fi

    ECHO_QUESTION "Would you like to use iptables rules shipped within iRedMail now?"
    ECHO_QUESTION -n "File: ${IPTABLES_CONFIG}, with SSHD port: ${sshd_port}. [Y|n]"
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
            ECHO_QUESTION -n "Restart iptables now (with SSHD port ${sshd_port})? [y|N]"
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

    # Send tip file to the mail server admin or first mail user.
    tip_recipient="${FIRST_USER}@${FIRST_DOMAIN}"
    [ ! -z ${MAIL_ALIAS_ROOT} ] && tip_recipient="${tip_recipient},${MAIL_ALIAS_ROOT}"

    mail -s "iRedMail tips for mail server administrator." ${tip_recipient} < ${TIP_FILE} >/dev/null 2>&1
    mail -s "Useful links for iRedMail." ${tip_recipient} < ${DOC_FILE} >/dev/null 2>&1

    cat <<EOF

********************************************************************
* Congratulations, mail server setup complete. Please refer to tip
* file for more information:
*
*   - ${TIP_FILE}
*
* And it's sent to your mail account ${tip_recipient}.
*
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

