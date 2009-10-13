# -----------------------------
# PostfixAdmin.
# -----------------------------
postfixadmin_install()
{
    cd ${MISC_DIR}

    ECHO_INFO "Extract PostfixAdmin: ${POSTFIXADMIN_TARBALL}..."
    extract_pkg ${POSTFIXADMIN_TARBALL} ${HTTPD_SERVERROOT} && \
    cd ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/ && \
    patch -p0 < ${PATCH_DIR}/postfixadmin/create_mailbox.patch >/dev/null

    ECHO_INFO "Set file permission for PostfixAdmin."
    chown -R root:root ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/
    chmod -R 755 ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/
    mv ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/setup.php ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/setup.php.${DATE}

    ECHO_INFO "Create directory alias for PostfixAdmin in Apache."
    cat > ${HTTPD_CONF_DIR}/postfixadmin.conf <<EOF
${CONF_MSG}
Alias /postfixadmin "${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/"
EOF

    ECHO_INFO "Add site admin in SQL database."
    SITE_ADMIN_PASSWD="$(openssl passwd -1 ${SITE_ADMIN_PASSWD})"

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
/* Add site admin. */
USE ${VMAIL_DB};

INSERT INTO admin (username, password) VALUES("${SITE_ADMIN_NAME}","${SITE_ADMIN_PASSWD}");
INSERT INTO domain_admins (username,domain) VALUES ("${SITE_ADMIN_NAME}","ALL");

FLUSH PRIVILEGES;
EOF

    cd ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/

    # Don't show default motd message.
    echo '' > motd.txt
    echo '' > motd-users.txt

    perl -pi -e 's#(.*configured.*=)(.*)#${1}"true";#' config.inc.php
    perl -pi -e 's#(.*default_language.*=)(.*)#${1}"cn";#' config.inc.php

    perl -pi -e 's#(.*database_host.*)localhost(.*)#${1}127.0.0.1${2}#' config.inc.php
    perl -pi -e 's#(.*database_user.*=)(.*)#${1}"$ENV{'MYSQL_ADMIN_USER'}";#' config.inc.php
    export MYSQL_ADMIN_PW
    perl -pi -e 's#(.*database_password.*=)(.*)#${1}"$ENV{'MYSQL_ADMIN_PW'}";#' config.inc.php
    perl -pi -e 's#(.*database_name.*=)(.*)#${1}"$ENV{'VMAIL_DB'}";#' config.inc.php
    perl -pi -e 's#(.*smtp_server.*)localhost(.*)#${1}127.0.0.1${2}#' config.inc.php

    [ ! -z ${MAIL_ALIAS_ROOT} ] && perl -pi -e 's#(.*admin_email.*=)(.*)#${1}"$ENV{'MAIL_ALIAS_ROOT'}";#' config.inc.php

    perl -pi -e 's#(.*domain_path.*=)(.*)#${1}"YES";#' config.inc.php
    perl -pi -e 's#(.*domain_in_mailbox.*=)(.*)#${1}"NO";#' config.inc.php
    perl -pi -e 's#(.*quota.*=)(.*)(NO)(.*)#${1}"YES";#' config.inc.php
    perl -pi -e 's#(.*quota_multiplier.*)1024000(.*)#${1}1024${2}#' config.inc.php
    perl -pi -e 's#(.*transport.*=)(.*)(NO)(.*)#${1}"YES";#' config.inc.php
    perl -pi -e 's#(.*virtual.*,)#${1}"dovecot",#' config.inc.php
    perl -pi -e 's#(.*transport_default.*=)(.*)#${1}"dovecot";#' config.inc.php

    perl -pi -e 's#(.*backup.*=)(.*)(YES)(.*)#${1}"NO";#' config.inc.php
    perl -pi -e 's#(.*fetchmail.*=)(.*)(YES)(.*)#${1}"NO";#' config.inc.php
    perl -pi -e 's#(.*sendmail.*=)(.*)(YES)(.*)#${1}"NO";#' config.inc.php
    perl -pi -e 's#(.*show_footer_text.*=)(.*)(YES)(.*)#${1}"NO";#' config.inc.php
    perl -pi -e 's#(.*emailcheck_resolve_domain.*=)(.*)(YES)(.*)#${1}"NO";#' config.inc.php

    [ X"${HOME_MAILBOX}" == X"mbox" ] && perl -pi -e 's#(.*maildir.*fDomain.*fUsername.*)(\..*/.*)#${1};#' create-mailbox.php

    cat >> ${TIP_FILE} <<EOF
PostfixAdmin:
    * Configuration files:
        - ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/
        - ${HTTPD_SERVERROOT}/postfixadmin-${POSTFIXADMIN_VERSION}/config.inc.php
    * URL:
        - http://$(hostname)/postfixadmin/
    * See also:
        - ${HTTPD_CONF_DIR}/postfixadmin.conf

EOF

    echo 'export status_postfixadmin_install="DONE"' >> ${STATUS_FILE}
}
