#!/bin/bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------------
# --------------------- MySQL ----------------------
# --------------------------------------------------

. ${CONF_DIR}/mysql

# MySQL root password.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Password for MySQL administrator: root\Zn" \
    --passwordbox "\
Please specify \Zb\Z2password for MySQL administrator: root\Zn

Warning:

    * \Zb\Z1EMPTY password is *NOT* permitted.\Zn
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
        --title "\Zb\Z2Password\Zn for virtual hosts bind user and admin user" \
        --passwordbox "\
Please specify \Zb\Z2password\Zn for virtual hosts database admin user:

    * ${VMAIL_DB} admin user: ${MYSQL_ADMIN_USER}

Warning:

    * \Zb\Z1EMPTY password in *NOT* permitted.\Zn

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
