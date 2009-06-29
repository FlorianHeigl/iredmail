#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# Dovecot & dovecot-sieve.
# -------------------------------------------------------

# For dovecot SSL support.
dovecot_ssl_config()
{
    ECHO_INFO "Enable TLS support in Dovecot."

    [ X"${ENABLE_DOVECOT_SSL}" == X"YES" ] && cat >> ${DOVECOT_CONF} <<EOF
# SSL support.
# Refer to official documentation:
#   * http://wiki.dovecot.org/SSL/DovecotConfiguration
ssl_disable = no
verbose_ssl = no
ssl_key_file = ${SSL_KEY_FILE}
ssl_cert_file = ${SSL_CERT_FILE}
EOF

    echo 'export status_dovecot_ssl_config="DONE"' >> ${STATUS_FILE}
}

dovecot_config()
{
    ECHO_INFO "==================== Dovecot ===================="

    [ X"${ENABLE_DOVECOT}" == X"YES" ] && \
        backup_file ${DOVECOT_CONF} && \
        chmod 0755 ${DOVECOT_CONF} && \
        ECHO_INFO "Setup dovecot: ${DOVECOT_CONF}." && \
        cat > ${DOVECOT_CONF} <<EOF
${CONF_MSG}
# Provided services.
protocols = ${DOVECOT_PROTOCOLS}

# Listen addresses. for Dovecot-1.1.x.
# ipv4: *
# ipv6: [::]
#listen = *, [::]
listen = *

# mail uid/gid.
mail_uid = ${VMAIL_USER_UID}
mail_gid = ${VMAIL_USER_GID}

#
# Debug options.
#
#mail_debug = yes
#auth_verbose = yes
#auth_debug = yes
#auth_debug_passwords = yes

#
# Log file.
#
#log_timestamp = "%Y-%m-%d %H:%M:%S "
log_path = ${DOVECOT_LOG_FILE}

#login_processes_count = 3
#login_max_processes_count = 128
#login_max_connections = 256
#max_mail_processes = 512

umask = 0077
disable_plaintext_auth = no

# Performance Tuning. Reference:
#   http://wiki.dovecot.org/LoginProcess
#
# High-Security mode. Dovecot default setting.
#
# It works by using a new imap-login or pop3-login process for each
# incoming connection. Since the processes run in a highly restricted
# chroot, running each connection in a separate process means that in
# case there is a security hole in Dovecot's pre-authentication code
# or in the SSL library, the attacker can't see other users'
# connections and can't really do anything destructive.
login_process_per_connection=yes

#
# High-Performance mode.
#
# It works by using a number of long running login processes,
# each handling a number of connections. This loses much of
# the security benefits of the login process design, because
# in case of a security hole the attacker is now able to see
# other users logging in and steal their passwords.
#login_process_per_connection = no

# Default realm/domain to use if none was specified.
# This is used for both SASL realms and appending '@domain.ltd' to username in plaintext logins.
auth_default_realm = ${FIRST_DOMAIN}

# ---- NFS storage ----
# Set to 'no' For NFSv2. Default is 'yes'.
#dotlock_use_excl = yes 

#mail_nfs_storage = yes # v1.1+ only

# If indexes are on NFS.
#mail_nfs_index = yes # v1.1+ only
# ----

plugin {
    # Quota warning.
    #
    # You can find sample script from iRedMail Support mail list:
    #   http://groups.google.com/group/iredmailsupport/
    #
    # Or you can find sample script from Dovecot wiki:
    #   http://wiki.dovecot.org/Quota/1.1#head-03d8c4f6fb28e2e2f1cb63ec623810b45bec1734
    #
    # If user suddenly receives a huge mail and the quota jumps from
    # 85% to 95%, only the 95% script is executed.
    #
    #quota_warning = storage=85%% /usr/bin/dovecot-quota-warning.sh 85
    #quota_warning2 = storage=90%% /usr/bin/dovecot-quota-warning.sh 90
    #quota_warning3 = storage=95%% /usr/bin/dovecot-quota-warning.sh 95
}

EOF

    # Enable SSL support.
    [ X"${ENABLE_DOVECOT_SSL}" == X"YES" ] && dovecot_ssl_config

    # Mailbox format.
    if [ X"${MAILBOX_FORMAT}" == X"Maildir" ]; then
        cat >> ${DOVECOT_CONF} <<EOF
# Maildir format and location.
# Such as: /home/vmail/iredmail.org/www/
#          ----------- ================
#          homeDirectory  mailMessageStore
mail_location = maildir:/%Lh/Maildir/:INDEX=/%Lh/Maildir/

plugin {
    quota = maildir

    # Quota rules. Reference: http://wiki.dovecot.org/Quota/1.1
    # The following limit names are supported:
    #   - storage: Quota limit in kilobytes, 0 means unlimited.
    #   - bytes: Quota limit in bytes, 0 means unlimited.
    #   - messages: Quota limit in number of messages, 0 means unlimited. This probably isn't very useful.
    #   - backend: Quota backend-specific limit configuration.
    #   - ignore: Don't include the specified mailbox in quota at all (v1.1.rc5+). 
    quota_rule = *:storage=100M
    #quota_rule2 = *:messages=0
    #quota_rule3 = Trash:storage=1G
    #quota_rule4 = Junk:ignore
}

dict {
    # NOTE: dict process currently runs as root, so this file will be owned as root.
    expire = db:${DOVECOT_EXPIRE_DICT_BDB}
}

plugin {
    # ---- Expire plugin ----
    # Expire plugin. Mails are expunged from mailboxes after being there the
    # configurable time. The first expiration date for each mailbox is stored in
    # a dictionary so it can be quickly determined which mailboxes contain
    # expired mails. The actual expunging is done in a nightly cronjob, which
    # you must set up:
    #
    #   1   3   *   *   *   ${DOVECOT_BIN} --exec-mail ext /usr/libexec/dovecot/expire-tool
    #
    # Trash: 7 days
    # Trash's children directories: 7 days
    # Junk: 30 days
    expire = Trash 7 Trash/* 7 Junk 30
    expire_dict = proxy::expire

    # If you have a non-default path to auth-master, set also:
    auth_socket_path = ${DOVECOT_SOCKET_MASTER}
}

# Per-user sieve mail filter.
plugin {
    # NOTE: %variable expansion works only with Dovecot v1.0.2+.
    # For maildir format.
    sieve = /%Lh/${SIEVE_RULE_FILENAME}
}

EOF
    elif [ X"${MAILBOX_FORMAT}" == X"mbox" ]; then
        cat >> ${DOVECOT_CONF} <<EOF
# Mailbox format and location.
# Such as: /home/vmail/iredmail.org/www
#          ----------- ====================
#          homeDirectory  mailMessageStore
mail_location = mbox:/%Lh/:INBOX=/%Lh/inbox:INDEX=/%Lh/indexes

# mbox performance optimizations.
mbox_lazy_writes=yes
mbox_min_index_size=10240
mbox_very_dirty_syncs = yes
mbox_read_locks = fcntl
mbox_write_locks = dotlock fcntl

plugin {
    quota = dirsize

    # Quota rules.
    quota_rule = *:storage=10M
    #quota_rule2 = Trash:storage=100M
    #quota_rule3 = Junk:ignore
}

plugin {
    # NOTE: %variable expansion works only with Dovecot v1.0.2+.
    # For mbox format.
    sieve = /%Lh/${SIEVE_RULE_FILENAME}
}
EOF
    else
        :
    fi

    cat >> ${DOVECOT_CONF} <<EOF
# LDA: Local Deliver Agent
protocol lda { 
    postmaster_address = root
    auth_socket_path = ${DOVECOT_SOCKET_MASTER}
    #mail_plugins = cmusieve quota expire
    mail_plugins = cmusieve quota
    sieve_global_path = ${SIEVE_FILTER_FILE}
    log_path = ${SIEVE_LOG_FILE}
}

# IMAP configuration
protocol imap {
    #mail_plugins = quota imap_quota zlib expire
    mail_plugins = quota imap_quota zlib

    # number of connections per-user per-IP
    #mail_max_userip_connections = 10
}

# POP3 configuration
protocol pop3 {
    #mail_plugins = quota zlib expire
    mail_plugins = quota zlib
    pop3_uidl_format = %08Xu%08Xv
    pop3_client_workarounds = outlook-no-nuls oe-ns-eoh
}

auth default {
    mechanisms = plain login
    user = ${VMAIL_USER_NAME}
EOF

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        cat >> ${DOVECOT_CONF} <<EOF
    passdb ldap {
        args = ${DOVECOT_LDAP_CONF}
    }
    userdb ldap {
        args = ${DOVECOT_LDAP_CONF}
    }
EOF

        backup_file ${DOVECOT_LDAP_CONF}
        cat > ${DOVECOT_LDAP_CONF} <<EOF
${CONF_MSG}
hosts           = ${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}
ldap_version    = 3
auth_bind       = yes
dn              = ${LDAP_BINDDN}
dnpass          = ${LDAP_BINDPW}
base            = ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}
scope           = subtree
deref           = never
user_filter     = (&(${LDAP_ATTR_USER_RDN}=%u)(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=%Ls))
pass_filter     = (${LDAP_ATTR_USER_RDN}=%u)
pass_attrs      = ${LDAP_ATTR_USER_PASSWD}=password
default_pass_scheme = CRYPT
EOF
        # Maildir format.
        [ X"${MAILBOX_FORMAT}" == X"Maildir" ] && cat >> ${DOVECOT_LDAP_CONF} <<EOF
user_attrs      = ${LDAP_ATTR_USER_STORAGE_BASE_DIRECTORY}=home,mailMessageStore=mail=maildir:~/%\$/Maildir/,${LDAP_ATTR_USER_QUOTA}=quota_rule=*:bytes=%\$
EOF
        [ X"${MAILBOX_FORMAT}" == X"mbox" ] && cat >> ${DOVECOT_LDAP_CONF} <<EOF
#    sieve = /%Lh/%Ld/.%Ln${SIEVE_RULE_FILENAME}
user_attrs      = ${LDAP_ATTR_USER_STORAGE_BASE_DIRECTORY}=home,mailMessageStore=mail=dirsize:~/%\$,${LDAP_ATTR_USER_QUOTA}=quota_rule=*:bytes=%\$
EOF
    else
        cat >> ${DOVECOT_CONF} <<EOF
    passdb sql {
        args = ${DOVECOT_MYSQL_CONF}
    }
    userdb sql {
        args = ${DOVECOT_MYSQL_CONF}
    }
EOF

        backup_file ${DOVECOT_MYSQL_CONF}
        cat > ${DOVECOT_MYSQL_CONF} <<EOF
driver = mysql
default_pass_scheme = CRYPT
connect = host=${MYSQL_SERVER} dbname=${VMAIL_DB} user=${MYSQL_BIND_USER} password=${MYSQL_BIND_PW}
password_query = SELECT password FROM mailbox WHERE username='%u' AND active='1' AND expired >= NOW()
EOF
        # Maildir format.
        [ X"${MAILBOX_FORMAT}" == X"Maildir" ] && cat >> ${DOVECOT_MYSQL_CONF} <<EOF
user_query = SELECT CONCAT(storagebasedirectory, '/', maildir) AS home, \
CONCAT('*:bytes=', quota*1048576) AS quota_rule \
FROM mailbox WHERE username='%u' \
AND active='1' AND enable%Ls='1' AND expired >= NOW()
EOF
        [ X"${MAILBOX_FORMAT}" == X"mbox" ] && cat >> ${DOVECOT_MYSQL_CONF} <<EOF
user_query = SELECT CONCAT('mbox:', storagebasedirectory, '/', maildir, '/Maildir/') AS home, \
CONCAT('*:bytes=', quota*1048576) AS quota_rule, \
maildir FROM mailbox \
WHERE username='%u' \
AND active='1' \
AND enable%Ls='1' \
AND expired >= NOW()
EOF
    fi

    cat >> ${DOVECOT_CONF} <<EOF
    socket listen {
        master { 
            path = ${DOVECOT_SOCKET_MASTER}
            mode = 0666
            user = ${VMAIL_USER_NAME}
            group = ${VMAIL_GROUP_NAME}
        }
        client {
            path = ${DOVECOT_SOCKET_MUX}
            mode = 0666
            user = postfix
            group = postfix
        }
    }
}
EOF

    ECHO_INFO "Generate dovecot sieve global filter rule file: ${SIEVE_FILTER_FILE}.sample."
    cp -f ${SAMPLE_DIR}/dovecot.sieve ${SIEVE_FILTER_FILE}.sample
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${SIEVE_FILTER_FILE}.sample
    chmod 0500 ${SIEVE_FILTER_FILE}.sample

    ECHO_INFO "Create dovecot log file: ${DOVECOT_LOG_FILE}, ${SIEVE_LOG_FILE}."
    touch ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chmod 0600 ${DOVECOT_LOG_FILE}

    # Sieve log file must be world-writable.
    chmod 0666 ${SIEVE_LOG_FILE}

    ECHO_INFO "Enable dovecot in postfix: ${POSTFIX_FILE_MAIN_CF}."
    postconf -e mailbox_command="${DOVECOT_DELIVER}"
    postconf -e virtual_transport="${TRANSPORT}"
    postconf -e dovecot_destination_recipient_limit='1'

    postconf -e smtpd_sasl_type='dovecot'
    # if postfix does *NOT* runs under in chroot env, smtpd_sasl_path
    # should be '/var/spool/postfix/dovecot-auth'.
    postconf -e smtpd_sasl_path='dovecot-auth'

    ECHO_INFO "Create directory for Dovecot plugin: Expire."
    dovecot_expire_dict_dir="$(dirname ${DOVECOT_EXPIRE_DICT_BDB})"
    mkdir -p ${dovecot_expire_dict_dir} && \
    chown -R ${DOVECOT_USER}:${DOVECOT_GROUP} ${dovecot_expire_dict_dir} && \
    chmod -R 0750 ${dovecot_expire_dict_dir}

    if [ X"${DISTRO}" == X"RHEL" ]; then
        ECHO_INFO "Setting cronjob for Dovecot plugin: Expire."
        cat >> ${CRON_SPOOL_DIR}/root <<EOF
${CONF_MSG}
#1   5   *   *   *   ${DOVECOT_BIN} --exec-mail ext $(eval ${LIST_FILES_IN_PKG} dovecot | grep 'expire-tool$')
EOF
    elif [ X"${DISTRO}" == X"UBUNTU" -o X"${DISTRO}" == X"DEBIAN" ]; then
        :
    else
        :
    fi

    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
dovecot unix    -       n       n       -       -      pipe
  flags=DRhu user=${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} argv=${DOVECOT_DELIVER} -d \${recipient} -f \${sender}
EOF

    ECHO_INFO "Setting logrotate for dovecot log file."
    cat > ${DOVECOT_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${DOVECOT_LOG_FILE} {
    compress
    weekly
    rotate 10
    create 0600 ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
    missingok

    # Use bzip2 for compress.
    compresscmd $(which bzip2)
    uncompresscmd $(which bunzip2)
    compressoptions -9
    compressext .bz2 

    postrotate
        ${SYSLOG_POSTROTATE_CMD}
    endscript
}
EOF

    cat > ${SIEVE_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${SIEVE_LOG_FILE} {
    compress
    weekly
    rotate 10
    create 0666 ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
    missingok
    postrotate
        ${SYSLOG_POSTROTATE_CMD}
    endscript
}
EOF

    cat >> ${TIP_FILE} <<EOF
Dovecot:
    * Configuration files:
        - ${DOVECOT_CONF}
    * LDAP:
        - ${DOVECOT_LDAP_CONF}
    * MySQL:
        - ${DOVECOT_MYSQL_CONF}
    * RC script:
        - /etc/init.d/dovecot
    * Log files:
        - ${DOVECOT_LOGROTATE_FILE}
        - ${DOVECOT_LOG_FILE}
        - ${SIEVE_LOG_FILE}
    * See also:
        - ${SIEVE_FILTER_FILE}

EOF

    echo 'export status_enable_dovecot="DONE"' >> ${STATUS_FILE}
}

enable_dovecot()
{
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        check_status_before_run dovecot_config
    else
        check_status_before_run enable_procmail
    fi
    echo 'export status_enable_dovecot="DONE"' >> ${STATUS_FILE}
}
