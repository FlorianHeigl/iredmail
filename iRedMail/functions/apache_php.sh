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
    ECHO_INFO "Configure Apache web server and PHP."

    backup_file ${HTTPD_CONF} ${HTTPD_SSL_CONF}

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
    ECHO_DEBUG "Hide apache version number in ${HTTPD_CONF}."
    perl -pi -e 's#^(ServerTokens).*#${1} ProductOnly#' ${HTTPD_CONF}
    perl -pi -e 's#^(ServerSignature).*#${1} EMail#' ${HTTPD_CONF}

    #ECHO_DEBUG "Disable 'AddDefaultCharset' in ${HTTPD_CONF}."
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
        ECHO_DEBUG "Change Apache listen port to: ${HTTPD_PORT}."
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
Disallow: /iredadmin
EOF

    # --------------------------
    # PHP Setting.
    # --------------------------
    backup_file ${PHP_INI}

    # FreeBSD.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        # Copy sample file.
        cp -f /usr/local/etc/php.ini-production ${PHP_INI}

        # Set date.timezone. required by PHP-5.3.
        perl -pi -e 's#^;(date.timezone).*#${1} = UTC#' ${PHP_INI}
    fi

    #ECHO_DEBUG "Setting error_reporting to 'E_ERROR': ${PHP_INI}."
    #perl -pi -e 's#^(error_reporting.*=)#${1} E_ERROR;#' ${PHP_INI}

    ECHO_DEBUG "Disable several functions: ${PHP_INI}."
    perl -pi -e 's#^(disable_functions.*=)(.*)#${1}show_source,system,shell_exec,passthru,exec,phpinfo,proc_open ; ${2}#' ${PHP_INI}

    ECHO_DEBUG "Hide PHP Version in Apache from remote users requests: ${PHP_INI}."
    perl -pi -e 's#^(expose_php.*=)#${1} Off;#' ${PHP_INI}

    ECHO_DEBUG "Increase 'memory_limit' to 128M: ${PHP_INI}."
    perl -pi -e 's#^(memory_limit = )#${1} 128M;#' ${PHP_INI}

    ECHO_DEBUG "Increase 'upload_max_filesize', 'post_max_size' to 10/12M: ${PHP_INI}."
    perl -pi -e 's/^(upload_max_filesize.*=)/${1}10M; #/' ${PHP_INI}
    perl -pi -e 's/^(post_max_size.*=)/${1}12M; #/' ${PHP_INI}

    # FreeBSD
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        # With Apache2.2 it now wants to load an Accept Filter.
        echo 'accf_http_load="YES"' >> /boot/loader.conf

        # Change 'Deny from all' to 'Allow from all'.
        sed -i '.iredmailtmp' '/Each directory to/,/Note that from/s#Deny\ from\ all#Allow\ from\ all#' ${HTTPD_CONF}
        rm -f ${HTTPD_CONF}.iredmailtmp >/dev/null 2>&1

        # Set ServerName.
        perl -pi -e 's/^#(ServerName).*/${1} $ENV{HOSTNAME}/' ${HTTPD_CONF}

        # Disable unique_id_module.
        perl -pi -e 's/^(LoadModule.*unique_id_module.*)/#${1}/' ${HTTPD_CONF}

        # Add index.php in DirectoryIndex.
        perl -pi -e 's#(.*DirectoryIndex.*)(index.html)#${1} index.php ${2}#' ${HTTPD_CONF}

        # Add php file type.
        echo 'AddType application/x-httpd-php .php' >> ${HTTPD_CONF}
        echo 'AddType application/x-httpd-php-source .phps' >> ${HTTPD_CONF}

        # Enable httpd-ssl.conf.
        perl -pi -e 's/^#(Include.*etc.*apache.*extra.*httpd-ssl.conf.*)/${1}/' ${HTTPD_CONF}

        # Create empty directory for htcacheclean.
        mkdir -p /usr/local/www/proxy/ 2>/dev/null

        # Ubuntu 10.04.
        # Comments starting with '#' are deprecated.
        [ -d /etc/php5/conf.d/ ] && perl -pi -e 's/^#(.*)/;${1}/' /etc/php5/cli/conf.d/*.ini

        # Start apache when system start up.
        cat >> /etc/rc.conf <<EOF
# Start apache web server.
apache22_enable="YES"
htcacheclean_enable="NO"
EOF
    fi

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
