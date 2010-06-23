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

# -------------------------------------------------------
# Dovecot & dovecot-sieve.
# -------------------------------------------------------

# For dovecot SSL support.
dovecot_ssl_config()
{
    ECHO_DEBUG "Enable TLS support."

    if [ X"${ENABLE_DOVECOT_SSL}" == X"YES" ]; then
        # Enable ssl. Different setting in v1.1, v1.2.
        if [ X"${DOVECOT_VERSION}" == X"1.1" ]; then
            cat >> ${DOVECOT_CONF} <<EOF
# SSL support.
ssl_disable = no
EOF
        elif [ X"${DOVECOT_VERSION}" == X"1.2" ]; then
            cat >> ${DOVECOT_CONF} <<EOF
# SSL support.
ssl = yes
EOF
        fi

        cat >> ${DOVECOT_CONF} <<EOF
verbose_ssl = no
ssl_key_file = ${SSL_KEY_FILE}
ssl_cert_file = ${SSL_CERT_FILE}
EOF
    fi

    echo 'export status_dovecot_ssl_config="DONE"' >> ${STATUS_FILE}
}

dovecot_config()
{
    ECHO_INFO "Configure Dovecot (pop3/imap server)."

    [ X"${ENABLE_DOVECOT}" == X"YES" ] && \
        backup_file ${DOVECOT_CONF} && \
        chmod 0755 ${DOVECOT_CONF} && \
        ECHO_DEBUG "Configure dovecot: ${DOVECOT_CONF}."

        cat > ${DOVECOT_CONF} <<EOF
${CONF_MSG}
EOF

        if [ X"${DOVECOT_VERSION}" == X"1.1" ]; then
            cat >> ${DOVECOT_CONF} <<EOF
umask = 0077
EOF
        fi

        cat >> ${DOVECOT_CONF} <<EOF
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
    # You can find sample script from Dovecot wiki:
    # http://wiki.dovecot.org/Quota/1.1#head-03d8c4f6fb28e2e2f1cb63ec623810b45bec1734
    #
    # If user suddenly receives a huge mail and the quota jumps from
    # 85% to 95%, only the 95% script is executed.
    #
    quota_warning = storage=85%% ${DOVECOT_QUOTA_WARNING_BIN} 85
    quota_warning2 = storage=90%% ${DOVECOT_QUOTA_WARNING_BIN} 90
    quota_warning3 = storage=95%% ${DOVECOT_QUOTA_WARNING_BIN} 95
}

EOF

    # Generate dovecot quota warning script.
    mkdir -p $(dirname ${DOVECOT_QUOTA_WARNING_BIN}) 2>/dev/null

    backup_file ${DOVECOT_QUOTA_WARNING_BIN}
    rm -rf ${DOVECOT_QUOTA_WARNING_BIN} 2>/dev/null

    cat > ${DOVECOT_QUOTA_WARNING_BIN} <<FOE
#!/usr/bin/env bash
${CONF_MSG}

PERCENT=\${1}

cat << EOF | ${DOVECOT_DELIVER} -d \${USER} -c ${DOVECOT_CONF}
From: no-reply@${HOSTNAME}
Subject: Mailbox Quota Warning: \${PERCENT}% Full.

Your mailbox is now \${PERCENT}% full, please clean up some mails for
further incoming mails.

EOF
FOE

    chown root ${DOVECOT_QUOTA_WARNING_BIN}
    chmod 0755 ${DOVECOT_QUOTA_WARNING_BIN}

    # Use '/usr/local/bin/bash' as shabang line, otherwise quota waning will be failed.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        perl -pi -e 's#(.*)/usr/bin/env bash.*#${1}/usr/local/bin/bash#' ${DOVECOT_QUOTA_WARNING_BIN}
    fi

    # Enable SSL support.
    [ X"${ENABLE_DOVECOT_SSL}" == X"YES" ] && dovecot_ssl_config

    # Mailbox format.
    if [ X"${MAILBOX_FORMAT}" == X"Maildir" ]; then
        cat >> ${DOVECOT_CONF} <<EOF
# Maildir format and location.
# Such as: /var/mail/vmail01/iredmail.org/www/
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
    # For maildir format.
    sieve = ${SIEVE_DIR}/%Ld/%Ln/${SIEVE_RULE_FILENAME}
}
EOF
    elif [ X"${MAILBOX_FORMAT}" == X"mbox" ]; then
        cat >> ${DOVECOT_CONF} <<EOF
# Mailbox format and location.
# Such as: /var/mail/vmail01/iredmail.org/www
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

# Per-user sieve mail filter.
plugin {
    # For mbox format.
    sieve = ${SIEVE_DIR}/%Ld/.%Ln${SIEVE_RULE_FILENAME}
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
    #mail_plugins = ${DOVECOT_LDA_SIEVE_PLUGIN_NAME} quota expire
    mail_plugins = ${DOVECOT_LDA_SIEVE_PLUGIN_NAME} quota
    sieve_global_path = ${GLOBAL_SIEVE_FILE}
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
base            = ${LDAP_BASEDN}
scope           = subtree
deref           = never
user_filter     = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=%Ls%Lc)(|(${LDAP_ATTR_USER_RDN}=%u)(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SHADOW_ADDRESS})(${LDAP_ATTR_USER_SHADOW_ADDRESS}=%u))))
pass_filter     = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=%Ls%Lc)(|(${LDAP_ATTR_USER_RDN}=%u)(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SHADOW_ADDRESS})(${LDAP_ATTR_USER_SHADOW_ADDRESS}=%u))))
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
password_query = SELECT password FROM mailbox WHERE username='%u' AND active='1'
EOF
        # Maildir format.
        [ X"${MAILBOX_FORMAT}" == X"Maildir" ] && cat >> ${DOVECOT_MYSQL_CONF} <<EOF
user_query = SELECT CONCAT(storagebasedirectory, '/', storagenode, '/', maildir) AS home, \
CONCAT('*:bytes=', quota*1048576) AS quota_rule \
FROM mailbox WHERE username='%u' \
AND active='1' AND enable%Ls%Lc='1'
EOF
        [ X"${MAILBOX_FORMAT}" == X"mbox" ] && cat >> ${DOVECOT_MYSQL_CONF} <<EOF
user_query = SELECT CONCAT('mbox:', storagebasedirectory, '/', storagenode, '/', maildir, '/Maildir/') AS home, \
CONCAT('*:bytes=', quota*1048576) AS quota_rule, \
maildir FROM mailbox \
WHERE username='%u' \
AND active='1' \
AND enable%Ls='1'
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

    ECHO_DEBUG "Copy sample sieve global filter rule file: ${GLOBAL_SIEVE_FILE}.sample."
    cp -f ${SAMPLE_DIR}/dovecot.sieve ${GLOBAL_SIEVE_FILE}.sample
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${GLOBAL_SIEVE_FILE}.sample
    chmod 0500 ${GLOBAL_SIEVE_FILE}.sample

    ECHO_DEBUG "Create dovecot log file: ${DOVECOT_LOG_FILE}, ${SIEVE_LOG_FILE}."
    touch ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chmod 0600 ${DOVECOT_LOG_FILE}

    # Sieve log file must be world-writable.
    chmod 0666 ${SIEVE_LOG_FILE}

    ECHO_DEBUG "Enable dovecot SASL support in postfix: ${POSTFIX_FILE_MAIN_CF}."
    postconf -e mailbox_command="${DOVECOT_DELIVER}"
    postconf -e virtual_transport="${TRANSPORT}"
    postconf -e dovecot_destination_recipient_limit='1'

    postconf -e smtpd_sasl_type='dovecot'
    # if postfix does *NOT* runs under in chroot env, smtpd_sasl_path
    # should be '/var/spool/postfix/dovecot-auth'.
    postconf -e smtpd_sasl_path='dovecot-auth'

    ECHO_DEBUG "Create directory for Dovecot plugin: Expire."
    dovecot_expire_dict_dir="$(dirname ${DOVECOT_EXPIRE_DICT_BDB})"
    mkdir -p ${dovecot_expire_dict_dir} && \
    chown -R ${DOVECOT_USER}:${DOVECOT_GROUP} ${dovecot_expire_dict_dir} && \
    chmod -R 0750 ${dovecot_expire_dict_dir}

    if [ X"${DISTRO}" == X"RHEL" ]; then
        ECHO_DEBUG "Setting cronjob for Dovecot plugin: Expire."
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
# Use dovecot deliver program as LDA.
dovecot unix    -       n       n       -       -      pipe
    flags=DRhu user=${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} argv=${DOVECOT_DELIVER} -f \${sender} -d \${user}@\${domain}
EOF

    if [ X"${KERNEL_NAME}" == X"Linux" ]; then
        ECHO_DEBUG "Setting logrotate for dovecot log file."
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
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
Dovecot:
    * Configuration files:
        - ${DOVECOT_CONF}
    * LDAP:
        - ${DOVECOT_LDAP_CONF}
    * MySQL:
        - ${DOVECOT_MYSQL_CONF}
    * RC script:
        - ${DIR_RC_SCRIPTS}/dovecot
    * Log files:
        - ${DOVECOT_LOGROTATE_FILE}
        - ${DOVECOT_LOG_FILE}
        - ${SIEVE_LOG_FILE}
    * See also:
        - ${GLOBAL_SIEVE_FILE}

EOF

    echo 'export status_enable_dovecot="DONE"' >> ${STATUS_FILE}
}

enable_dovecot()
{
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        check_status_before_run dovecot_config
    fi

    # FreeBSD.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        # It seems there's a bug in Dovecot port, it will try to invoke '/usr/lib/sendmail'
        # to send vacation response which should be '/usr/sbin/mailwrapper'.
        [ ! -e /usr/lib/sendmail ] && ln -s /usr/sbin/mailwrapper /usr/lib/sendmail 2>/dev/null

        # Start dovecot when system start up.
        cat >> /etc/rc.conf <<EOF
# Start dovecot IMAP/POP3 server.
dovecot_enable="YES"
EOF
    fi

    echo 'export status_enable_dovecot="DONE"' >> ${STATUS_FILE}
}
