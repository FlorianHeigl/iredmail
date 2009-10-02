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

# --------------------------------------------------
# --------------------- MySQL ----------------------
# --------------------------------------------------

. ${CONF_DIR}/mysql

# MySQL root password.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for MySQL administrator: root" \
    --passwordbox "\
Please specify password for MySQL administrator: root

Warning:

    * EMPTY password is *NOT* permitted.
" 20 76 2>/tmp/mysql_rootpw

    MYSQL_ROOT_PASSWD="$(cat /tmp/mysql_rootpw)"
    [ X"${MYSQL_ROOT_PASSWD}" != X"" ] && break
done

echo "export MYSQL_ROOT_PASSWD='${MYSQL_ROOT_PASSWD}'" >>${CONFIG_FILE}
rm -f /tmp/mysql_rootpw

if [ X"${BACKEND}" == X"MySQL" ]; then
    # MySQL bind/admin user passwd.
    while : ; do
        ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Password for virtual hosts bind user and admin user" \
        --passwordbox "\
Please specify password for virtual hosts database admin user:

    * ${VMAIL_DB} admin user: ${MYSQL_ADMIN_USER}

Warning:

    * EMPTY password in *NOT* permitted.

" 20 76 2>/tmp/mysql_user_and_passwd

        MYSQL_ADMIN_PW="$(cat /tmp/mysql_user_and_passwd)"

        [ X"${MYSQL_ADMIN_PW}" != X"" ] && break
    done

    echo "export MYSQL_ADMIN_USER='${MYSQL_ADMIN_USER}'" >> ${CONFIG_FILE}
    echo "export MYSQL_ADMIN_PW='${MYSQL_ADMIN_PW}'" >> ${CONFIG_FILE}
    rm -f /tmp/mysql_user_and_passwd
else
    :
fi
