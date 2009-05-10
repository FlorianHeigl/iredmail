#!/bin/bash

# Filename: create_mail_ldap_user.sh
# Author:   Zhang Huangbin (michaelbibby#gmail.com)
# Lastest update date:  2009.02.19
# Purpose: Add new OpenLDAP user for postfix mail server.
#
# Shipped within iRedMail project:
#   * http://code.google.com/p/iredmail/

# --------------------------- WARNING ------------------------------
# This script only works under iRedMail >= 0.3.3 due to ldap schema
# changes.
# ------------------------------------------------------------------

# --------------------------- USAGE --------------------------------
# Please change variables below to fit your env:
#   - In 'Global Setting' section:
#       * STORAGE_BASE_DIRECTORY
#       * VMAIL_USER_NAME
#       * VMAIL_GROUP_NAME
#
#   - In 'LDAP Setting' section:
#       * LDAP_SUFFIX
#       * BINDDN
#       * BINDPW
#       * QUOTA
#
#   - In 'Virtual Domains & Users' section:
#       * QUOTA
#       * TRANSPORT
#       * CRYPT_MECH                # SSHA is recommended.
#       * DEFAULT_PASSWD
#       * USE_DEFAULT_PASSWD
#       * USE_NAME_AS_PASSWD

#   - Optional variables:
#       * SEND_WELCOME_MSG
# ------------------------------------------------------------------

# ----------------------------------------------
# ------------ Global Setting ------------------
# ----------------------------------------------
# Storage base directory used to store users' mail.
# mailbox of LDAP user will be:
#    ${STORAGE_BASE_DIRECTORY}/${DOMAIN_NAME}/${USERNAME}/
# Such as:
#    /home/vmail/domains/domain1.com/bibby/
#   -------------------|===========|-----|
#   STORAGE_BASE_DIRECTORY|DOMAIN_NAME|USERNAME
#
STORAGE_BASE_DIRECTORY="/home/vmail"

# All mails will be stored under user vmail's home directory.
# Files and directories will be ownned as 'vmail:vmail'.
# By default it's 'vmail:vmail'.
VMAIL_USER_NAME="vmail"
VMAIL_GROUP_NAME='vmail'

# Mailbox format: mbox, Maildir.
MAILBOX_FORMAT='Maildir'

# Mailbox style: hashed, normal.
MAILDIR_STYLE='hashed'

# ------------------------------------------------------------------
# -------------------------- LDAP Setting --------------------------
# ------------------------------------------------------------------
LDAP_SUFFIX="dc=iredmail,dc=org"

# Setting 'BASE_DN'.
BASE_DN="o=domains,${LDAP_SUFFIX}"

# Setting 'DOMAIN_NAME' and DOMAIN_DN':
#     * DOMAIN will be used in mail address: ${USERNAME}@${DOMAIN}
#    * DOMAIN_DN will be used in LDAP dn.
DOMAIN_NAME="$1"
DOMAIN_DN="domainName=${DOMAIN_NAME}"
OU_USER_DN="ou=Users"

# ---------- rootdn of LDAP Server ----------
# Setting rootdn of LDAP.
BINDDN="cn=Manager,${LDAP_SUFFIX}"

# Setting rootpw of LDAP.
BINDPW='passwd'
 
# ---------- Virtual Domains & Users --------------
# Set default quota for LDAP users: 104857600 = 100M
QUOTA='104857600'

# Default MTA Transport (Defined in postfix master.cf).
TRANSPORT='dovecot'

# Password setting.
CRYPT_MECH='SSHA'   # MD5, SSHA. SSHA is recommended.
DEFAULT_PASSWD='888888'
USE_DEFAULT_PASSWD='NO'
USE_NAME_AS_PASSWD='YES'

# ------------------------------------------------------------------
# ------------------------- Welcome Msg ----------------------------
# ------------------------------------------------------------------
# Send a welcome mail after user created.
SEND_WELCOME_MSG='NO'

# Set welcome mail info.
WELCOME_MSG_SUBJECT="Welcome!"
WELCOME_MSG_BODY="Welcome, new user."

# -------------------------------------------
# ----------- End Global Setting ------------
# -------------------------------------------

# Time stamp, will be appended in maildir.
DATE="$(date +%Y.%m.%d.%H.%M.%S)"

add_new_domain()
{
    ldapsearch -x -D "${BINDDN}" -w "${BINDPW}" -b "${BASE_DN}" | grep "domainName: ${DOMAIN_NAME}" >/dev/null

    if [ X"$?" != X"0" ]; then
        echo "Add new domain: ${DOMAIN_NAME}."

        ldapadd -x -D "${BINDDN}" -w "${BINDPW}" <<EOF
dn: ${DOMAIN_DN},${BASE_DN}
objectClass: mailDomain
domainName: ${DOMAIN_NAME}
mtaTransport: ${TRANSPORT}
accountStatus: active
enableMailService: yes
EOF
    else
        :
    fi

    ldapadd -x -D "${BINDDN}" -w "${BINDPW}" <<EOF
dn: ${OU_USER_DN},${DOMAIN_DN},${BASE_DN}
objectClass: organizationalUnit
objectClass: top
ou: Users
EOF

    ldapadd -x -D "${BINDDN}" -w "${BINDPW}" <<EOF
dn: ou=Groups,${DOMAIN_DN},${BASE_DN}
objectClass: organizationalUnit
objectClass: top
ou: Groups
EOF

    ldapadd -x -D "${BINDDN}" -w "${BINDPW}" <<EOF
dn: ou=Aliases,${DOMAIN_DN},${BASE_DN}
objectClass: organizationalUnit
objectClass: top
ou: Aliases
EOF
}

add_new_user()
{
    USERNAME="$1"
    MAIL="$2"

    # Create template LDIF file for this new user and add it.
    # If you do *NOT* want to keep rootpw in script, use '-W' instead of 
    # '-w "${BINDPW}".

    # Different maildir style: hashed, normal.
    if [ X"${MAILDIR_STYLE}" == X"hashed" ]; then
        length="$(echo ${USERNAME} | wc -L)"
        str1="$(echo ${USERNAME} | cut -c1)"
        str2="$(echo ${USERNAME} | cut -c2)"
        str3="$(echo ${USERNAME} | cut -c3)"

        if [ X"${length}" == X"1" ]; then
            str2="${str1}"
            str3="${str1}"
        elif [ X"${length}" == X"2" ]; then
            str3="${str2}"
        else
            :
        fi

        # Use mbox, will be changed later.
        maildir="${DOMAIN_NAME}/${str1}/${str1}${str2}/${str1}${str2}${str3}/${USERNAME}-${DATE}"
    else
        # Use mbox, will be changed later.
        maildir="${DOMAIN_NAME}/${USERNAME}-${DATE}"
    fi

    # For maildir format.
    [ X"${MAILBOX_FORMAT}" == X"Maildir" ] && mailMessageStore="${maildir}/"
    [ X"${MAILBOX_FORMAT}" == X"mbox" ] && mailMessageStore="${maildir}"

    # Generate user password.
    if [ X"${USE_DEFAULT_PASSWD}" == X"YES" ]; then
        PASSWD="$(slappasswd -h {${CRYPT_MECH}} -s ${DEFAULT_PASSWD})"
    else
        PASSWD="$(slappasswd -h {${CRYPT_MECH}} -s ${USERNAME})"
    fi

    ldapadd -x -D "${BINDDN}" -w "${BINDPW}" <<EOF
dn: mail=${MAIL},${OU_USER_DN},${DOMAIN_DN},${BASE_DN}
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: mailUser
objectClass: top
storageBaseDirectory: ${STORAGE_BASE_DIRECTORY}
homeDirectory: ${STORAGE_BASE_DIRECTORY}/${mailMessageStore}
accountStatus: active
mailMessageStore: ${mailMessageStore}
mail: ${MAIL}
mailQuota: ${QUOTA}
userPassword: ${PASSWD}
cn: ${USERNAME}
sn: ${USERNAME}
givenName: ${USERNAME}
uid: ${USERNAME}
enabledService: mail
enabledService: imap
enabledService: pop3
enabledService: smtp
enabledService: deliver
enabledService: forward
enabledService: senderbcc
enabledService: recipientbcc
enabledService: managesieve
EOF
}

send_welcome_mail()
{
    MAIL="$1"
    echo "Send a welcome mail to new user: ${MAIL}"

    echo "${WELCOME_MSG_BODY}" | mail -s "${WELCOME_MSG_SUBJECT}" ${MAIL}
}

usage()
{
    echo "Usage:"
    echo -e "\t$0 DOMAIN USERNAME"
    echo -e "\t$0 DOMAIN USER1 USER2 USER3..."
}

if [ $# -lt 2 ]; then
    usage
else
    # Promopt to check settings.
    [ X"${LDAP_SUFFIX}" == X"dc=iredmail,dc=org" ] && echo "You should change 'LDAP_SUFFIX' in $0."

    # Get domain name.
    DOMAIN_NAME="$1"
    shift 1

    add_new_domain ${DOMAIN_NAME}
    for i in $@
    do
        USERNAME="$i"
        MAIL="${USERNAME}@${DOMAIN_NAME}"

        # Add new user in LDAP.
        add_new_user ${USERNAME} ${MAIL}

        # Send welcome msg to new user.
        [ X"${SEND_WELCOME_MSG}" == X"YES" ] && send_welcome_mail ${MAIL}
    done
fi
