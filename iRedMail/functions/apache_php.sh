#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ---------------- Apache & PHP -------------------------
# -------------------------------------------------------

apache_php_config()
{
    ECHO_INFO "==================== Apache & PHP ===================="

    # Copy a sample default-ssl site config file.
    if [ X"${DISTRO}" == X"UBUNTU" -a X"${DISTRO_CODENAME}" == X"hardy" ]; then
        sample="$( eval ${LIST_FILES_IN_PKG} apache2-common | grep 'httpd-ssl.conf.gz' )"
        [ ! -z ${sample} ] && gunzip -c ${sample} > ${HTTPD_SSL_CONF}

        # Set document root.
        perl -pi -e 's#^(DocumentRoot).*#${1} "$ENV{HTTPD_DOCUMENTROOT}"#' ${HTTPD_SSL_CONF}
    else
        :
    fi

    backup_file ${HTTPD_CONF} ${HTTPD_SSL_CONF}

    # --------------------------
    # Apache Setting.
    # --------------------------
    ECHO_INFO "Hide apache version number in ${HTTPD_CONF}."
    perl -pi -e 's#^(ServerTokens).*#${1} ProductOnly#' ${HTTPD_CONF}
    perl -pi -e 's#^(ServerSignature).*#${1} EMail#' ${HTTPD_CONF}

    ECHO_INFO "Disable 'AddDefaultCharset' in ${HTTPD_CONF}."
    perl -pi -e 's/^(AddDefaultCharset UTF-8)/#${1}/' ${HTTPD_CONF}

    # SSL Cert/Key file.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        perl -pi -e 's#^(SSLCertificateFile)(.*)#${1} $ENV{SSL_CERT_FILE}#' ${HTTPD_SSL_CONF}
        perl -pi -e 's#^(SSLCertificateKeyFile)(.*)#${1} $ENV{SSL_KEY_FILE}#' ${HTTPD_SSL_CONF}
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        perl -pi -e 's#^([ \t]+SSLCertificateFile)(.*)#${1} $ENV{SSL_CERT_FILE}#' ${HTTPD_SSL_CONF}
        perl -pi -e 's#^([ \t]+SSLCertificateKeyFile)(.*)#${1} $ENV{SSL_KEY_FILE}#' ${HTTPD_SSL_CONF}
    else
        :
    fi

    # Enable ssl, ldap, mysql module on Debian/Ubuntu.
    if [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        a2ensite $(basename ${HTTPD_SSL_CONF}) >/dev/null
        a2enmod ssl >/dev/null
        [ X"${BACKEND}" == X"OpenLDAP" ] && a2enmod authnz_ldap > /dev/null
        [ X"${BACKEND}" == X"MySQL" ] && a2enmod auth_mysql > /dev/null
    else
        :
    fi

    if [ X"${HTTPD_PORT}" != X"80" ]; then
        ECHO_INFO "Change Apache listen port to: ${HTTPD_PORT}."
        perl -pi -e 's#^(Listen )(80)$#${1}$ENV{HTTPD_PORT}#' ${HTTPD_CONF}
    else
        :
    fi

    # Add robots.txt.
    backup_file ${HTTPD_DOCUMENTROOT}/robots.txt
    cat >> ${HTTPD_DOCUMENTROOT}/robots.txt <<EOF
User-agent: *
Disallow: /mail
Disallow: /webmail
Disallow: /roundcube
Disallow: /phpldapadmin
Disallow: /ldap
Disallow: /mysql
Disallow: /phpmyadmin
Disallow: /awstats
Disallow: /postfixadmin
EOF

    # --------------------------
    # PHP Setting.
    # --------------------------
    backup_file ${PHP_INI}

    #ECHO_INFO "Setting error_reporting to 'E_ERROR': ${PHP_INI}."
    #perl -pi -e 's#^(error_reporting.*=)#${1} E_ERROR;#' ${PHP_INI}

    ECHO_INFO "Disable several functions: ${PHP_INI}."
    perl -pi -e 's#^(disable_functions.*=)(.*)#${1}show_source,system,shell_exec,passthru,exec,phpinfo,popen,proc_open ; ${2}#' ${PHP_INI}

    ECHO_INFO "Hide PHP Version in Apache from remote users requests: ${PHP_INI}."
    perl -pi -e 's#^(expose_php.*=)#${1} Off;#' ${PHP_INI}

    ECHO_INFO "Increase 'memory_limit' to 128M: ${PHP_INI}."
    perl -pi -e 's#^(memory_limit = )#${1} 128M;#' ${PHP_INI}

    ECHO_INFO "Increase 'upload_max_filesize', 'post_max_size' to 10/12M: ${PHP_INI}."
    perl -pi -e 's/^(upload_max_filesize.*=)/${1}10M; #/' ${PHP_INI}
    perl -pi -e 's/^(post_max_size.*=)/${1}12M; #/' ${PHP_INI}

    cat >> ${TIP_FILE} <<EOF
Apache & PHP:
    * Configuration files:
        - /etc/httpd/conf/
        - /etc/httpd/conf.d/
        - /etc/php.ini
    * Directories:
        - ${HTTPD_SERVERROOT}
        - ${HTTPD_DOCUMENTROOT}

EOF

    echo 'export status_apache_php_config="DONE"' >> ${STATUS_FILE}
}
