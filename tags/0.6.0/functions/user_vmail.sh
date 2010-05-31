#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ---------------- User/Group: vmail --------------------
# -------------------------------------------------------
adduser_vmail()
{
    ECHO_INFO "==================== User/Group: vmail ===================="

    homedir="$(dirname $(echo ${VMAIL_USER_HOME_DIR} | sed 's#/$##'))"
    [ -L ${homedir} ] && rm -f ${homedir}
    [ -d ${homedir} ] || mkdir -p ${homedir}
    [ -d ${STORAGE_BASE_DIR}/${STORAGE_NODE} ] || mkdir -p ${STORAGE_BASE_DIR}/${STORAGE_NODE}

    ECHO_INFO "Add user/group: vmail."

    # It will create a group with the same name as vmail user name.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        pw useradd -n ${VMAIL_USER_NAME} -s /sbin/nologin -d ${VMAIL_USER_HOME_DIR} -m 2>/dev/null
    else
        useradd -m -d ${VMAIL_USER_HOME_DIR} -s /sbin/nologin ${VMAIL_USER_NAME} 2>/dev/null
    fi
    rm -f ${VMAIL_USER_HOME_DIR}/.* 2>/dev/null

    # Export vmail user uid/gid.
    export VMAIL_USER_UID="$(id -u ${VMAIL_USER_NAME})"
    export VMAIL_USER_GID="$(id -g ${VMAIL_USER_NAME})"

    # Set permission for exist home directory.
    if [ -d ${VMAIL_USER_HOME_DIR} ]; then
        chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${VMAIL_USER_HOME_DIR}
        chmod -R 0700 ${VMAIL_USER_HOME_DIR}
    else
        :
    fi

    ECHO_INFO "Create directory to store user sieve rule files: ${SIEVE_DIR}."
    mkdir -p ${SIEVE_DIR} && \
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${SIEVE_DIR} && \
    chmod -R 0700 ${SIEVE_DIR}

    cat >> ${TIP_FILE} <<EOF
Mail Storage:
    - Path:
        + ${VMAIL_USER_HOME_DIR}
        + ${STORAGE_BASE_DIR}/${STORAGE_NODE}

EOF

    echo 'export status_adduser_vmail="DONE"' >> ${STATUS_FILE}
}
