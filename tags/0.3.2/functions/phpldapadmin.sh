#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ------------------- phpLDAPadmin ----------------------
# -------------------------------------------------------
pla_install()
{
    cd ${MISC_DIR}

    extract_pkg ${PLA_TARBALL} ${HTTPD_SERVERROOT}

    chown -R root:root ${PLA_HTTPD_ROOT}
    chmod -R 0755 ${PLA_HTTPD_ROOT}

    ECHO_INFO "Create directory alias for phpLDAPadmin."
    cat > ${HTTPD_CONF_DIR}/phpldapadmin.conf <<EOF
${CONF_MSG}
Alias /phpldapadmin "/var/www/phpldapadmin-${PLA_VERSION}/"
Alias /ldap "/var/www/phpldapadmin-${PLA_VERSION}/"
EOF

    ECHO_INFO "Copy example config file."
    cd ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/config/
    cd ${PLA_HTTPD_ROOT}/config/
    cp config.php.example config.php

    ECHO_INFO "Add phpLDAPadmin templates for create virtual domains/users."
    cp -f ${SAMPLE_DIR}/phpldapadmin.templates/*xml \
        ${PLA_HTTPD_ROOT}/templates/creation/

    cat >> ${TIP_FILE} <<EOF
phpLDAPadmin:
    * Configuration files:
        - ${PLA_HTTPD_ROOT}/config/config.php
    * URL:
        - ${PLA_HTTPD_ROOT}
        - http://${HOSTNAME}/phpldapadmin/
        - http://${HOSTNAME}/ldap/
    * See also:
        - ${HTTPD_CONF_DIR}/phpldapadmin.conf
        - ${PLA_HTTPD_ROOT}/templates/creation/custom_*.xml
    * Note:
          You should click 'Purge Cache' link to enable these templates while
          you login into phpldapadmin."

EOF

    echo 'export status_pla_install="DONE"' >> ${STATUS_FILE}
}
