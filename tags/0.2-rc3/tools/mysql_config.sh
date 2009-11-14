# --------------------------------------------------
# --------------------- MySQL ----------------------
# --------------------------------------------------

. ${CONF_DIR}/mysql

# MySQL root password.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for MySQL administrator: root" \
    --insecure --passwordbox "\
Please specify password for MySQL administrator: root

Warnning:

    * EMPTY password is *NOT* permit.
" 20 76 2>/tmp/mysql_rootpw

    MYSQL_ROOT_PASSWD="$(cat /tmp/mysql_rootpw)"
    [ X"${MYSQL_ROOT_PASSWD}" != X"" ] && break
done

echo "export MYSQL_ROOT_PASSWD='${MYSQL_ROOT_PASSWD}'" >>${CONFIG_FILE}
rm -f /tmp/mysql_rootpw

# MySQL bind/admin user passwd.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for virtual hosts bind user and admin user" \
    --insecure --passwordbox "\
Please specify password for virtual hosts database admin user:

    * ${VMAIL_DB} admin user: ${MYSQL_ADMIN_USER}

Warnning:

    * EMPTY password in *NOT* permit.

" 20 76 2>/tmp/mysql_user_and_passwd

    MYSQL_ADMIN_PW="$(cat /tmp/mysql_user_and_passwd)"

    [ X"${MYSQL_ADMIN_PW}" != X"" ] && break
done

echo "export MYSQL_ADMIN_USER='${MYSQL_ADMIN_USER}'" >> ${CONFIG_FILE}
echo "export MYSQL_ADMIN_PW='${MYSQL_ADMIN_PW}'" >> ${CONFIG_FILE}
rm -f /tmp/mysql_user_and_passwd
