#!/bin/sh

# Author: Bibby(michaelbibby#gmail.com)

# File: create_mail_ldap_user.sh
# Date: 2008.02.28
# Purpose: Add new LDAP user for postfix mail server.

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

# ------------------ LDAP Setting ---------------
# BASE_DN, DOMAIN_DN:
# The full DN will be:
#
#     uid=${USERNAME}, ${DOMAIN_DN}, ${BASE_DN}
#
# such as:
#
# mail=a@b.com, o=b.com, o=domains,dc=bibby,dc=org
#      _______    _____    _______________________
#        /|\        /|\                  /|\
#         |          |                    |
#      USERNAME   DOMAIN_NAME          BASE_DN
#

LDAP_SUFFIX="dc=iredmail,dc=org"

# Setting 'BASE_DN'.
BASE_DN="o=domains,${LDAP_SUFFIX}"

# Setting 'DOMAIN_NAME' and DOMAIN_DN':
#     * DOMAIN will be used in mail address: ${USERNAME}@${DOMAIN}
#    * DOMAIN_DN will be used in LDAP dn.
DOMAIN_NAME="$1"
DOMAIN_DN="domainName=${DOMAIN_NAME}"

# ---------- rootdn of LDAP Server ----------
# Setting rootdn of LDAP.
ROOTDN="cn=Manager,${LDAP_SUFFIX}"

# Setting rootpw of LDAP.
ROOTPW="passwd"
 
# ---------- LDAP User Setting --------------
# Set default quota for LDAP users: 10485760 = 10M
QUOTA='10485760'

# Transport.
TRANSPORT='dovecot'

# ---------- Welcome Mail info -------------
# Set welcome mail info.
WELCOME_MSG_TITLE="Welcome!"
WELCOME_MSG_BODY="Welcome, new user."

# -------------------------------------------
# ----------- End Global Setting ------------
# -------------------------------------------

add_new_domain()
{
    ldapsearch -x -D "${ROOTDN}" -w "${ROOTPW}" \
    -b "${BASE_DN}" | \
    grep "o: ${DOMAIN_NAME}" >/dev/null

    if [ X"$?" != X"0" ]; then
        echo "Add new domain: ${DOMAIN_NAME}."

        ldapadd -x -D "${ROOTDN}" -w "${ROOTPW}" <<EOF
dn: domainName=${DOMAIN_NAME}, ${BASE_DN}
objectClass: mailDomain
domainName: ${DOMAIN_NAME}
mtaTransport: ${TRANSPORT}
domainStatus: active
EOF
    fi
}

add_new_user()
{
    USERNAME="$1"
    MAIL="$2"

    # Create template LDIF file for this new user and add it.
    # If you do *NOT* want to keep rootpw in script, use '-W' instead of 
    # '-w "${ROOTPW}".

    # For maildir format.
    if [ X"${MAILDIR_IN_MAILBOX}" == X"YES" ]; then
        [ X"${HOME_MAILBOX}" == X"Maildir" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}/${MAILDIR_STRING}/"
    else
        [ X"${HOME_MAILBOX}" == X"Maildir" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}/"
    fi
    [ X"${HOME_MAILBOX}" == X"mbox" ] && mailMessageStore="${DOMAIN_NAME}/${USERNAME}"

    ldapadd -x -D "${ROOTDN}" -w "${ROOTPW}" <<EOF
dn: mail=${MAIL}, ${DOMAIN_DN}, ${BASE_DN}
objectClass: inetOrgPerson
objectClass: mailUser
objectClass: top
homeDirectory: ${VMAIL_USER_HOME_DIR}
accountStatus: active
mailMessageStore: ${mailMessageStore}
mail: ${MAIL}
mailQuota: ${QUOTA}
userPassword: $(slappasswd -h {MD5} -s ${USERNAME})
cn: ${USERNAME}
sn: ${USERNAME}
uid: ${USERNAME}
enablePOP3: yes
enableIMAP: yes
enableSMTP: yes
enableDELIVER: yes
EOF
}

# *********
# WARNNING
# *********
# We do *NOT* need this function, because dovecot will create user
# mailbox automatic.
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
    DOMAIN_NAME="$1"
    shift 1

    add_new_domain ${DOMAIN_NAME}
    for i in $@
    do
        USERNAME="$i"
        MAIL="${USERNAME}@${DOMAIN_NAME}"

        add_new_user ${USERNAME} ${MAIL}
        # Dovecot will create user maildir automatic when user logins via
        # POP3 or IMAP.
        #create_maildir ${DOMAIN_NAME} ${USERNAME}
        #send_welcome_mail ${MAIL}
    done
fi
