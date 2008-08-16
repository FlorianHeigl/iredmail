# -------------------------------------------------------
# ------------------- phpLDAPadmin ----------------------
# -------------------------------------------------------
pla_install()
{
    cd ${MISC_DIR}

    extract_pkg ${PLA_TARBALL} ${HTTPD_SERVERROOT}

    ECHO_INFO "Create directory alias for phpLDAPadmin."
    cat > ${HTTPD_CONF_DIR}/phpldapadmin.conf <<EOF
${CONF_MSG}
Alias /phpldapadmin "/var/www/phpldapadmin-${PLA_VERSION}/"
Alias /ldap "/var/www/phpldapadmin-${PLA_VERSION}/"
EOF

    ECHO_INFO "Copy example config file."
    cd ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/config/
    cp config.php.example config.php

    ECHO_INFO "Add phpLDAPadmin templates for create virtual domains/users."
    cp -f ${SAMPLE_DIR}/phpldapadmin.templates/*xml \
        ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/templates/creation/

    cat >> ${TIP_FILE} <<EOF
phpLDAPadmin:
    * Configuration files:
        - ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/config/config.php
    * URL:
        - ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/
        - http://$(hostname)/phpldapadmin/
        - http://$(hostname)/ldap/
    * See also:
        - ${HTTPD_CONF_DIR}/phpldapadmin.conf
        - ${HTTPD_SERVERROOT}/phpldapadmin-${PLA_VERSION}/templates/creation/custom_*.xml
    * Note:
          You should click 'Purge Cache' link to enable these templates while
          you login into phpldapadmin."

EOF

    echo 'export status_pla_install="DONE"' >> ${STATUS_FILE}
}
