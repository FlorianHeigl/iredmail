#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -----------------------------
# PostfixAdmin.
# -----------------------------
postfixadmin_install()
{
    ECHO_INFO "==================== PostfixAdmin ===================="

    cd ${MISC_DIR}

    extract_pkg ${POSTFIXADMIN_TARBALL} ${HTTPD_SERVERROOT}

    # Create symbol link, so that we don't need to modify apache
    # conf.d/postfixadmin.conf file after upgrade this component.
    ln -s ${POSTFIXADMIN_HTTPD_ROOT} ${HTTPD_SERVERROOT}/postfixadmin

    cd ${POSTFIXADMIN_HTTPD_ROOT}/ && \
    patch -p0 < ${PATCH_DIR}/postfixadmin/create_mailbox.patch >/dev/null && \
    patch -p0 < ${PATCH_DIR}/postfixadmin/login-security-issue.patch >/dev/null

    ECHO_INFO "Set file permission for PostfixAdmin."
    chown -R ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${POSTFIXADMIN_HTTPD_ROOT}
    chmod -R 755 ${POSTFIXADMIN_HTTPD_ROOT}
    mv ${POSTFIXADMIN_HTTPD_ROOT}/setup.php ${POSTFIXADMIN_HTTPD_ROOT}/setup.php.${DATE}
    chmod 0000 ${POSTFIXADMIN_HTTPD_ROOT}/setup.php.${DATE}

    ECHO_INFO "Create directory alias for PostfixAdmin in Apache."
    cat > ${HTTPD_CONF_DIR}/postfixadmin.conf <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
#Alias /postfixadmin "${HTTPD_SERVERROOT}/postfixadmin/"
<Directory "${POSTFIXADMIN_HTTPD_ROOT}/">
    Options -Indexes
</Directory>
EOF

    # Make PostfixAdmin can be accessed via HTTPS only.
    sed -i 's#\(</VirtualHost>\)#Alias /postfixadmin '${HTTPD_SERVERROOT}/postfixadmin/'\n\1#' ${HTTPD_SSL_CONF}

    if [ X"${SITE_ADMIN_NAME}" == X"${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}" ]; then
        # We need update domain list, not insert a new record.
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
USE ${VMAIL_DB};

/* Update domain list. */
UPDATE domain_admins SET domain='ALL' WHERE username="${SITE_ADMIN_NAME}";

FLUSH PRIVILEGES;
EOF
    else
        ECHO_INFO "Add site admin in SQL database."
        SITE_ADMIN_PASSWD="$(openssl passwd -1 ${SITE_ADMIN_PASSWD})"
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
USE ${VMAIL_DB};

/* Add whole site admin. */
INSERT INTO admin (username, password) VALUES("${SITE_ADMIN_NAME}","${SITE_ADMIN_PASSWD}");
INSERT INTO domain_admins (username,domain) VALUES ("${SITE_ADMIN_NAME}","ALL");

FLUSH PRIVILEGES;
EOF
    fi


    cd ${POSTFIXADMIN_HTTPD_ROOT}

    # Don't show default motd message.
    echo '' > motd.txt
    echo '' > motd-users.txt

    cat > ${POSTFIXADMIN_CONF_LOCAL} <<EOF
<?php
\$CONF['configured'] = true;
\$CONF['default_language'] = "${POSTFIXADMIN_DEFAULT_LANGUAGE}";
\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = "${MYSQL_SERVER}";
\$CONF['database_user'] = "${MYSQL_ADMIN_USER}";
\$CONF['database_password'] = "${MYSQL_ADMIN_PW}";
\$CONF['database_name'] = "${VMAIL_DB}";
\$CONF['smtp_server'] = "${SMTP_SERVER}";

\$CONF['domain_path'] = "YES";
\$CONF['domain_in_mailbox'] = "NO";
\$CONF['quota'] = "YES";
\$CONF['quota_multiplier'] = 1;
\$CONF['transport'] = "YES";
\$CONF['transport_options'] = array ('dovecot', 'virtual', 'local', 'relay');
\$CONF['transport_default'] = "dovecot";

\$CONF['backup'] = "NO";
\$CONF['fetchmail'] = "NO";
\$CONF['sendmail'] = "NO";
\$CONF['show_footer_text'] = "NO";
\$CONF['emailcheck_resolve_domain'] = "NO";

# Disable vacation.
\$CONF['vacation_control'] = "NO";
\$CONF['vacation_control_admin'] = "NO";
EOF

    [ ! -z ${MAIL_ALIAS_ROOT} ] && \
        echo "\$CONF['admin_email'] = \"${MAIL_ALIAS_ROOT}\";" >> ${POSTFIXADMIN_CONF_LOCAL}

    echo '?>' >> ${POSTFIXADMIN_CONF_LOCAL}

    [ X"${HOME_MAILBOX}" == X"mbox" ] && \
        perl -pi -e 's#(.*maildir.*fDomain.*fUsername.*)(\..*/.*)#${1};#' ${POSTFIXADMIN_HTTPD_ROOT}/create-mailbox.php

    cat >> ${TIP_FILE} <<EOF
PostfixAdmin:
    * Configuration files:
        - ${POSTFIXADMIN_HTTPD_ROOT}
        - ${POSTFIXADMIN_CONF_LOCAL}
        - ${POSTFIXADMIN_HTTPD_ROOT}/config.inc.php
    * Login account:
        - Username: ${SITE_ADMIN_NAME}, password: ${SITE_ADMIN_PASSWD}
    * URL:
        - https://${HOSTNAME}/postfixadmin/
    * See also:
        - ${HTTPD_CONF_DIR}/postfixadmin.conf

EOF

    echo 'export status_postfixadmin_install="DONE"' >> ${STATUS_FILE}
}
