#!/usr/bin/env bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

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

# First domain name.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Your first virtual \Zb\Z2domain name\Zn" \
    --inputbox "\
Please specify your first virtual \Zb\Z2domain name\Zn.

EXAMPLES:

    * iredmail.org

" 20 76 2>/tmp/first_domain

    FIRST_DOMAIN="$(cat /tmp/first_domain)"

    [ X"${FIRST_DOMAIN}" != X"" ] && break
done

echo "export FIRST_DOMAIN='${FIRST_DOMAIN}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain

#DOMAIN_ADMIN_NAME
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Specify \Zb\Z2administrator' name\Zn of your virtual domain" \
    --inputbox "\
Please specify \Zb\Z2administrator' name\Zn of your virtual domain.

EXAMPLE:

    * postmaster

Warning:

    * \Zb\Z1This account is used only for system administration.\Zn
    * \Zb\Z1It's *NOT* a normal mail user.\Zn
" 20 76 "postmaster" 2>/tmp/first_domain_admin_name

DOMAIN_ADMIN_NAME="$(cat /tmp/first_domain_admin_name)"
echo "export DOMAIN_ADMIN_NAME='${DOMAIN_ADMIN_NAME}'" >>${CONFIG_FILE}
rm -f /tmp/first_domain_admin_name

# DOMAIN_ADMIN_PASSWD
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Password\Zn for the administrator of your domain" \
    --passwordbox "\
Please specify \Zb\Z2password\Zn for the administrator user:

    * ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}

Warning:

    * \Zb\Z1EMPTY password is *NOT* permitted.\Zn

" 20 76 2>/tmp/first_domain_admin_passwd

    DOMAIN_ADMIN_PASSWD="$(cat /tmp/first_domain_admin_passwd)"

    [ X"${DOMAIN_ADMIN_PASSWD}" != X"" ] && break
done

export DOMAIN_ADMIN_PASSWD_PLAIN="${DOMAIN_ADMIN_PASSWD}"
echo "export DOMAIN_ADMIN_PASSWD_PLAIN='${DOMAIN_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
echo "export DOMAIN_ADMIN_PASSWD='${DOMAIN_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain_admin_passwd

#FIRST_USER
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Add a user for your domain" \
        --inputbox "\
Please specify \Zb\Z2username\Zn of your first user for domain: ${FIRST_DOMAIN}.

EXAMPLE:

    * www

Note:

    * \Zb\Z1This account is a normal mail user.\Zn
" 20 76 "www" 2>/tmp/first_user

    FIRST_USER="$(cat /tmp/first_user)"
    [ X"${FIRST_USER}" != X"" ] && break
done

echo "export FIRST_USER='${FIRST_USER}'" >>${CONFIG_FILE}
rm -f /tmp/first_user

# FIRST_USER_PASSWD
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Password\Zn for your first user" \
    --passwordbox "\
Please specify \Zb\Z2password\Zn for your first user:

    * ${FIRST_USER}@${FIRST_DOMAIN}

Warning:

    * \Zb\Z1EMPTY password is *NOT* permitted.\Zn

" 20 76 2>/tmp/first_user_passwd

    FIRST_USER_PASSWD="$(cat /tmp/first_user_passwd)"
    [ X"${FIRST_USER_PASSWD}" != X"" ] && break
done

export FIRST_USER_PASSWD_PLAIN="${FIRST_USER_PASSWD}"
echo "export FIRST_USER_PASSWD='${FIRST_USER_PASSWD}'" >>${CONFIG_FILE}
rm -f /tmp/first_user_passwd

cat >> ${TIP_FILE} <<EOF
Admin of domain ${FIRST_DOMAIN}:
    * Account: ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}
    * Password: ${DOMAIN_ADMIN_PASSWD_PLAIN}

    Note:
        - This account is used only for system administrations, not a mail user.
        - Account name is full email address.

First mail user:
    * Account: ${FIRST_USER}@${FIRST_DOMAIN}
    * Password: ${FIRST_USER_PASSWD}

    Note:
        - This account is a normal mail user.
        - Account name is full email address.

EOF
