# -------------------------------------------------------
# ------------------- Cyrus-SASL ------------------------
# -------------------------------------------------------

cyrus_sasl_config_ldap()
{
    ECHO_INFO "Configure saslauthd for LDAP bind: ${SASLAUTHD_CONF}"
    cat > ${SASLAUTHD_CONF} <<EOF
${CONF_MSG}
SOCKETDIR=${SASLAUTHD_SOCKETDIR}
MECH=ldap
FLAGS="-O /etc/saslauthd.conf"
EOF

    ECHO_INFO "Generate configuration file for LDAP search in cyrus-sasl: ${ETC_SASLAUTHD_CONF}"
    cat > ${ETC_SASLAUTHD_CONF} <<EOF
${CONF_MSG}
ldap_servers:      ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}
ldap_search_base:  ${LDAP_BASEDN}
ldap_timeout:      10
ldap_bind_dn:      ${LDAP_BINDDN}
ldap_bind_pw:      ${LDAP_BINDPW}
ldap_filter:       mail=%u@%r
EOF

    cat >> ${TIP_FILE} <<EOF
Cyrus-SASL (LDAP):
    * Configuration files:
        - ${SASLAUTHD_CONF}
        - ${ETC_SASLAUTHD_CONF}

EOF

    echo 'export status_cyrus_sasl_config_ldap="DONE"' >> ${STATUS_FILE}
}

cyrus_sasl_config_mysql()
{
    ECHO_INFO "Config saslauthd to use MySQL bind: ${SASLAUTHD_CONF}"
    cat > ${SASLAUTHD_CONF} <<EOF
${CONF_MSG}
SOCKETDIR=${SASLAUTHD_SOCKETDIR}
MECH=rimap
FLAGS="-r -O 127.0.0.1"
EOF

    cat >> ${TIP_FILE} <<EOF
Cyrus-SASL (MySQL):
    * Configuration files:
        - ${SASLAUTHD_CONF}

EOF

    echo 'export status_cyrus_sasl_config_mysql="DONE"' >> ${STATUS_FILE}
}

# -------------------------------------------------------
# ------------------ Config Cyrus-SASL ------------------
# -------------------------------------------------------
cyrus_sasl_config()
{
    backup_file ${SASLAUTHD_CONF} ${ETC_SASLAUTHD_CONF}
    mkdir -p ${SASLAUTHD_SOCKETDIR}

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        check_status_before_run cyrus_sasl_config_ldap
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        check_status_before_run cyrus_sasl_config_mysql
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
Cyrus-SASL:
    * Configuration files:
        - ${SMTPD_CONF}
    * RC script:
        - /etc/init.d/saslauthd

EOF
    echo 'export status_cyrus_sasl_config="DONE"' >> ${STATUS_FILE}
}
