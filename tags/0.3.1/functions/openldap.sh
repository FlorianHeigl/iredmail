#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ------------------- OpenLDAP --------------------------
# -------------------------------------------------------

openldap_config()
{
    backup_file ${OPENLDAP_SLAPD_CONF} ${OPENLDAP_LDAP_CONF}

    ECHO_INFO "Set file permission on TLS cert key file: ${SSL_KEY_FILE}."
    setfacl -m u:ldap:r-- ${SSL_KEY_FILE}

    # Copy ${PROG_NAME}.schema.
    cp -f ${SAMPLE_DIR}/${PROG_NAME_LOWERCASE}.schema ${OPENLDAP_SCHEMA_DIR}

    ECHO_INFO "Generate new configuration file: ${OPENLDAP_SLAPD_CONF}."
    cat > ${OPENLDAP_SLAPD_CONF} <<EOF
${CONF_MSG}
include     ${OPENLDAP_SCHEMA_DIR}/core.schema
include     ${OPENLDAP_SCHEMA_DIR}/corba.schema
include     ${OPENLDAP_SCHEMA_DIR}/cosine.schema
include     ${OPENLDAP_SCHEMA_DIR}/inetorgperson.schema
include     ${OPENLDAP_SCHEMA_DIR}/nis.schema

include     ${OPENLDAP_SCHEMA_DIR}/${PROG_NAME_LOWERCASE}.schema

pidfile     /var/run/openldap/slapd.pid
argsfile    /var/run/openldap/slapd.args

TLSCACertificateFile ${SSL_CERT_FILE}
TLSCertificateFile ${SSL_CERT_FILE}
TLSCertificateKeyFile ${SSL_KEY_FILE}

#
# Disallow bind as anonymous.
#
disallow    bind_anon

#
# Specify LDAP protocol version.
#require     LDAPv3
allow       bind_v2

# For debug
#loglevel   -1
#loglevel   64
#loglevel   256
loglevel    0

#
# Access Control List. Used for LDAP bind.
#
# NOTE: Every domain have a administrator.
#   For domain: '${FIRST_DOMAIN}'
#   Administrator:
#       ${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}, ${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN}, ${LDAP_BASEDN}
#

#
# Set permission for LDAP attrs.
#
access to attrs="${LDAP_ATTR_USER_PASSWD},${LDAP_ATTR_USER_ALIAS}"
    by anonymous    auth
    by self         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@([^,]+),${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}"   write
    by users        none

access to attrs="cn,sn"
    by anonymous    auth
    by self         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@([^,]+),${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}"   write
    by users        read

# Domain attrs.
access to attrs="objectclass,${LDAP_ATTR_DOMAIN_DN_NAME},${LDAP_ATTR_DOMAIN_TRANSPORT},${LDAP_ATTR_DOMAIN_STATUS},${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS},${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS}"
    by anonymous    auth
    by self         read
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@([^,]+),${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}"    write
    by users        read

# User attrs.
access to attrs="${LDAP_ATTR_USER_DN_NAME},${LDAP_ATTR_USER_STATUS},${LDAP_ATTR_USER_SENDER_BCC_ADDRESS},${LDAP_ATTR_USER_RECIPIENT_BCC_ADDRESS},${LDAP_ATTR_USER_ALIAS},${LDAP_ATTR_USER_QUOTA},homeDirectory,mailMessageStore"
    by anonymous    auth
    by self         read
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@([^,]+),${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}"    write
    by users        read

#
# Set ACL for vmail/vmailadmin.
#
access to dn="${LDAP_BINDDN}"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by users                        none
access to dn="${LDAP_ADMIN_DN}"
    by anonymous                    auth
    by self                         write
    by users                        none

#
# Allow users to access their own domain subtree.
#
access to dn.regex="${LDAP_ATTR_DOMAIN_DN_NAME}=([^,]+),${LDAP_BASEDN}\$"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@\$1,${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}\$" write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=[^,]+,${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}\$" read
    by users                        none
#
# Enable vmail/vmailadmin. 
#
access to dn.subtree="${LDAP_BASEDN}"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_DN_NAME}=[^,]+,${LDAP_ATTR_DOMAIN_DN_NAME}=\$1,${LDAP_BASEDN}\$" read
    by users                        read

#
# Set permission for "cn=*,${LDAP_SUFFIX}".
#
access to dn.regex="cn=[^,]+,${LDAP_SUFFIX}"
    by anonymous                    auth
    by self                         write
    by users                        none
#
# Set default permission.
#
access to *
    by anonymous                    auth
    by self                         write
    by users                        read

#######################################################################
# BDB database definitions
#######################################################################

database    bdb
suffix      "${LDAP_SUFFIX}"
directory   ${LDAP_DATA_DIR}

rootdn      "${LDAP_ROOTDN}"
rootpw      $(gen_ldap_passwd ${LDAP_ROOTPW})

#
# Set directory permission.
#
mode        0700

#
# Default index.
#
index objectClass                       eq,pres
index ou,cn,mail,surname,givenname      eq,pres,sub
index uidNumber,gidNumber,loginShell    eq,pres
index uid,memberUid                     eq,pres,sub
index nisMapName,nisMapEntry            eq,pres,sub

#
# Index for mail attrs.
#
index ${LDAP_ATTR_DOMAIN_DN_NAME},${LDAP_ATTR_DOMAIN_TRANSPORT},${LDAP_ATTR_DOMAIN_STATUS}  eq,pres
index ${LDAP_ATTR_DOMAIN_QUOTA},${LDAP_ATTR_DOMAIN_USER_NUMBER} eq,pres
index ${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS},${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS}  eq,pres
index homeDirectory,mailMessageStore,${LDAP_ATTR_USER_ALIAS},${LDAP_ATTR_USER_STATUS}   eq,pres

cachesize   1000
EOF

    ECHO_INFO "Generating new LDAP client configuration file: ${OPENLDAP_LDAP_CONF}"
    cat > ${OPENLDAP_LDAP_CONF} <<EOF
BASE    ${LDAP_SUFFIX}
URI     ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}
TLS_CACERT ${OPENLDAP_CACERT_DIR}/slapdCert.pem
EOF

    ECHO_INFO "Setting up syslog configration file for openldap: /etc/syslog.conf"
    echo -e "local4.*\t\t\t\t\t\t-${OPENLDAP_LOGFILE}" >>/etc/syslog.conf

    ECHO_INFO "Create empty log file for OpenLDAP: ${OPENLDAP_LOGFILE}."
    touch ${OPENLDAP_LOGFILE}
    chown ldap:ldap ${OPENLDAP_LOGFILE}
    chmod 0600 ${OPENLDAP_LOGFILE}

    ECHO_INFO "Setting logrotate for openldap log file: ${OPENLDAP_LOGFILE}."
    cat > ${OPENLDAP_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${OPENLDAP_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 ldap ldap
    missingok
    postrotate
        /usr/bin/killall -HUP syslogd
    endscript
}
EOF

    ECHO_INFO "Make OpenLDAP listen on '127.0.0.1' only."
    cp /etc/init.d/ldap /etc/init.d/ldap.bak
    chmod -x /etc/init.d/ldap.bak
    perl -pi -e 's#(.*ldap.*://)(/)#${1}127.0.0.1${2}#' /etc/init.d/ldap

    ECHO_INFO "Restarting syslog."
    /etc/init.d/syslog restart >/dev/null

    echo 'export status_openldap_config="DONE"' >> ${STATUS_FILE}
}

openldap_data_initialize()
{
    ECHO_INFO "Create instance directory for openldap tree: ${LDAP_DATA_DIR}."
    mkdir -p ${LDAP_DATA_DIR}
    chown -R ldap:ldap ${OPENLDAP_DATA_DIR}
    chmod -R 0700 ${OPENLDAP_DATA_DIR}

    ECHO_INFO "Generate DB_CONFIG for instance: ${LDAP_DATA_DIR}/DB_CONFIG."
    cp ${OPENLDAP_ROOTDIR}/DB_CONFIG.example ${LDAP_DATA_DIR}/DB_CONFIG

    ECHO_INFO "Starting OpenLDAP."
    /etc/init.d/ldap restart >/dev/null
    
    ECHO_INFO -n "Sleep 5 seconds for LDAP daemon initialize:"
    for i in $(seq 5 -1 1); do
        echo -n " ${i}s" && sleep 1
    done
    echo '.'

    ECHO_INFO "Initialization LDAP tree."
    # home_mailbox format is 'maildir/' by default.
    cat > ${LDAP_INIT_LDIF} <<EOF
dn: ${LDAP_SUFFIX}
objectclass: dcObject
objectclass: organization
dc: ${LDAP_SUFFIX_MAJOR}
o: ${LDAP_SUFFIX_MAJOR}

dn: o=${LDAP_BASEDN_NAME},${LDAP_SUFFIX}
objectClass: Organization
o: ${LDAP_BASEDN_NAME}

dn: ${LDAP_BINDDN}
objectClass: person
objectClass: top
cn: ${VMAIL_USER_NAME}
sn: ${VMAIL_USER_NAME}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd ${LDAP_BINDPW})

dn: ${LDAP_ADMIN_DN}
objectClass: person
objectClass: top
cn: ${VMAIL_ADMIN_USER_NAME}
sn: ${VMAIL_ADMIN_USER_NAME}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd ${LDAP_ADMIN_PW})

dn: ${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_DOMAIN}
${LDAP_ATTR_DOMAIN_DN_NAME}: ${FIRST_DOMAIN}
${LDAP_ATTR_DOMAIN_TRANSPORT}: ${TRANSPORT}
${LDAP_ATTR_DOMAIN_STATUS}: active

dn: ${LDAP_ATTR_USER_DN_NAME}=${FIRST_USER}@${FIRST_DOMAIN},${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: inetOrgPerson
objectClass: ${LDAP_OBJECTCLASS_USER}
objectClass: top
cn: ${FIRST_USER}
sn: ${FIRST_USER}
uid: ${FIRST_USER}
${LDAP_ATTR_USER_DN_NAME}: ${FIRST_USER}@${FIRST_DOMAIN}
${LDAP_ATTR_USER_STATUS}: active
homeDirectory: ${VMAIL_USER_HOME_DIR}
mailMessageStore: ${FIRST_DOMAIN}/${FIRST_USER}/
${LDAP_ATTR_USER_QUOTA}: 10485760
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd ${FIRST_USER_PASSWD})
${LDAP_ATTR_USER_ENABLE_SMTP}: yes
${LDAP_ATTR_USER_ENABLE_DELIVER}: yes
${LDAP_ATTR_USER_ENABLE_POP3}: yes
${LDAP_ATTR_USER_ENABLE_IMAP}: yes

dn: ${LDAP_ATTR_USER_DN_NAME}=${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN},${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: inetOrgPerson
objectClass: ${LDAP_OBJECTCLASS_USER}
objectClass: top
cn: ${FIRST_DOMAIN_ADMIN_NAME}
sn: ${FIRST_DOMAIN_ADMIN_NAME}
uid: ${FIRST_DOMAIN_ADMIN_NAME}
${LDAP_ATTR_USER_DN_NAME}: ${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}
${LDAP_ATTR_USER_STATUS}: active
homeDirectory: ${VMAIL_USER_HOME_DIR}
mailMessageStore: ${FIRST_DOMAIN}/${FIRST_DOMAIN_ADMIN_NAME}/
${LDAP_ATTR_USER_QUOTA}: 0
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd ${FIRST_DOMAIN_ADMIN_PASSWD})
${LDAP_ATTR_USER_ENABLE_SMTP}: yes
${LDAP_ATTR_USER_ENABLE_DELIVER}: yes
${LDAP_ATTR_USER_ENABLE_POP3}: yes
${LDAP_ATTR_USER_ENABLE_IMAP}: yes
EOF

    # Maildir format.
    [ X"${HOME_MAILBOX}" == X"mbox" ] && \
        perl -pi -e 's#^(mailMessageStore.*)/#${1}#' ${LDAP_INIT_LDIF} && \
        perl -pi -e 's#^($ENV{LDAP_ATTR_USER_QUOTA}: )0#${1}1000000000000000000000#' ${LDAP_INIT_LDIF}

    ldapadd -x -D "${LDAP_ROOTDN}" -w "${LDAP_ROOTPW}" -f ${LDAP_INIT_LDIF}

    cat >> ${TIP_FILE} <<EOF
OpenLDAP:
    * Configuration files:
        - ${OPENLDAP_ROOTDIR}
        - ${OPENLDAP_SLAPD_CONF}
        - ${OPENLDAP_LDAP_CONF}
        - ${OPENLDAP_SCHEMA_DIR}/${PROG_NAME_LOWERCASE}.schema
    * Log file related:
        - /etc/syslog.conf
        - ${OPENLDAP_LOGROTATE_FILE}
        - ${OPENLDAP_LOGFILE}
    * Data dir and files:
        - ${OPENLDAP_DATA_DIR}
        - ${LDAP_DATA_DIR}
        - ${LDAP_DATA_DIR}/DB_CONFIG
    * RC script:
        - /etc/init.d/ldap
    * See also:
        - ${LDAP_INIT_LDIF}
        - ${OPENLDAP_CACERT_DIR}

EOF

    echo 'export status_openldap_data_initialize="DONE"' >> ${STATUS_FILE}
}

