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
    rpm -qa | grep sendmail >/dev/null 2>&1
    if [ X"$?" == X"0" ]; then
        echo -n "Would you like to *REMOVE* sendmail now? [Y|n]"
        read ANSWER
        case $ANSWER in
            N|n )
                ECHO_INFO "Disable sendmail, of course it is replaced by Postfix." && \
                chkconfig --level 35 sendmail off
                ;;
            Y|y|* ) remove_pkg sendmail ;;
        esac
    else
        :
    fi

    echo 'export status_remove_sendmail="DONE"' >> ${STATUS_FILE}
}

disable_iredmail_repo()
{
    [ -f /etc/yum.repos.d/${LOCAL_REPO_NAME}.repo ] && \
    ECHO_INFO "Disable yum repo generated by iRedMail." && \
    perl -pi -e 's#^(enabled.*=)1#${1}0#' /etc/yum.repos.d/${LOCAL_REPO_NAME}.repo

    echo 'export status_disable_iredmail_repo="DONE"' >> ${STATUS_FILE}
}

replace_iptables_rule()
{
    ECHO_QUESTION "Would you like to use iptables rules shipped within iRedMail now?"
    ECHO_QUESTION -n "File: /etc/sysconfig/iptables. [Y|n]"
    read ANSWER
    case $ANSWER in
        N|n ) ECHO_INFO "Skip iptable rules." ;;
        Y|y|* ) 
            ECHO_INFO "Copy iptables sample rules: /etc/sysconfig/iptables."
            backup_file /etc/sysconfig/iptables
            cp ${SAMPLE_DIR}/iptables /etc/sysconfig/iptables

            if [ X"${HTTPD_PORT}" != X"80" ]; then
                perl -pi -e 's#(.*)80(,.*)#${1}$ENV{HTTPD_PORT}${2}#' ${HTTPD_CONF}
            else
                :
            fi

            # Prompt to restart iptables.
            ECHO_QUESTION -n "Restart iptables now? [y|N]"
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
    if [ X"${BACKEND}" == X"MySQL" ]; then
        ECHO_QUESTION "Would you like to use MySQL configuration file shipped within iRedMail now?"
        ECHO_QUESTION -n "File: /etc/my.cnf. [Y|n]"
        read ANSWER
        case $ANSWER in
            N|n ) ECHO_INFO "Skip iptable rules." ;;
            Y|y|* )
                backup_file /etc/my.cnf
                ECHO_INFO "Copy MySQL sample file: /etc/my.cnf."
                cp ${SAMPLE_DIR}/my.cnf /etc/my.cnf
                ;;
        esac
    else
        :
    fi

    echo 'export status_replace_mysql_config="DONE"' >> ${STATUS_FILE}
}

run_freshclam_now()
{
    # Run freshclam.
    ECHO_QUESTION -n "Would you like to run freshclam now? [y|N]"
    read ANSWER
    case $ANSWER in
        Y|y ) freshclam ;;
        N|n|* ) ECHO_INFO "Skip freshclam." ;;
    esac

    echo 'export status_run_freshclam_now="DONE"' >> ${STATUS_FILE}
}

start_postfix_now()
{
    # Start postfix without reboot your system.
    ECHO_QUESTION -n "Would you like to start postfix now? [y|N]"
    read ANSWER
    case $ANSWER in
        Y|y ) 
            # Disable SELinux.
            setenforce 0

            # Start/Restart necessary services.
            for i in syslog ${ENABLED_SERVICES}
            do
                /etc/init.d/${i} restart
            done
        ;;
        N|n|* )
            echo ''
            echo "*****************************************************"
            echo "* Please reboot your system to enable mail service. *"
            echo "*****************************************************"
            echo ''
            ;;
    esac

    echo 'export status_start_postfix_now="DONE"' >> ${STATUS_FILE}
}

clear_away()
{
    cat <<EOF

*******************************************************
* Congratulations, mail server installation complete. *
*******************************************************

EOF

    check_status_before_run disable_selinux
    check_status_before_run remove_sendmail
    check_status_before_run disable_iredmail_repo
    check_status_before_run replace_iptables_rule
    check_status_before_run replace_mysql_config
    check_status_before_run run_freshclam_now
    check_status_before_run start_postfix_now

    echo 'export status_clear_away="DONE"' >> ${STATUS_FILE}
}

