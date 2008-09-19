# -------------------------------------------------------
# ---------------------- Postfix ------------------------
# -------------------------------------------------------

postfix_config_basic()
{
    backup_file ${SMTPD_CONF}

    ECHO_INFO "Create saslauthd user auth lookup file: ${SMTPD_CONF}."

    cat > ${SMTPD_CONF} <<EOF
${CONF_MSG}
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN MD5
saslauthd_path: SASLAUTHD_MUX
EOF

    ECHO_INFO "Enable chroot for Postfix."
    backup_file ${POSTFIX_FILE_MASTER_CF}
    perl -pi -e 's/^(smtp.*inet)(.*)(n)(.*)(n)(.*smtpd)$/${1}${2}${3}${4}-${6}/' ${POSTFIX_FILE_MASTER_CF}

    ECHO_INFO "Copy /etc/hosts file to chrooted postfix."
    mkdir -p "${POSTFIX_CHROOT_DIR}/etc/"
    cp -f /etc/hosts ${POSTFIX_CHROOT_DIR}/etc/
    cp -f /etc/resolv.conf ${POSTFIX_CHROOT_DIR}/etc/

    postconf -e mydestination="\$myhostname, localhost, localhost.localdomain, localhost.\$myhostname"
    postconf -e mail_name="${PROG_NAME}"
    postconf -e mail_version="${PROG_VERSION}"
    postconf -e myhostname=$(hostname)
    postconf -e mydomain=$(hostname)
    postconf -e myorigin=$(hostname)
    postconf -e relay_domains='$mydestination'
    postconf -e inet_interfaces="all"
    postconf -e mynetworks="127.0.0.0/8"
    postconf -e mynetworks_style="subnet"
    postconf -e receive_override_options='no_address_mappings'
    postconf -e smtpd_data_restrictions='reject_unauth_pipelining'
    postconf -e smtpd_reject_unlisted_recipient='yes'   # Default
    postconf -e smtpd_sender_restrictions="permit_mynetworks, reject_sender_login_mismatch, permit_sasl_authenticated"
    postconf -e delay_warning_time='4h'
    postconf -e policy_time_limit='3600'

    # We use 'maildir' format, not 'mbox'.
    if [ X"${HOME_MAILBOX}" == X"Maildir" ]; then
        postconf -e home_mailbox="Maildir/"
    elif [ X"${HOME_MAILBOX}" == X"mbox" ]; then
        postconf -e home_mailbox="Mailbox"
        postconf -e mailbox_delivery_lock='fcntl, dotlock'
        postconf -e virtual_mailbox_lock='fcntl'
    else
        :
    fi
    postconf -e maximal_backoff_time="4000s"

    # Allow recipient address start with '-'.
    postconf -e allow_min_user='no'

    if [ ! -z ${MAIL_ALIAS_ROOT} ]; then
        echo "root: ${MAIL_ALIAS_ROOT}" >> ${POSTFIX_FILE_ALIASES}
        postconf -e alias_maps="hash:${POSTFIX_FILE_ALIASES}"
        postconf -e alias_database="hash:${POSTFIX_FILE_ALIASES}"
        postalias hash:${POSTFIX_FILE_ALIASES}
        newaliases
    else
        :
    fi

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
    postconf -e header_checks="pcre:${POSTFIX_ROOTDIR}/header_checks"
    cat >> ${POSTFIX_ROOTDIR}/header_checks <<EOF
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
    ECHO_INFO "Setting up LDAP lookup in Postfix."
    postconf -e transport_maps="ldap:${ldap_transport_maps_cf}"
    postconf -e virtual_mailbox_domains="ldap:${ldap_virtual_mailbox_domains_cf}"
    postconf -e virtual_mailbox_maps="ldap:${ldap_accounts_cf}, ldap:${ldap_virtual_mailbox_maps_cf}"
    postconf -e virtual_alias_maps="ldap:${ldap_virtual_alias_maps_cf}"
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
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_DOMAIN})(${LDAP_ATTR_DOMAIN_DN_NAME}=%s)(${LDAP_ATTR_DOMAIN_STATUS}=active))
result_attribute= ${LDAP_ATTR_DOMAIN_DN_NAME}
debug_level     = 0
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
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_DOMAIN})(${LDAP_ATTR_DOMAIN_DN_NAME}=%s)(${LDAP_ATTR_DOMAIN_STATUS}=active))
result_attribute= ${LDAP_ATTR_DOMAIN_TRANSPORT}
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_DN_NAME}=%s)(${LDAP_ATTR_USER_STATUS}=active))
result_attribute= mailMessageStore
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_DN_NAME}=%s)(${LDAP_ATTR_USER_STATUS}=active)(${LDAP_ATTR_USER_ENABLE_DELIVER}=yes))
result_attribute= ${LDAP_ATTR_USER_DN_NAME}
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(${LDAP_ATTR_USER_DN_NAME}=%s)(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_STATUS}=active)(${LDAP_ATTR_USER_ENABLE_SMTP}=yes))
result_attribute= ${LDAP_ATTR_USER_DN_NAME}
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(${LDAP_ATTR_USER_DN_NAME}=%s)(objectClass=${LDAP_OBJECTCLASS_USER})(${LDAP_ATTR_USER_STATUS}=active))
result_attribute= ${LDAP_ATTR_USER_ALIAS}
debug_level     = 0
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
query_filter    = (&(&(${LDAP_ATTR_DOMAIN_DN_NAME}=%d)(objectClass=${LDAP_OBJECTCLASS_DOMAIN}))(${LDAP_ATTR_DOMAIN_STATUS}=active))
result_attribute= ${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS}
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(&(${LDAP_ATTR_USER_DN_NAME}=%s)(objectClass=${LDAP_OBJECTCLASS_USER}))(${LDAP_ATTR_USER_STATUS}=active))
result_attribute= ${LDAP_ATTR_USER_RECIPIENT_BCC_ADDRESS}
debug_level     = 0
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
query_filter    = (&(&(${LDAP_ATTR_DOMAIN_DN_NAME}=%d)(objectClass=${LDAP_OBJECTCLASS_DOMAIN}))(${LDAP_ATTR_DOMAIN_STATUS}=active))
result_attribute= ${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS}
debug_level     = 0
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
search_base     = ${LDAP_ATTR_DOMAIN_DN_NAME}=%d,${LDAP_BASEDN}
scope           = sub
query_filter    = (&(&(${LDAP_ATTR_USER_DN_NAME}=%s)(objectClass=${LDAP_OBJECTCLASS_USER}))(${LDAP_ATTR_USER_STATUS}=active))
result_attribute= ${LDAP_ATTR_USER_SENDER_BCC_ADDRESS}
debug_level     = 0
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
        ${ldap_recipient_bcc_maps_domain_cf} \
        ${ldap_recipient_bcc_maps_user_cf} \
        ${ldap_sender_bcc_maps_domain_cf} \
        ${ldap_sender_bcc_maps_user_cf}
    do
        chown root:root ${i}
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
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT transport FROM domain WHERE domain='%s' AND active='1'
EOF

    cat > ${mysql_virtual_mailbox_domains_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT domain FROM domain WHERE domain='%s' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_virtual_mailbox_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT maildir FROM mailbox WHERE username='%s' AND active='1' AND enabledeliver='1' AND expired >= NOW()
EOF

    cat > ${mysql_virtual_mailbox_limit_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT quota FROM mailbox WHERE username='%s' AND active='1'
EOF

    cat > ${mysql_virtual_alias_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT goto FROM alias WHERE address='%s' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_login_maps_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT username FROM mailbox WHERE username='%s' AND active='1' AND enablesmtp='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_bcc_maps_domain_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM sender_bcc_domain WHERE domain='%d' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_sender_bcc_maps_user_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM sender_bcc_user WHERE username='%s' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_recipient_bcc_maps_domain_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
port        = ${MYSQL_PORT}
dbname      = ${VMAIL_DB}
query       = SELECT bcc_address FROM recipient_bcc_domain WHERE domain='%d' AND active='1' AND expired >= NOW()
EOF

    cat > ${mysql_recipient_bcc_maps_user_cf} <<EOF
user        = ${MYSQL_BIND_USER}
password    = ${MYSQL_BIND_PW}
hosts       = ${MYSQL_SERVER}
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
        chown root:root ${i}
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
    postconf -e enable_original_recipient="no" # Default is 'yes'. refer to postconf(5).
    postconf -e smtpd_helo_required="yes"

    # Report the SASL authenticated user name in Received message header.
    # Used to reject backscatter.
    # Such as:
    # ----8<----
    # Received: xxxxxxxxxxx
    #           (Authenticated sender: www@a.cn)
    # ----8<----
    # Default is 'no'.
    postconf -e smtpd_sasl_authenticated_header="no"

    #
    # Standalone smtpd_helo_restrictions.
    #
    postconf -e smtpd_helo_restrictions="permit_mynetworks,permit_sasl_authenticated, check_helo_access pcre:${POSTFIX_ROOTDIR}/helo_access.pcre"
    cp -f ${SAMPLE_DIR}/helo_access.pcre ${POSTFIX_ROOTDIR}/

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
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        #
        # Non-SPF.
        #
        postconf -e smtpd_recipient_restrictions="permit_mynetworks, reject_unknown_sender_domain, reject_unknown_recipient_domain, reject_non_fqdn_sender, reject_non_fqdn_recipient, permit_sasl_authenticated, reject_unauth_destination, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname, check_policy_service unix:postgrey/socket"
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        #
        # Policyd, perl-Mail-SPF and non-SPF.
        #
        postconf -e smtpd_recipient_restrictions="permit_mynetworks, reject_unknown_sender_domain, reject_unknown_recipient_domain, reject_non_fqdn_sender, reject_non_fqdn_recipient, permit_sasl_authenticated, reject_unauth_destination, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname, check_policy_service inet:127.0.0.1:10031"
    else
        :
    fi

    echo 'export status_postfix_config_sasl="DONE"' >> ${STATUS_FILE}
}

postfix_config_tls()
{
    ECHO_INFO "Generate CA file for Postfix TLS support."
    mkdir -p ${POSTFIX_CERTS_DIR} 2>/dev/null

    cd ${POSTFIX_CERTS_DIR} && \
    gen_pem_key postfix && \
    chown root:root ${POSTFIX_CERTS_DIR}/* && \
    chmod 400 ${POSTFIX_CERTS_DIR}

    cat >> ${POSTFIX_FILE_MAIN_CF} <<EOF
#
# Postfix TLS support. Please refer to:
#   * http://www.postfix.org/TLS_README.html
#   * http://code.google.com/p/${PROG_NAME_LOWERCASE}/wiki/${PROG_NAME}_tut_Postfix#TLS_Support
#
# Example:
#    $ openssl req -newkey rsa:1024 -x509 -nodes -out postfixCert.pem -keyout postfixKey.pem
#
# Enable TLS. Note: 'smtpd_use_tls' equal to 'smtpd_tls_security_level'.
#
smtpd_tls_security_level = may
smtpd_enforce_tls = no
smtpd_tls_loglevel = 0
smtpd_tls_key_file = ${POSTFIX_CERTS_DIR}/postfixKey.pem
smtpd_tls_cert_file = ${POSTFIX_CERTS_DIR}/postfixCert.pem
#smtpd_tls_CAfile = ${POSTFIX_CERTS_DIR}/cacert.pem
tls_random_source = dev:/dev/urandom
tls_daemon_random_source = dev:/dev/urandom
EOF

    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
smtps     inet  n       -       n       -       -       smtpd
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
EOF

    echo 'export status_postfix_config_tls="DONE"' >> ${STATUS_FILE}
}

postfix_config_syslog()
{
    #
    # maillog file is listed in ${LOG_ROTATE_DIR}/syslog file by
    # default, logrotated weekly, it's not suited for a large network.
    #

    ECHO_INFO "Setting up logrotate for maillog as a daily work."

    # Remove maillog from ${LOG_ROTATE_DIR}/syslog.
    perl -pi -e 's#/var/log/maillog ##' ${LOG_ROTATE_DIR}/syslog

    # Make maillog as standalone logrotated job.
    cat >> ${LOG_ROTATE_DIR}/maillog <<EOF
${CONF_MSG}
#
# Logrotate file for postfix maillog.
#
 
/var/log/maillog {
    compress
    daily
    rotate 30
    create 0600 root root
    missingok
    postrotate
        /bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
        /bin/kill -HUP \`cat /var/run/rsyslogd.pid 2> /dev/null\` 2> /dev/null || true
    endscript
}
EOF

    cat >> ${TIP_FILE} <<EOF
Postfix (syslog):
    * logrotate file: ${LOG_ROTATE_DIR}/maillog

EOF

    echo 'export status_postfix_config_syslog="DONE"' >> ${STATUS_FILE}
}
