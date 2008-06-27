# -------------------------------------------------------
# ---------------- User/Group: vmail --------------------
# -------------------------------------------------------
adduser_vmail()
{
    homedir="$(dirname $(echo ${VMAIL_USER_HOME_DIR} | sed 's#/$##'))"
    [ -d ${homedir} ] || mkdir -p ${homedir}

    ECHO_INFO "Add user/group: vmail."
    groupadd -g ${VMAIL_USER_GID} ${VMAIL_GROUP_NAME}
    useradd -m -d ${VMAIL_USER_HOME_DIR} -s /sbin/nologin -u ${VMAIL_USER_UID} -g ${VMAIL_USER_GID} ${VMAIL_USER_NAME}
    rm -f ${VMAIL_USER_HOME_DIR}/.* 2>/dev/null

    cat >> ${TIP_FILE} <<EOF
Mail Storage:
    - Path:
        ${VMAIL_USER_HOME_DIR}
    - Format:
        ${VMAIL_USER_HOME_DIR}/DomainName/UserName/
    - Example:
        ${VMAIL_USER_HOME_DIR}/${FIRST_DOMAIN}/${FIRST_USER}/

EOF

    echo 'export status_adduser_vmail="DONE"' >> ${STATUS_FILE}
}
