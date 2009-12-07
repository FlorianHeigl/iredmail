#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

# -------------------------------------------------------
# ---------------- Apache & PHP -------------------------
# -------------------------------------------------------

apache_php_config()
{
    ECHO_INFO "==================== Apache & PHP ===================="

    backup_file ${HTTPD_CONF} ${HTTPD_SSL_CONF}

    # FreeBSD: Copy sample file.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        sample="$( ${LIST_FILES_IN_PKG} 'apache*' | grep '/httpd-ssl.conf$' )"
        cp ${sample} ${HTTPD_SSL_CONF}
        unset sample
    fi

    # Ubuntu (hardy): Generate a sample default-ssl site config file.
    if [ X"${DISTRO_CODENAME}" == X"hardy" ]; then
        cat > ${HTTPD_SSL_CONF} <<EOF
NameVirtualHost *:443
<VirtualHost *:443>
    ServerAdmin ${FIRST_USER}@${FIRST_DOMAIN}
    DocumentRoot ${HTTPD_DOCUMENTROOT}

    # Enable SSL.
    SSLEngine On
    SSLCertificateFile ${SSL_CERT_FILE}
    SSLCertificateKeyFile ${SSL_KEY_FILE}
</VirtualHost>
EOF

    else
        :
    fi

    # --------------------------
    # Apache Setting.
    # --------------------------
    ECHO_INFO "Hide apache version number in ${HTTPD_CONF}."
    perl -pi -e 's#^(ServerTokens).*#${1} ProductOnly#' ${HTTPD_CONF}
    perl -pi -e 's#^(ServerSignature).*#${1} EMail#' ${HTTPD_CONF}

    #ECHO_INFO "Disable 'AddDefaultCharset' in ${HTTPD_CONF}."
    #perl -pi -e 's/^(AddDefaultCharset UTF-8)/#${1}/' ${HTTPD_CONF}

    # Set correct SSL Cert/Key file location.
    if [ X"${DISTRO}" == X"RHEL" -o X"${DISTRO}" == X"FREEBSD" ]; then
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

        # Enable mod_deflate to compress web content.
        a2enmod deflate >/dev/null 2>&1
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

    # FreeBSD: Copy a sample file.
    [ X"${DISTRO}" == X"FREEBSD" ] && cp -f /usr/local/etc/php.ini-recommended ${PHP_INI}

    #ECHO_INFO "Setting error_reporting to 'E_ERROR': ${PHP_INI}."
    #perl -pi -e 's#^(error_reporting.*=)#${1} E_ERROR;#' ${PHP_INI}

    ECHO_INFO "Disable several functions: ${PHP_INI}."
    perl -pi -e 's#^(disable_functions.*=)(.*)#${1}show_source,system,shell_exec,passthru,exec,phpinfo,proc_open ; ${2}#' ${PHP_INI}

    ECHO_INFO "Hide PHP Version in Apache from remote users requests: ${PHP_INI}."
    perl -pi -e 's#^(expose_php.*=)#${1} Off;#' ${PHP_INI}

    ECHO_INFO "Increase 'memory_limit' to 128M: ${PHP_INI}."
    perl -pi -e 's#^(memory_limit = )#${1} 128M;#' ${PHP_INI}

    ECHO_INFO "Increase 'upload_max_filesize', 'post_max_size' to 10/12M: ${PHP_INI}."
    perl -pi -e 's/^(upload_max_filesize.*=)/${1}10M; #/' ${PHP_INI}
    perl -pi -e 's/^(post_max_size.*=)/${1}12M; #/' ${PHP_INI}

    # FreeBSD: Start apache when system start up.
    [ X"${DISTRO}" == X"FREEBSD" ] && cat >> /etc/rc.conf <<EOF
# Start apache web server.
apache22_enable="YES"
htcacheclean_enable="YES"
EOF

    cat >> ${TIP_FILE} <<EOF
Apache & PHP:
    * Configuration files:
        - ${HTTPD_CONF_ROOT}
        - ${HTTPD_CONF_DIR}
        - ${PHP_INI}
    * Directories:
        - ${HTTPD_SERVERROOT}
        - ${HTTPD_DOCUMENTROOT}

EOF

    echo 'export status_apache_php_config="DONE"' >> ${STATUS_FILE}
}
