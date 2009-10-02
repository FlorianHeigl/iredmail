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
# ------------------- OpenLDAP --------------------------
# -------------------------------------------------------

openldap_config()
{
    ECHO_INFO "==================== OpenLDAP ===================="

    backup_file ${OPENLDAP_SLAPD_CONF} ${OPENLDAP_LDAP_CONF}

    ECHO_INFO "Set file permission on TLS cert key file: ${SSL_KEY_FILE}."
    if [ X"${ACL_AVAILABLE}" != X"NO" ]; then
        setfacl -m u:${LDAP_USER}:r-- ${SSL_KEY_FILE}
    else
        chmod +r ${SSL_KEY_FILE}
    fi

    # Add ${LDAP_USER} to 'ssl-cert' group, so that slapd service can read the SSL key.
    [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && usermod -G ssl-cert ${LDAP_USER}

    # Copy ${PROG_NAME}.schema.
    cp -f ${SAMPLE_DIR}/iredmail.schema ${OPENLDAP_SCHEMA_DIR}

    ECHO_INFO "Generate new server configuration file: ${OPENLDAP_SLAPD_CONF}."
    cat > ${OPENLDAP_SLAPD_CONF} <<EOF
${CONF_MSG}
# Schemas.
include     ${OPENLDAP_SCHEMA_DIR}/core.schema
include     ${OPENLDAP_SCHEMA_DIR}/corba.schema
include     ${OPENLDAP_SCHEMA_DIR}/cosine.schema
include     ${OPENLDAP_SCHEMA_DIR}/inetorgperson.schema
include     ${OPENLDAP_SCHEMA_DIR}/nis.schema
# Schema provided by ${PROG_NAME}.
include     ${OPENLDAP_SCHEMA_DIR}/${PROG_NAME_LOWERCASE}.schema

# Where the pid file is put. The init.d script will not stop the
# server if you change this.
pidfile     ${OPENLDAP_PID_FILE}

# List of arguments that were passed to the server
argsfile    ${OPENLDAP_ARGS_FILE}

# TLS files.
TLSCACertificateFile ${SSL_CERT_FILE}
TLSCertificateFile ${SSL_CERT_FILE}
TLSCertificateKeyFile ${SSL_KEY_FILE}

EOF

    # Load backend module. Required on Debian/Ubuntu.
    if [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        if [ X"${OPENLDAP_DEFAULT_DBTYPE}" == X"bdb" ]; then
            # bdb, Berkeley DB.
            cat >> ${OPENLDAP_SLAPD_CONF} <<EOF
# Modules.
modulepath  ${OPENLDAP_MODULE_PATH}
moduleload  back_bdb

EOF
        elif [ X"${OPENLDAP_DEFAULT_DBTYPE}" == X"hdb" ]; then
            # hdb.
            cat >> ${OPENLDAP_SLAPD_CONF} <<EOF
# Modules.
modulepath  ${OPENLDAP_MODULE_PATH}
moduleload  back_hdb

EOF
        else
            :
        fi
    else
        :
    fi

    cat >> ${OPENLDAP_SLAPD_CONF} <<EOF
#
# Disallow bind as anonymous.
#
disallow    bind_anon

#
# Specify LDAP protocol version.
#require     LDAPv3
allow       bind_v2

# Log level.
#   -1:     enable all debugging
#    0:     no debugging
#   128:    access control list processing
#   256:    stats log connections/operations/results
loglevel    0

#
# Access Control List. Used for LDAP bind.
#
# NOTE: Every domain have a administrator. e.g.
#   Domain Name: '${FIRST_DOMAIN}'
#   Admin Name: ${LDAP_ATTR_USER_RDN}=${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}, ${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN}, ${LDAP_BASEDN}
#

#
# Set permission for LDAP attrs.
#
access to attrs="${LDAP_ATTR_USER_PASSWD},${LDAP_ATTR_USER_FORWARD}"
    by anonymous    auth
    by self         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by users        none

access to attrs="cn,sn,telephoneNumber"
    by anonymous    auth
    by self         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by users        read

# Domain attrs.
access to attrs="objectclass,${LDAP_ATTR_DOMAIN_RDN},${LDAP_ATTR_MTA_TRANSPORT},${LDAP_ENABLED_SERVICE},${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS},${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS},${LDAP_ATTR_DOMAIN_ADMIN},${LDAP_ATTR_DOMAIN_GLOBALADMIN},${LDAP_ATTR_DOMAIN_BACKUPMX},${LDAP_ATTR_DOMAIN_MAX_QUOTA_SIZE},${LDAP_ATTR_DOMAIN_MAX_USER_NUMBER}"
    by anonymous    auth
    by self         read
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by users        read

# User attrs.
access to attrs="employeeNumber,homeDirectory,mailMessageStore,${LDAP_ATTR_USER_RDN},${LDAP_ATTR_ACCOUNT_STATUS},${LDAP_ATTR_USER_SENDER_BCC_ADDRESS},${LDAP_ATTR_USER_RECIPIENT_BCC_ADDRESS},${LDAP_ATTR_USER_FORWARD},${LDAP_ATTR_USER_QUOTA},${LDAP_ATTR_USER_BACKUP_MAIL_ADDRESS},${LDAP_ATTR_USER_SHADOW_ADDRESS}"
    by anonymous    auth
    by self         read
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
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
# Allow domain admin to modify accounts under same domain.
#
access to dn.regex="${LDAP_ATTR_DOMAIN_RDN}=([^,]+),${LDAP_BASEDN}\$"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_RDN}=[^,]+@\$1,${LDAP_ADMIN_BASEDN}\$" write
    by dn.regex="${LDAP_ATTR_USER_RDN}=[^,]+@\$1,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=\$1,${LDAP_BASEDN}\$" read
    by users                        none

#
# Enable vmail/vmailadmin. 
#
access to dn.subtree="${LDAP_BASEDN}"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by dn.regex="${LDAP_ATTR_USER_RDN}=[^,]+,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=\$1,${LDAP_BASEDN}\$" read
    by users                        read

access to dn.subtree="${LDAP_ADMIN_BASEDN}"
    by anonymous                    auth
    by self                         write
    by dn.exact="${LDAP_BINDDN}"   read
    by dn.exact="${LDAP_ADMIN_DN}"  write
    by users                        none

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

database    ${OPENLDAP_DEFAULT_DBTYPE}
suffix      ${LDAP_SUFFIX}
directory   ${LDAP_DATA_DIR}

rootdn      ${LDAP_ROOTDN}
rootpw      $(gen_ldap_passwd "${LDAP_ROOTPW}")

sizelimit   1000
cachesize   1000

#
# Set directory permission.
#
mode        0700

#
# Default index.
#
index objectClass                                   eq,pres
index ou,cn,mail,surname,givenname,telephoneNumber  eq,pres,sub
index uidNumber,gidNumber,loginShell                eq,pres
index uid,memberUid                                 eq,pres,sub
index nisMapName,nisMapEntry                        eq,pres,sub

#
# Index for mail attrs.
#
# ---- Domain related ----
index ${LDAP_ATTR_DOMAIN_RDN},${LDAP_ATTR_MTA_TRANSPORT},${LDAP_ATTR_ACCOUNT_STATUS},${LDAP_ENABLED_SERVICE}  eq,pres
index ${LDAP_ATTR_DOMAIN_QUOTA},${LDAP_ATTR_DOMAIN_MAX_USER_NUMBER} eq,pres
index ${LDAP_ATTR_DOMAIN_ADMIN},${LDAP_ATTR_DOMAIN_GLOBALADMIN},${LDAP_ATTR_DOMAIN_BACKUPMX}    eq,pres
index ${LDAP_ATTR_DOMAIN_SENDER_BCC_ADDRESS},${LDAP_ATTR_DOMAIN_RECIPIENT_BCC_ADDRESS}  eq,pres
# ---- Group related ----
index ${LDAP_ATTR_GROUP_ACCESSPOLICY},${LDAP_ATTR_GROUP_HASMEMBER},${LDAP_ATTR_GROUP_ALLOWED_USER}   eq,pres
# ---- User related ----
index homeDirectory,mailMessageStore,${LDAP_ATTR_USER_FORWARD},${LDAP_ATTR_USER_SHADOW_ADDRESS}   eq,pres
index ${LDAP_ATTR_USER_BACKUP_MAIL_ADDRESS},${LDAP_ATTR_USER_MEMBER_OF_GROUP}   eq,pres
EOF

    # Make slapd use slapd.conf insteald of slapd.d (cn=config backend).
    [ X"${DISTRO}" == X"UBUNTU" ] && \
        perl -pi -e 's#^(SLAPD_CONF=).*#${1}"$ENV{OPENLDAP_SLAPD_CONF}"#' ${ETC_SYSCONFIG_DIR}/slapd && \
        perl -pi -e 's#^(SLAPD_PIDFILE=).*#${1}"$ENV{OPENLDAP_PID_FILE}"#' ${ETC_SYSCONFIG_DIR}/slapd

    ECHO_INFO "Generate new client configuration file: ${OPENLDAP_LDAP_CONF}"
    cat > ${OPENLDAP_LDAP_CONF} <<EOF
BASE    ${LDAP_SUFFIX}
URI     ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}
TLS_CACERT ${SSL_CERT_FILE}
EOF
    chown ${LDAP_USER}:${LDAP_GROUP} ${OPENLDAP_LDAP_CONF}

    ECHO_INFO "Setting up syslog configration file for OpenLDAP."
    echo -e "local4.*\t\t\t\t\t\t-${OPENLDAP_LOGFILE}" >> ${SYSLOG_CONF}

    ECHO_INFO "Create empty log file for OpenLDAP: ${OPENLDAP_LOGFILE}."
    touch ${OPENLDAP_LOGFILE}
    chown ${LDAP_USER}:${LDAP_GROUP} ${OPENLDAP_LOGFILE}
    chmod 0600 ${OPENLDAP_LOGFILE}

    ECHO_INFO "Setting logrotate for openldap log file: ${OPENLDAP_LOGFILE}."
    cat > ${OPENLDAP_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${OPENLDAP_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 ${LDAP_USER} ${LDAP_GROUP}
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

    ECHO_INFO "Restarting syslog."
    if [ X"${DISTRO}" == X"RHEL" ]; then
        service_control syslog restart >/dev/null
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        # Debian 4, Ubuntu 9.04 -> /etc/init.d/sysklogd
        # Debian 5  -> /etc/init.d/rsyslog
        [ -x /etc/init.d/sysklogd ] && service_control sysklogd restart >/dev/null
        [ -x /etc/init.d/rsyslog ] && service_control rsyslog restart >/dev/null
    else
        :
    fi

    echo 'export status_openldap_config="DONE"' >> ${STATUS_FILE}
}

openldap_data_initialize()
{
    if [ X"${DISTRO_CODENAME}" == X"hardy" -a -f /etc/apparmor.d/usr.sbin.slapd ]; then
        sed -i "s|\(}\)| # Added by ${PROG_NAME}-${PROG_VERSION}. \n\1|" /etc/apparmor.d/usr.sbin.slapd
        sed -i "s#\(}\)# ${LDAP_DATA_DIR}/ r,\n\1#" /etc/apparmor.d/usr.sbin.slapd
        sed -i "s#\(}\)# ${LDAP_DATA_DIR}/* rw,\n\1#" /etc/apparmor.d/usr.sbin.slapd
        sed -i "s#\(}\)# ${LDAP_DATA_DIR}/alock kw,\n\1#" /etc/apparmor.d/usr.sbin.slapd
        service_control apparmor restart >/dev/null
    else
        :
    fi

    ECHO_INFO "Create instance directory for openldap tree: ${LDAP_DATA_DIR}."
    mkdir -p ${LDAP_DATA_DIR}
    cp -f ${OPENLDAP_DB_CONFIG_SAMPLE} ${LDAP_DATA_DIR}/DB_CONFIG
    chown -R ${LDAP_USER}:${LDAP_GROUP} ${OPENLDAP_DATA_DIR}
    chmod -R 0700 ${OPENLDAP_DATA_DIR}

    ECHO_INFO "Starting OpenLDAP."
    if [ X"${DISTRO}" == X"RHEL" ]; then
        service_control ldap restart >/dev/null
    elif [ X"${DISTRO}" == X"UBUNTU" -o X"${DISTRO}" == X"DEBIAN" ]; then
        service_control slapd restart >/dev/null
    else
        :
    fi
    
    ECHO_INFO -n "Sleep 5 seconds for LDAP daemon initialize:"
    for i in $(seq 5 -1 1); do
        echo -n " ${i}s" && sleep 1
    done
    echo '.'

    ECHO_INFO "Initialize LDAP tree."
    # home_mailbox format is 'maildir/' by default.
    cat > ${LDAP_INIT_LDIF} <<EOF
dn: ${LDAP_SUFFIX}
objectclass: dcObject
objectclass: organization
dc: ${LDAP_SUFFIX_MAJOR}
o: ${LDAP_SUFFIX_MAJOR}

dn: ${LDAP_BINDDN}
objectClass: person
objectClass: shadowAccount
objectClass: top
cn: ${VMAIL_USER_NAME}
sn: ${VMAIL_USER_NAME}
uid: ${VMAIL_USER_NAME}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${LDAP_BINDPW}")

dn: ${LDAP_ADMIN_DN}
objectClass: person
objectClass: shadowAccount
objectClass: top
cn: ${VMAIL_ADMIN_USER_NAME}
sn: ${VMAIL_ADMIN_USER_NAME}
uid: ${VMAIL_ADMIN_USER_NAME}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${LDAP_ADMIN_PW}")

dn: ${LDAP_BASEDN}
objectClass: Organization
o: ${LDAP_BASEDN_NAME}

dn: ${LDAP_ADMIN_BASEDN}
objectClass: Organization
o: ${LDAP_ATTR_DOMAINADMIN_DN_NAME}

dn: ${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_MAILDOMAIN}
${LDAP_ATTR_DOMAIN_RDN}: ${FIRST_DOMAIN}
${LDAP_ATTR_MTA_TRANSPORT}: ${TRANSPORT}
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MAIL}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SENDER_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_RECIPIENT_BCC}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_USERS}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_GROUPS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_GROUPS}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_ALIASES},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_ALIASES}

dn: ${LDAP_ATTR_USER_RDN}=${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN},${LDAP_ADMIN_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_MAILADMIN}
objectClass: shadowAccount
objectClass: top
cn: ${DOMAIN_ADMIN_NAME}
uid: ${DOMAIN_ADMIN_NAME}
givenName: ${DOMAIN_ADMIN_NAME}
${LDAP_ATTR_USER_RDN}: ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${DOMAIN_ADMIN_PASSWD}")
${LDAP_ATTR_DOMAIN_GLOBALADMIN}: ${LDAP_VALUE_DOMAIN_GLOBALADMIN}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_AWSTATS}

dn: ${LDAP_ATTR_USER_RDN}=all@${FIRST_DOMAIN},${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_GROUPS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_MAILGROUP}
cn: All users
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ATTR_USER_RDN}: all@${FIRST_DOMAIN}
${LDAP_ATTR_GROUP_HASMEMBER}: ${LDAP_VALUE_GROUP_HASMEMBER}

dn: ${LDAP_ATTR_USER_RDN}=${FIRST_USER}@${FIRST_DOMAIN},${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: ${LDAP_OBJECTCLASS_MAILUSER}
objectClass: top
cn: ${FIRST_USER}
sn: ${FIRST_USER}
uid: ${FIRST_USER}
givenName: ${FIRST_USER}
${LDAP_ATTR_USER_RDN}: ${FIRST_USER}@${FIRST_DOMAIN}
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ATTR_USER_STORAGE_BASE_DIRECTORY}: ${STORAGE_BASE_DIR}
mailMessageStore: $( hash_domain ${FIRST_DOMAIN})/$( hash_maildir ${FIRST_USER} )
homeDirectory: ${STORAGE_BASE_DIR}/$( hash_domain ${FIRST_DOMAIN})/$( hash_maildir ${FIRST_USER} )
${LDAP_ATTR_USER_QUOTA}: 104857600
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${FIRST_USER_PASSWD}")
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MAIL}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SMTP}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_POP3}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_IMAP}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DELIVER}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_FORWARD}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SENDER_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_RECIPIENT_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MANAGESIEVE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DISPLAYED_IN_ADDRBOOK}
${LDAP_ATTR_USER_MEMBER_OF_GROUP}: all@${FIRST_DOMAIN}
EOF

    ldapadd -x -D "${LDAP_ROOTDN}" -w "${LDAP_ROOTPW}" -f ${LDAP_INIT_LDIF}

    cat >> ${TIP_FILE} <<EOF
OpenLDAP:
    * Configuration files:
        - ${OPENLDAP_CONF_ROOT}
        - ${OPENLDAP_SLAPD_CONF}
        - ${OPENLDAP_LDAP_CONF}
        - ${OPENLDAP_SCHEMA_DIR}/${PROG_NAME_LOWERCASE}.schema
    * Log file related:
        - ${SYSLOG_CONF}
        - ${OPENLDAP_LOGFILE}
        - ${OPENLDAP_LOGROTATE_FILE}
    * Data dir and files:
        - ${OPENLDAP_DATA_DIR}
        - ${LDAP_DATA_DIR}
        - ${LDAP_DATA_DIR}/DB_CONFIG
    * RC script:
        - ${LDAP_INIT_SCRIPT}
    * See also:
        - ${LDAP_INIT_LDIF}

EOF

    echo 'export status_openldap_data_initialize="DONE"' >> ${STATUS_FILE}
}

