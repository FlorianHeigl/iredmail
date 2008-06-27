# -------------------------------------------------
# phpMyAdmin.
# -------------------------------------------------
phpmyadmin_install()
{
    cd ${MISC_DIR}

    extract_pkg ${PHPMYADMIN_TARBALL} ${HTTPD_SERVERROOT}

    ECHO_INFO "Create directory alias for phpMyAdmin in Apache: ${HTTPD_CONF_DIR}/phpmyadmin.conf."
    cat > ${HTTPD_CONF_DIR}/phpmyadmin.conf <<EOF
${CONF_MSG}
Alias /phpmyadmin "${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/"
EOF

    ECHO_INFO "Set file permission for phpMyAdmin: ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}."
    chown root:root ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}
    chown -R apache:apache ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/*

    ECHO_INFO "Config phpMyAdmin: ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/config.inc.php."
    cd ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/
    cp config.sample.inc.php config.inc.php

    export COOKIE_STRING="$(openssl passwd -1 ${PROG_NAME_LOWERCASE})"
    perl -pi -e 's#(.*blowfish_secret.*= )(.*)#${1}"$ENV{'COOKIE_STRING'}"; //${2}#' config.inc.php
    perl -pi -e 's#(.*Servers.*host.*=.*)localhost(.*)#${1}127.0.0.1${2}#' config.inc.php

    cat >> ${TIP_FILE} <<EOF
phpMyAdmin:
    * Configuration files:
        - ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/
        - ${HTTPD_SERVERROOT}/phpMyAdmin-${PHPMYADMIN_VERSION}/config.inc.php
    * URL:
        - http://$(hostname)/phpmyadmin
    * See also:
        - ${HTTPD_CONF_DIR}/phpmyadmin.conf

EOF

    echo 'export status_phpmyadmin_install="DONE"' >> ${STATUS_FILE}
}
