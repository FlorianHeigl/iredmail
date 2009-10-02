#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Purpose:  Install & config necessary packages for iRedAdmin.

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

iredadmin_config()
{
    ECHO_INFO "======== iRedAdmin: Official Web-based Admin Panel  ========"

    if [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ECHO_INFO "Enable apache module: wsgi."
        a2enmod wsgi
    fi

    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${IREDADMIN_TARBALL} ${HTTPD_SERVERROOT}

    # Create symbol link, so that we don't need to modify apache
    # conf.d/iredadmin.conf file after upgrade this component.
    ln -s ${IREDADMIN_HTTPD_ROOT} ${HTTPD_SERVERROOT}/iredadmin 2>/dev/null

    ECHO_INFO "Set correct permission for iRedAdmin: ${RCM_HTTPD_ROOT}."
    chown -R ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${IREDADMIN_HTTPD_ROOT}
    chmod -R 0555 ${IREDADMIN_HTTPD_ROOT}

    # Copy sample configure file.
    cd ${IREDADMIN_HTTPD_ROOT}/ && \
    cp settings.ini.sample settings.ini
    chmod 0555 settings.ini

    ECHO_INFO "Create directory alias for iRedAdmin."
    backup_file ${HTTPD_CONF_DIR}/iredadmin.conf
    cat > ${HTTPD_CONF_DIR}/iredadmin.conf <<EOF
#
# Note: Uncomment below two lines if you want to make iRedAdmin accessable via HTTP.
#
#WSGIScriptAlias /iredadmin ${HTTPD_SERVERROOT}/iredadmin/iredadmin.py/
#Alias /iredadmin/static ${HTTPD_SERVERROOT}/iredadmin/static/

AddType text/html .py

<Directory ${HTTPD_SERVERROOT}/iredadmin/>
    Order deny,allow
    Allow from all
</Directory>

# Used to enable compress web contents during transfer.
DeflateCompressionLevel 3
AddOutputFilter DEFLATE html xml php js css
<Location />
SetOutputFilter DEFLATE
BrowserMatch ^Mozilla/4 gzip-only-text/html
BrowserMatch ^Mozilla/4\.0[678] no-gzip
BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
SetEnvIfNoCase Request_URI \\.(?:gif|jpe?g|png)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI .(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI .(?:pdf|mov|avi|mp3|mp4|rm)$ no-gzip dont-vary
#Header append Vary User-Agent env=!dont-vary
</Location>
EOF

    ECHO_INFO "Import iredadmin database template."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
# Create databases.
CREATE DATABASE ${IREDADMIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# Import SQL template.
USE ${IREDADMIN_DB_NAME};
SOURCE ${IREDADMIN_HTTPD_ROOT}/docs/samples/iredadmin.sql;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${IREDADMIN_DB_NAME}.* TO ${IREDADMIN_DB_USER}@localhost IDENTIFIED BY "${IREDADMIN_DB_PASSWD}";

FLUSH PRIVILEGES;
EOF

    ECHO_INFO "Configure iRedAdmin."

    # General settings: [general] section.
    [ ! -z ${MAIL_ALIAS_ROOT} ] && \
        perl -pi -e 's#webmaster =# $ENV{MAIL_ALIAS_ROOT}#' settings.ini

    # MySQL database related settings: [iredadmin] section.
    perl -pi -e 's#lang =# $ENV{DEFAULT_LANG}#' settings.ini
    perl -pi -e 's#host =# $ENV{MYSQL_SERVER}#' settings.ini
    perl -pi -e 's#port =# $ENV{MYSQL_PORT}#' settings.ini
    perl -pi -e 's#db =# $ENV{IREDADMIN_DB_NAME}#' settings.ini
    perl -pi -e 's#user =# $ENV{IREDADMIN_DB_USER}#' settings.ini
    perl -pi -e 's#passwd =# $ENV{IREDADMIN_DB_PASSWD}#' settings.ini

    # LDAP related settings: [ldap] section.
    perl -pi -e 's#uri =# ldap://$ENV{LDAP_SERVER_HOST}:$ENV{LDAP_SERVER_PORT}/#' settings.ini
    perl -pi -e 's#suffix =# $ENV{LDAP_SUFFIX}#' settings.ini
    perl -pi -e 's#basedn =# $ENV{LDAP_BASEDN}#' settings.ini
    perl -pi -e 's#domainadmin_dn =# $ENV{LDAP_ADMIN_BASEDN}#' settings.ini
    perl -pi -e 's#bind_dn =# $ENV{LDAP_BINDDN}#' settings.ini
    perl -pi -e 's#bind_pw =# $ENV{LDAP_BINDPW}#' settings.ini
}
