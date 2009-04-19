#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ------------------- phpLDAPadmin ----------------------
# -------------------------------------------------------
pla_install()
{
    ECHO_INFO "==================== phpLDAPadmin ===================="

    cd ${MISC_DIR}

    extract_pkg ${PLA_TARBALL} ${HTTPD_SERVERROOT}

    # Create symbol link, so that we don't need to modify apache
    # conf.d/phpldapadmin.conf file after upgrade this component.
    ln -s ${PLA_HTTPD_ROOT} ${HTTPD_SERVERROOT}/phpldapadmin 2>/dev/null

    ECHO_INFO "Copy example config file."
    cd ${PLA_HTTPD_ROOT}/config/ && \
    cp -f config.php.example config.php

    ECHO_INFO "Set file permission."
    chown -R root:root ${PLA_HTTPD_ROOT}
    chmod -R 0755 ${PLA_HTTPD_ROOT}

    ECHO_INFO "Create directory alias for phpLDAPadmin."
    cat > ${HTTPD_CONF_DIR}/phpldapadmin.conf <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
#Alias /phpldapadmin "${HTTPD_SERVERROOT}/phpldapadmin/"
#Alias /ldap "${HTTPD_SERVERROOT}/phpldapadmin/"
<Directory "${HTTPD_SERVERROOT}/phpldapadmin/">
    Options -Indexes
</Directory>
EOF

    # Make phpldapadmin can be accessed via HTTPS only.
    sed -i 's#\(</VirtualHost>\)#Alias /phpldapadmin '${HTTPD_SERVERROOT}/phpldapadmin/'\nAlias /ldap '${HTTPD_SERVERROOT}/phpldapadmin/'\n\1#' ${HTTPD_SSL_CONF}

    cat >> ${TIP_FILE} <<EOF
phpLDAPadmin:
    * Configuration files:
        - ${PLA_HTTPD_ROOT}/config/config.php
    * URL:
        - ${PLA_HTTPD_ROOT}
        - https://${HOSTNAME}/phpldapadmin/
        - https://${HOSTNAME}/ldap/
    * Login account:
        * Username: ${LDAP_ADMIN_DN}
        * Password: ${LDAP_ADMIN_PW}
    * See also:
        - ${HTTPD_CONF_DIR}/phpldapadmin.conf

EOF

    echo 'export status_pla_install="DONE"' >> ${STATUS_FILE}
}
