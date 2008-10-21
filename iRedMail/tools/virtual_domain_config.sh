#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# First domain name.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Your first virtual domain" \
    --inputbox "\
Please specify the name of your first virtual domain.

EXAMPLES:

    * iredmail.org

" 20 76 2>/tmp/first_domain

    FIRST_DOMAIN="$(cat /tmp/first_domain)"

    [ X"${FIRST_DOMAIN}" != X"" ] && break
done

echo "export FIRST_DOMAIN='${FIRST_DOMAIN}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain

#FIRST_DOMAIN_ADMIN_NAME
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Specify administrator' name of your virtual domain" \
    --inputbox "\
Please specify administrator' name of your virtual domain.

EXAMPLE:

    * postmaster

" 20 76 "postmaster" 2>/tmp/first_domain_admin_name

FIRST_DOMAIN_ADMIN_NAME="$(cat /tmp/first_domain_admin_name)"
echo "export FIRST_DOMAIN_ADMIN_NAME='${FIRST_DOMAIN_ADMIN_NAME}'" >>${CONFIG_FILE}
rm -f /tmp/first_domain_admin_name

# FIRST_DOMAIN_ADMIN_PASSWD
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for the administrator of your domain" \
    --insecure --passwordbox "\
Please specify password for the administrator user:

    * ${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}

Warnning:

    * EMPTY password is *NOT* permit.

" 20 76 2>/tmp/first_domain_admin_passwd

    FIRST_DOMAIN_ADMIN_PASSWD="$(cat /tmp/first_domain_admin_passwd)"

    [ X"${FIRST_DOMAIN_ADMIN_PASSWD}" != X"" ] && break
done

echo "export FIRST_DOMAIN_ADMIN_PASSWD='${FIRST_DOMAIN_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain_admin_passwd

#FIRST_USER
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Add a user for your domain" \
        --inputbox "\
Please specify the username of your first domain: ${FIRST_DOMAIN}.

EXAMPLE:

    * www

" 20 76 "www" 2>/tmp/first_user

    FIRST_USER="$(cat /tmp/first_user)"
    [ X"${FIRST_USER}" != X"" ] && break
done

echo "export FIRST_USER='${FIRST_USER}'" >>${CONFIG_FILE}
rm -f /tmp/first_user

# FIRST_USER_PASSWD
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for your first user" \
    --insecure --passwordbox "\
Please specify password for your first user:

    * ${FIRST_USER}@${FIRST_DOMAIN}

Warnning:

    * EMPTY password is *NOT* permit.

" 20 76 2>/tmp/first_user_passwd

    FIRST_USER_PASSWD="$(cat /tmp/first_user_passwd)"
    [ X"${FIRST_USER_PASSWD}" != X"" ] && break
done

echo "export FIRST_USER_PASSWD='${FIRST_USER_PASSWD}'" >>${CONFIG_FILE}
rm -f /tmp/first_user_passwd
