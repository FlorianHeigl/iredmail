# --------------------------------------------------
# ------------------- PostfixAdmin -----------------
# --------------------------------------------------

# Username of PostfixAdmin site admin.
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Username of PostfixAdmin site admin" \
    --inputbox "\
Please specify the username of PostfixAdmin site admin.

EXAMPLE:

    * michaelbibby@gmail.com

" 20 76 2>/tmp/site_admin_name

SITE_ADMIN_NAME="$(cat /tmp/site_admin_name)"
echo "export SITE_ADMIN_NAME='${SITE_ADMIN_NAME}'" >>${CONFIG_FILE}
rm -f /tmp/site_admin_name

# If SITE_ADMIN_NAME not equal FIRST_DOMAIN_ADMIN_NAME, we need to
# set password for PostfixAdmin site admin.
if [ X"${SITE_ADMIN_NAME}" != X"${FIRST_DOMAIN_ADMIN_NAME}" ]; then
    # Prompt to set password.
    while : ; do
        ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Password of PostfixAdmin site admin" \
        --insecure --passwordbox "\
Please specify the password of site admin in PostfixAdmin:

    * ${SITE_ADMIN_NAME}

Warnning:

    * EMPTY password in *NOT* permit.

" 20 76 2>/tmp/site_admin_passwd

        SITE_ADMIN_PASSWD="$(cat /tmp/site_admin_passwd)"
        [ X"${SITE_ADMIN_PASSWD}" != X"" ] && break
    done

    echo "export SITE_ADMIN_PASSWD='${SITE_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
    rm -f /tmp/site_admin_passwd
else
    :
fi
