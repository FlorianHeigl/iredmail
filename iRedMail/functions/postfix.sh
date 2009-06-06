#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ---------------------- Postfix ------------------------
# -------------------------------------------------------

postfix_config_basic()
{
    ECHO_INFO "==================== Postfix ===================="

    backup_file ${POSTFIX_FILE_MAIN_CF}

    ECHO_INFO "Enable chroot for Postfix."
    backup_file ${POSTFIX_FILE_MASTER_CF}
    perl -pi -e 's/^(smtp.*inet)(.*)(n)(.*)(n)(.*smtpd)$/${1}${2}${3}${4}-${6}/' ${POSTFIX_FILE_MASTER_CF}

    ECHO_INFO "Bypass checks for internally generated mail: ${POSTFIX_FILE_MASTER_CF}."
    # comment out
    perl -pi -e 's/^(pickup.*)/#${1}/' ${POSTFIX_FILE_MASTER_CF}
    # Add new option to 'pickup' daemon.
    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
# Bypass checks for internally generated mail.
pickup    fifo  n       -       n       60      1       pickup
  -o content_filter=
EOF


    ECHO_INFO "Copy /etc/{hosts,resolv.conf,localtime} -> ${POSTFIX_CHROOT_DIR}/etc/."
    mkdir -p "${POSTFIX_CHROOT_DIR}/etc/"
    cp -f /etc/{hosts,resolv.conf,localtime} ${POSTFIX_CHROOT_DIR}/etc/

    # Normally, myhostname is the same as myorigin.
    postconf -e myhostname="${HOSTNAME}"
    postconf -e myorigin="${HOSTNAME}"

    # Remove the characters before first dot in myhostname is mydomain.
    echo "${HOSTNAME}" | grep '\..*\.' >/dev/null 2>&1
    if [ X"$?" == X"0" ]; then
        mydomain="$(echo "${HOSTNAME}" | awk -F'.' '{print $2 "." $3}')"
        postconf -e mydomain="${mydomain}"
    else
        postconf -e mydomain="${HOSTNAME}"
    fi

    postconf -e mydestination="\$myhostname, localhost, localhost.localdomain, localhost.\$myhostname"
    postconf -e mail_name="${PROG_NAME}"
    postconf -e mail_version="${PROG_VERSION}"
    postconf -e biff="no"   # Do not notify local user.
    postconf -e relay_domains='$mydestination'
    postconf -e inet_interfaces="all"
    postconf -e mynetworks="127.0.0.0/8"
    postconf -e mynetworks_style="subnet"
    postconf -e receive_override_options='no_address_mappings'
    postconf -e smtpd_data_restrictions='reject_unauth_pipelining'
    postconf -e smtpd_reject_unlisted_recipient='yes'   # Default
    postconf -e smtpd_sender_restrictions="permit_mynetworks, reject_sender_login_mismatch, permit_sasl_authenticated"
    postconf -e delay_warning_time='0h'
    postconf -e policy_time_limit='3600'
    postconf -e maximal_queue_lifetime='1d'
    postconf -e bounce_queue_lifetime='1d'

    #
    # Standalone smtpd_helo_restrictions.
    #
    postconf -e smtpd_helo_required="yes"
    postconf -e smtpd_helo_restrictions="permit_mynetworks,permit_sasl_authenticated, check_helo_access pcre:${POSTFIX_FILE_HELO_ACCESS}"

    backup_file ${POSTFIX_FILE_HELO_ACCESS}
    cp -f ${SAMPLE_DIR}/helo_access.pcre ${POSTFIX_FILE_HELO_ACCESS}

    # Reduce queue run delay time.
    postconf -e queue_run_delay='300s'          # default '300s' in postfix-2.4.
    postconf -e minimal_backoff_time='300s'     # default '300s' in postfix-2.4.
    postconf -e maximal_backoff_time='1800s'    # default '4000s' in postfix-2.4.

    # Avoid duplicate recipient messages. Default is 'yes'.
    postconf -e enable_original_recipient="no"

    # Disable the SMTP VRFY command. This stops some techniques used to
    # harvest email addresses.
    postconf -e disable_vrfy_command='yes'

    # We use 'maildir' format, not 'mbox'.
    if [ X"${MAILBOX_FORMAT}" == X"Maildir" ]; then
        postconf -e home_mailbox="Maildir/"
    elif [ X"${MAILBOX_FORMAT}" == X"mbox" ]; then
        postconf -e home_mailbox="Mailbox"
        postconf -e mailbox_delivery_lock='fcntl, dotlock'
        postconf -e virtual_mailbox_lock='fcntl'
    else
        :
    fi
    postconf -e maximal_backoff_time="4000s"

    # Allow recipient address start with '-'.
    postconf -e allow_min_user='no'

    # Postfix aliases file.
    [ ! -f ${POSTFIX_FILE_ALIASES} ] && cp -f /etc/aliases ${POSTFIX_FILE_ALIASES}
    [ ! -z ${MAIL_ALIAS_ROOT} ] && echo "root: ${MAIL_ALIAS_ROOT}" >> ${POSTFIX_FILE_ALIASES}

    postconf -e alias_maps="hash:${POSTFIX_FILE_ALIASES}"
    postconf -e alias_database="hash:${POSTFIX_FILE_ALIASES}"
    postalias hash:${POSTFIX_FILE_ALIASES} 2>/dev/null
    newaliases >/dev/null 2>&1

    # Set message_size_limit.
    postconf -e mailbox_size_limit="${MESSAGE_SIZE_LIMIT}"
    postconf -e message_size_limit="${MESSAGE_SIZE_LIMIT}"
    postconf -e virtual_mailbox_limit_override="yes"
    # Set maildir overquota. 
    postconf -e virtual_overquota_bounce="yes"
    postconf -e virtual_mailbox_limit_message="${MAILDIR_LIMIT_MESSAGE}"

    ECHO_INFO "Setting up virtual domain in Postfix."
    postconf -e virtual_minimum_uid="${VMAIL_USER_UID}"
    postconf -e virtual_uid_maps="static:${VMAIL_USER_UID}"
    postconf -e virtual_gid_maps="static:${VMAIL_USER_GID}"
    postconf -e virtual_mailbox_base="${VMAIL_USER_HOME_DIR}"

    postconf -e check_sender_access="hash:${POSTFIX_ROOTDIR}/sender_access"
    cat > ${POSTFIX_ROOTDIR}/sender_access <<EOF
${CONF_MSG}
# This file has to be compiled with "postmap".

# Examples:
# Using domain name.
#example.com    554 Spam not tolerated here
#example.com    REJECT

#example.com    DUNNO

# Using IP address.
# 10.0.0.0/8
#10             554 Go away!

# 172.16/16
#172.16         554 Bugger off!

#1.2.3.4        REJECT

# 192.168.4/24 is bad, but 192.168.4.128 is okay
#192.168.4.128       OK
#192.168.4           554 Take a hike!

# Write your own rules below.

EOF
    postmap hash:${POSTFIX_ROOTDIR}/sender_access

    # Simple backscatter block method.
    postconf -e header_checks="pcre:${POSTFIX_FILE_HEADER_CHECKS}"
    cat >> ${POSTFIX_FILE_HEADER_CHECKS} <<EOF
# *******************************************************************
# Below rules is wrote in pcre syntax, shipped within ${PROG_NAME} project:
#   http://${PROG_NAME}.googlecode.com
# Reference:
#   http://www.postfix.org/BACKSCATTER_README.html#real
# *******************************************************************

# Use your real hostname to replace 'porcupine.org'.
#if /^Received:/
#/^Received: +from +(porcupine\.org) +/
#    reject forged client name in Received: header: $1
#/^Received: +from +[^ ]+ +\(([^ ]+ +[he]+lo=|[he]+lo +)(porcupine\.org)\)/
#    reject forged client name in Received: header: $2
#/^Received:.* +by +(porcupine\.org)\b/
#    reject forged mail server name in Received: header: $1
#endif
#/^Message-ID:.* <!&!/ DUNNO
#/^Message-ID:.*@(porcupine\.org)/
#    reject forged domain name in Message-ID: header: $1

# Replace internal IP address by external IP address or whatever you
# want. Required 'smtpd_sasl_authenticated_header=yes' in postfix.
#/(^Received:.*\[).*(\].*Authenticated sender:.*by REPLACED_BE_YOUR_HOSTNAME.*iRedMail.*)/ REPLACE ${1}REPLACED_BE_YOUR_IP_ADDRESS${2}
EOF

    cat >> ${TIP_FILE} <<EOF
Postfix (basic):
    * Configuration files:
        - ${POSTFIX_ROOTDIR}
        - ${POSTFIX_ROOTDIR}/aliases
        - ${POSTFIX_FILE_MAIN_CF}
        - ${POSTFIX_FILE_MASTER_CF}

EOF

    echo 'export status_postfix_config_basic="DONE"' >> ${STATUS_FILE}
}

postfix_config_ldap()
{
    # LDAP search filters.
    ldap_search_base_domain="${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}"
    ldap_search_base_user="${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}"
    ldap_search_base_group="${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_GROUPS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}"

    ECHO_INFO "Setting up LDAP lookup in Postfix."
    postconf -e transport_maps="ldap:${ldap_transport_maps_cf}"
    postconf -e virtual_mailbox_domains="ldap:${ldap_virtual_mailbox_domains_cf}"
    postconf -e virtual_mailbox_maps="ldap:${ldap_accounts_cf}, ldap:${ldap_virtual_mailbox_maps_cf}"
    postconf -e virtual_alias_maps="ldap:${ldap_virtual_alias_maps_cf}, ldap:${ldap_virtual_group_maps_cf}"
    #postconf -e local_recipient_maps='$alias_maps $virtual_alias_maps $virtual_mailbox_maps'
    postconf -e sender_bcc_maps="ldap:${ldap_sender_bcc_maps_domain_cf}, ldap:${ldap_sender_bcc_maps_user_cf}"
    postconf -e recipient_bcc_maps="ldap:${ldap_recipient_bcc_maps_domain_cf}, ldap:${ldap_recipient_bcc_maps_user_cf}"

    postconf -e smtpd_sender_login_maps="ldap:${ldap_sender_login_maps_cf}"
    postconf -e smtpd_reject_unlisted_sender='yes'

    #
    # For mydestination = ldap:virtualdomains
    #
    ECHO_INFO "Setting up LDAP virtual domains: ${ldap_virtual_mailbox_domains_cf}."

    cat > ${ldap_virtual_mailbox_domains_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
bind            = ${LDAP_BIND}
start_tls       = no
version         = ${LDAP_BIND_VERSION}
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${LDAP_BASEDN}
scope           = one
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_MAILDOMAIN})(${LDAP_ATTR_DOMAIN_RDN}=%s)(!(${LDAP_ATTR_DOMAIN_BACKUPMX}=${LDAP_VALUE_DOMAIN_BACKUPMX}))(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL}))
result_attribute= ${LDAP_ATTR_DOMAIN_RDN}
debuglevel      = 0
EOF

    #
    # LDAP transport maps
    #
    ECHO_INFO "Setting up LDAP transport_maps: ${ldap_transport_maps_cf}."

    cat > ${ldap_transport_maps_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${LDAP_BASEDN}
scope           = one
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_MAILDOMAIN})(${LDAP_ATTR_DOMAIN_RDN}=%s)(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL}))
result_attribute= ${LDAP_ATTR_DOMAIN_TRANSPORT}
debuglevel      = 0
EOF

    #
    # LDAP Virtual Users.
    #
    ECHO_INFO "Setting up LDAP virtual users: ${ldap_accounts_cf}, ${ldap_virtual_mailbox_maps_cf}."

    cat > ${ldap_accounts_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_user}
scope           = one
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_USER_RDN}=%s)(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL}))
result_attribute= mailMessageStore
debuglevel      = 0
EOF

    cat > ${ldap_virtual_mailbox_maps_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_user}
scope           = one
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_USER_RDN}=%s)(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER}))
result_attribute= ${LDAP_ATTR_USER_RDN}
debuglevel      = 0
EOF

    ECHO_INFO "Setting up LDAP sender login maps: ${ldap_sender_login_maps_cf}."
    cat > ${ldap_sender_login_maps_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_user}
scope           = one
query_filter    = (&(${LDAP_ATTR_USER_RDN}=%s)(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SMTP}))
result_attribute= ${LDAP_ATTR_USER_RDN}
debuglevel      = 0
EOF

    ECHO_INFO "Setting up LDAP virtual aliases: ${ldap_virtual_alias_maps_cf}."

    cat > ${ldap_virtual_alias_maps_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_domain}
scope           = sub
query_filter    = (&(${LDAP_ATTR_USER_RDN}=%s)(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER})(|(objectClass=${LDAP_OBJECTCLASS_MAILGROUP})(objectClass=${LDAP_OBJECTCLASS_MAILALIAS})(&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_FORWARD}))))
result_attribute= ${LDAP_ATTR_USER_FORWARD}
debuglevel      = 0
EOF

    ECHO_INFO "Setting up LDAP virtual group: ${ldap_virtual_group_maps_cf}."
    cat > ${ldap_virtual_group_maps_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_domain}
scope           = sub
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_USER_MEMBER_OF_GROUP}=%s)(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER}))
result_attribute= ${LDAP_ATTR_USER_RDN}
debuglevel      = 0
EOF

    cat > ${ldap_recipient_bcc_maps_domain_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${LDAP_BASEDN}
scope           = one
query_filter    = (&(${LDAP_ATTR_DOMAIN_RDN}=%d)(objectClass=${LDAP_OBJECTCLASS_MAILDOMAIN})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_RECIPIENT_BCC}))
result_attribute= ${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS}
debuglevel      = 0
EOF

    cat > ${ldap_recipient_bcc_maps_user_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_user}
scope           = one
query_filter    = (&(${LDAP_ATTR_USER_RDN}=%s)(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_RECIPIENT_BCC}))
result_attribute= ${LDAP_ATTR_USER_RECIPIENT_BCC_ADDRESS}
debuglevel      = 0
EOF

    cat > ${ldap_sender_bcc_maps_domain_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${LDAP_BASEDN}
scope           = one
query_filter    = (&(${LDAP_ATTR_DOMAIN_RDN}=%d)(objectClass=${LDAP_OBJECTCLASS_MAILDOMAIN})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SENDER_BCC}))
result_attribute= ${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS}
debuglevel      = 0
EOF

    cat > ${ldap_sender_bcc_maps_user_cf} <<EOF
${CONF_MSG}
server_host     = ${LDAP_SERVER_HOST}
server_port     = ${LDAP_SERVER_PORT}
version         = ${LDAP_BIND_VERSION}
bind            = ${LDAP_BIND}
start_tls       = no
bind_dn         = ${LDAP_BINDDN}
bind_pw         = ${LDAP_BINDPW}
search_base     = ${ldap_search_base_user}
scope           = one
query_filter    = (&(${LDAP_ATTR_USER_RDN}=%s)(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SENDER_BCC}))
result_attribute= ${LDAP_ATTR_USER_SENDER_BCC_ADDRESS}
debuglevel      = 0
EOF

    ECHO_INFO "Set file permission: Owner/Group -> root/root, Mode -> 0640."

    cat >> ${TIP_FILE} <<EOF
Postfix (LDAP):
    * Configuration files:
EOF

    for i in ${ldap_virtual_mailbox_domains_cf} \
        ${ldap_transport_maps_cf} \
        ${ldap_accounts_cf} \
        ${ldap_virtual_mailbox_maps_cf} \
        ${ldap_virtual_alias_maps_cf} \
        ${ldap_virtual_group_maps_cf} \
        ${ldap_recipient_bcc_maps_domain_cf} \
        ${ldap_recipient_bcc_maps_user_cf} \
        ${ldap_sender_bcc_maps_domain_cf} \
        ${ldap_sender_bcc_maps_user_cf}
    do
        chown ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${i}
        chmod 0644 ${i}
        cat >> ${TIP_FILE} <<EOF
        - ${i}
EOF
    done

    echo 'export status_postfix_config_ldap="DONE"' >> ${STATUS_FILE}
}

postfix_config_mysql()
{
    ECHO_INFO "Configure Postfix for MySQL lookup."

    # Postfix doesn't work while mysql server is 'localhost', should be
    # changed to '127.0.0.1'.

    postconf -e transport_maps="mysql:${mysql_transport_maps_cf}"
    postconf -e virtual_mailbox_domains="mysql:${mysql_virtual_mailbox_domains_cf}"
    postconf -e virtual_mailbox_maps="mysql:${mysql_virtual_mailbox_maps_cf}"
    postconf -e virtual_mailbox_limit_maps="mysql:${mysql_virtual_mailbox_limit_maps_cf}"
    postconf -e virtual_alias_maps="mysql:${mysql_virtual_alias_maps_cf}"
    #postconf -e local_recipient_maps='$alias_maps $virtual_alias_maps $virtual_mailbox_maps'
    postconf -e sender_bcc_maps="mysql:${mysql_sender_bcc_maps_domain_cf}, mysql:${mysql_sender_bcc_maps_user_cf}"
    postconf -e recipient_bcc_maps="mysql:${mysql_recipient_bcc_maps_domain_cf}, mysql:${mysql_recipient_bcc_maps_user_cf}"

    postconf -e smtpd_sender_login_maps="mysql:${mysql_sender_login_maps_cf}"
    postconf -e smtpd_reject_unlisted_sender='yes'

    cat > ${mysql_transport_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT transport FROM domain WHERE domain='%s' AND active='1'
EOF

    cat > ${mysql_virtual_mailbox_domains_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT domain FROM domain WHERE domain='%s' AND backupmx='0' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_virtual_mailbox_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT maildir FROM mailbox WHERE username='%s' AND active='1' AND enabledeliver='1' AND expired >= NOW()
EOF

    cat > ${mysql_virtual_mailbox_limit_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT quota FROM mailbox WHERE username='%s' AND active='1'
EOF

    cat > ${mysql_virtual_alias_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT goto FROM alias WHERE address='%s' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_login_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT username FROM mailbox WHERE username='%s' AND active='1' AND enablesmtp='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_bcc_maps_domain_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM sender_bcc_domain WHERE domain='%d' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_bcc_maps_user_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM sender_bcc_user WHERE username='%s' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_recipient_bcc_maps_domain_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM recipient_bcc_domain WHERE domain='%d' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_recipient_bcc_maps_user_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${mysql_server}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM recipient_bcc_user WHERE username='%s' AND active='1' AND expired >= NOW()
EOF

    ECHO_INFO "Set file permission: Owner/Group -> postfix/postfix, Mode -> 0640."
    cat >> ${TIP_FILE} <<EOF
Postfix (MySQL):
    * Configuration files:
EOF
    for i in ${mysql_virtual_mailbox_domains_cf} \
        ${mysql_transport_maps_cf} \
        ${mysql_virtual_mailbox_maps_cf} \
        ${mysql_virtual_mailbox_limit_maps_cf} \
        ${mysql_virtual_alias_maps_cf} \
        ${mysql_sender_login_maps_cf} \
        ${mysql_sender_bcc_maps_domain_cf} \
        ${mysql_sender_bcc_maps_user_cf} \
        ${mysql_recipient_bcc_maps_domain_cf} \
        ${mysql_recipient_bcc_maps_user_cf}
    do
        chown ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${i}
        chmod 0644 ${i}

        cat >> ${TIP_FILE} <<EOF
        - $i
EOF
    done

    echo 'export status_postfix_config_mysql="DONE"' >> ${STATUS_FILE}
}

# Starting config.
postfix_config_virtual_host()
{
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        check_status_before_run postfix_config_ldap
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        check_status_before_run postfix_config_mysql
    else
        :
    fi

    echo 'export status_postfix_config_virtual_host="DONE"' >> ${STATUS_FILE}
}

postfix_config_sasl()
{
    ECHO_INFO "Setting up SASL configration for Postfix."

    # For SASL auth
    postconf -e smtpd_sasl_auth_enable="yes"
    postconf -e smtpd_sasl_local_domain=''
    postconf -e smtpd_sasl_security_options="noanonymous"
    postconf -e broken_sasl_auth_clients="yes"

    # Report the SASL authenticated user name in Received message header.
    # Used to reject backscatter.
    # Such as:
    # ----8<----
    # Received: xxxxxxxxxxx
    #           (Authenticated sender: www@a.cn)
    # ----8<----
    # Default is 'no'.
    postconf -e smtpd_sasl_authenticated_header="no"

    # smtpd_recipient_restrictions reference:
    #   http://www.postfix.org/SASL_README.html
    #
    #   Must order:
    #       xxx, permit_sasl_authenticated, reject_unauth_destination, _policy_
    #
    # **** HELO related (smtpd_helo_restrictions) ****
    # Reject the request when the HELO or EHLO hostname syntax is
    # invalid. 
    #   - reject_invalid_helo_hostname
    #
    # Reject the request when the HELO or EHLO hostname is not in
    # fully-qualified domain form, as required by the RFC. 
    #   - reject_non_fqdn_helo_hostname
    #
    # Reject the request when the HELO or EHLO hostname has no DNS A
    # or MX record.
    #   - reject_unknown_helo_hostname
    #
    # **** End HELO related ****

    #
    # Policyd, perl-Mail-SPF and non-SPF.
    #
    postconf -e smtpd_recipient_restrictions="reject_unknown_sender_domain, reject_unknown_recipient_domain, reject_non_fqdn_sender, reject_non_fqdn_recipient, reject_unlisted_recipient, permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname, check_policy_service inet:127.0.0.1:10031"

    echo 'export status_postfix_config_sasl="DONE"' >> ${STATUS_FILE}
}

postfix_config_tls()
{
    ECHO_INFO "Enable TLS/SSL support in Postfix."

    postconf -e smtpd_tls_security_level='may'
    postconf -e smtpd_enforce_tls='no'
    postconf -e smtpd_tls_loglevel='0'
    postconf -e smtpd_tls_key_file="${SSL_KEY_FILE}"
    postconf -e smtpd_tls_cert_file="${SSL_CERT_FILE}"
    #postconf -e #smtpd_tls_CAfile = 
    postconf -e tls_random_source='dev:/dev/urandom'
    postconf -e tls_daemon_random_source='dev:/dev/urandom'

    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
submission inet n       -       n       -       -       smtpd
  -o smtpd_enforce_tls=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
#  -o content_filter=smtp-amavis:[${AMAVISD_SERVER}]:10026

smtps     inet  n       -       n       -       -       smtpd
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o content_filter=smtp-amavis:[${AMAVISD_SERVER}]:10026
EOF

    echo 'export status_postfix_config_tls="DONE"' >> ${STATUS_FILE}
}

postfix_config_syslog()
{
    #
    # maillog file is listed in ${LOGROTATE_DIR}/syslog file by
    # default, logrotated weekly, it's not suited for a large network.
    #

    ECHO_INFO "Setting up logrotate for maillog as a daily work."
    # Remove maillog from ${LOGROTATE_DIR}/(r)syslog.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        perl -pi -e 's#/var/log/maillog ##' ${LOGROTATE_DIR}/syslog
    elif [ X"${DISTRO}" == X"UBUNTU" -o X"${DISTRO}" == X"DEBIAN" ]; then
        # File not available while upgrade from Debian 4.
        [ -f ${LOGROTATE_DIR}/rsyslog ] && perl -pi -e 's#/var/log/mail.*##' ${LOGROTATE_DIR}/rsyslog
    else
        :
    fi

    # Make maillog as standalone logrotated job.
    cat >> ${LOGROTATE_DIR}/maillog <<EOF
${CONF_MSG}
#
# Logrotate file for postfix maillog.
#
 
${MAILLOG} {
    compress
    daily
    rotate 30
    create 0600 root root
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

    cat >> ${TIP_FILE} <<EOF
Postfix (syslog):
    * logrotate file: ${LOGROTATE_DIR}/maillog

EOF

    echo 'export status_postfix_config_syslog="DONE"' >> ${STATUS_FILE}
}
