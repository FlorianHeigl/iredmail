#!/bin/sh

# Filename: create_mail_ldap_user.sh
# Author:   Zhang Huangbin (michaelbibby#gmail.com)
# Lastest update date:  2009.02.19
# Purpose: Add new OpenLDAP user for postfix mail server.
# Shipped within iRedMail project:
#   * http://iRedMail.googlecode.com/

# --------------------------- WARNING ------------------------------
# This script only works under iRedMail >= 0.3.3 due to ldap schema
# changes.
# ------------------------------------------------------------------

# --------------------------- USAGE --------------------------------
# Please change variables below to fit your env:
#   - In 'Global Setting' section:
#       * VMAIL_USER_NAME
#       * VMAIL_GROUP_NAME
#       * VMAIL_USER_HOME_DIR
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
#       * CREATE_MAILDIR
#       * CRYPT_MECH                # SSHA is recommended.
#       * DEFAULT_PASSWD
#       * USE_DEFAULT_PASSWD
#       * USE_NAME_AS_PASSWD

#   - Optional variables:
#       * CREATE_MAILDIR
#       * SEND_WELCOME_MSG
# ------------------------------------------------------------------

# ----------------------------------------------
# ------------ Global Setting ------------------
# ----------------------------------------------

# Mailbox format: mbox, Maildir.
HOME_MAILBOX='Maildir'

# Maildir format.
# YES:  domain.ltd/username/Maildir/
# No:   domain.ltd/username/
MAILDIR_IN_MAILBOX='NO'
MAILDIR_STRING='Maildir/'

# All mails will be stored under user vmail's home directory.
# Files and directories will be ownned as 'vmail:vmail'.
# By default it's 'vmail:vmail'.
VMAIL_USER_NAME="vmail"
VMAIL_GROUP_NAME='vmail'

# HOME directory for LDAP user.
# mailbox of LDAP user will be:
#    ${VMAIL_USER_HOME_DIR}/${DOMAIN_NAME}/${USERNAME}/
# Such as:
#    /home/vmail/domains/domain1.com/bibby/
#   -------------------|===========|-----|
#   VMAIL_USER_HOME_DIR|DOMAIN_NAME|USERNAME
#
VMAIL_USER_HOME_DIR="/home/vmail"

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
OU_GROUP_DN="ou=Groups"

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

# Create maildir in file system after user created.
# NOTE: We do *NOT* need this step, because dovecot will create user
# mailbox automatic when user login via IMAP/POP3 successfully.
CREATE_MAILDIR='NO'

# Password setting.
CRYPT_MECH='SSHA'   # MD5, SSHA
DEFAULT_PASSWD='888888'
USE_DEFAULT_PASSWD='NO'
USE_NAME_AS_PASSWD='YES'

# ------------------------------------------------------------------
# ------------------------- Welcome Msg ----------------------------
# ------------------------------------------------------------------
# Send a welcome mail after user created.
SEND_WELCOME_MSG='NO'

# Set welcome mail info.
WELCOME_MSG_TITLE="Welcome!"
WELCOME_MSG_BODY="Welcome, new user."

# -------------------------------------------
# ----------- End Global Setting ------------
# -------------------------------------------

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
domainStatus: active
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
dn: ${OU_GROUP_DN},${DOMAIN_DN},${BASE_DN}
objectClass: organizationalUnit
objectClass: top
ou: Groups
EOF
}

add_new_user()
{
    USERNAME="$1"
    MAIL="$2"

    # Create template LDIF file for this new user and add it.
    # If you do *NOT* want to keep rootpw in script, use '-W' instead of 
    # '-w "${BINDPW}".

    # For maildir format.
    if [ X"${MAILDIR_IN_MAILBOX}" == X"YES" -a X"${MAILDIR_STRING}" != X"" ]; then
        [ X"${HOME_MAILBOX}" == X"Maildir" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}/${MAILDIR_STRING}/"
    else
        [ X"${HOME_MAILBOX}" == X"Maildir" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}/"
    fi
    [ X"${HOME_MAILBOX}" == X"mbox" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}"

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
homeDirectory: ${VMAIL_USER_HOME_DIR}
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
EOF
}

create_maildir()
{
    DOMAIN_NAME="$1"
    USERNAME="$2"

    domain_dir="${VMAIL_USER_HOME_DIR}/${DOMAIN_NAME}/"
    user_maildir="${VMAIL_USER_HOME_DIR}/${DOMAIN_NAME}/${USERNAME}/"
    # Use 'maildirmake' to create Maildir before send welcome mail to user.
    echo "Create Maildir: ${user_maildir}."
    mkdir -p ${domain_dir}/{cur,new,tmp,.Junk}

    # Set permission.
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${VMAIL_USER_HOME_DIR}/${DOMAIN_NAME}/${USERNAME}/
    chmod -R 0700 ${VMAIL_USER_HOME_DIR}/${DOMAIN_NAME}/${USERNAME}/
}

send_welcome_mail()
{
    MAIL="$1"
    echo "Send a welcome mail to new user: ${MAIL}"

    echo "${WELCOME_MSG_BODY}" | mail -s "${WELCOME_MSG_TITLE}" ${MAIL}
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

        # Create maildir in file system.
        [ X"${CREATE_MAILDIR}" == X"YES" ] && create_maildir ${DOMAIN_NAME} ${USERNAME}

        # Send welcome msg to new user.
        [ X"${SEND_WELCOME_MSG}" == X"YES" ] && send_welcome_mail ${MAIL}
    done
fi
