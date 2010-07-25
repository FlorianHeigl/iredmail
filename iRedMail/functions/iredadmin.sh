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
    ECHO_INFO "Configure iRedAdmin (official web-based admin panel)."

    # Create a low privilege user as httpd daemon user.
    if [ X"${KERNEL_NAME}" == X"FreeBSD" ]; then
        pw useradd -s /sbin/nologin -d /home/iredadmin -m -n ${IREDADMIN_HTTPD_USER}
    else
        useradd -s /sbin/nologin -m -d /home/iredadmin ${IREDADMIN_HTTPD_GROUP}
    fi

    if [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ECHO_DEBUG "Enable apache module: wsgi."
        a2enmod wsgi >/dev/null 2>&1
    fi

    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${IREDADMIN_TARBALL} ${HTTPD_SERVERROOT}

    # Create symbol link, so that we don't need to modify apache
    # conf.d/iredadmin.conf file after upgrade this component.
    ln -s ${IREDADMIN_HTTPD_ROOT} ${HTTPD_SERVERROOT}/iredadmin 2>/dev/null

    ECHO_DEBUG "Set correct permission for iRedAdmin: ${IREDADMIN_HTTPD_ROOT}."
    chown -R ${IREDADMIN_HTTPD_USER}:${IREDADMIN_HTTPD_GROUP} ${IREDADMIN_HTTPD_ROOT}
    chmod -R 0755 ${IREDADMIN_HTTPD_ROOT}

    # Copy sample configure file.
    cd ${IREDADMIN_HTTPD_ROOT}/ && \
    cp settings.ini.sample settings.ini
    chmod 0600 settings.ini

    ECHO_DEBUG "Create directory alias for iRedAdmin."
    backup_file ${HTTPD_CONF_DIR}/iredadmin.conf
    perl -pi -e 's#(</VirtualHost>)#WSGIScriptAlias /iredadmin "$ENV{HTTPD_SERVERROOT}/iredadmin/iredadmin.py/"\n${1}#' ${HTTPD_SSL_CONF}
    perl -pi -e 's#(</VirtualHost>)#Alias /iredadmin/static "$ENV{HTTPD_SERVERROOT}/iredadmin/static/"\n${1}#' ${HTTPD_SSL_CONF}

    cat > ${HTTPD_CONF_DIR}/iredadmin.conf <<EOF
#
# Note: Uncomment below two lines if you want to make iRedAdmin accessable via HTTP.
#
#WSGIScriptAlias /iredadmin ${HTTPD_SERVERROOT}/iredadmin/iredadmin.py/
#Alias /iredadmin/static ${HTTPD_SERVERROOT}/iredadmin/static/

WSGISocketPrefix /var/run/wsgi
WSGIDaemonProcess iredadmin user=${IREDADMIN_HTTPD_USER} threads=15
WSGIProcessGroup ${IREDADMIN_HTTPD_GROUP}

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

    ECHO_DEBUG "Import iredadmin database template."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
# Create databases.
CREATE DATABASE ${IREDADMIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# Import SQL template.
USE ${IREDADMIN_DB_NAME};
SOURCE ${IREDADMIN_HTTPD_ROOT}/docs/samples/iredadmin.sql;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${IREDADMIN_DB_NAME}.* TO ${IREDADMIN_DB_USER}@localhost IDENTIFIED BY "${IREDADMIN_DB_PASSWD}";

FLUSH PRIVILEGES;
EOF

    ECHO_DEBUG "Configure iRedAdmin."

    # General settings: [general] section.
    [ ! -z ${MAIL_ALIAS_ROOT} ] && \
        perl -pi -e 's#(webmaster =).*#${1} $ENV{MAIL_ALIAS_ROOT}#' settings.ini

    [ X"${MAILBOX_FORMAT}" != X"Maildir" ] && \
        perl -pi -e 's#(mailbox_type =).*#${1} $ENV{MAILBOX_FORMAT}#' settings.ini

    [ X"${MAILDIR_STYLE}" != X'hashed' ] && \
        perl -pi -e 's#(hashed_maildir =).*#${1} False#' settings.ini

    perl -pi -e 's#(mtaTransport =).*#${1} $ENV{TRANSPORT}#' settings.ini
    perl -pi -e 's#(storage_base_directory =).*#${1} $ENV{STORAGE_BASE_DIR}#' settings.ini
    perl -pi -e 's#(storage_node=).*#${1} $ENV{STORAGE_NODE}#' settings.ini

    # MySQL database related settings: [iredadmin] section.
    perl -pi -e 's#(lang =).*#${1} $ENV{DEFAULT_LANG}#' settings.ini
    perl -pi -e 's#(host =).*#${1} $ENV{MYSQL_SERVER}#' settings.ini
    perl -pi -e 's#(port =).*#${1} $ENV{MYSQL_PORT}#' settings.ini
    perl -pi -e 's#(db =).*#${1} $ENV{IREDADMIN_DB_NAME}#' settings.ini
    perl -pi -e 's#(user =).*#${1} $ENV{IREDADMIN_DB_USER}#' settings.ini
    perl -pi -e 's#(passwd =).*#${1} $ENV{IREDADMIN_DB_PASSWD}#' settings.ini

    # LDAP related settings: [ldap] section.
    perl -pi -e 's#(uri =).*#${1} ldap://$ENV{LDAP_SERVER_HOST}:$ENV{LDAP_SERVER_PORT}/#' settings.ini
    perl -pi -e 's#(suffix =).*#${1} $ENV{LDAP_SUFFIX}#' settings.ini
    perl -pi -e 's#(basedn =).*#${1} $ENV{LDAP_BASEDN}#' settings.ini
    perl -pi -e 's#(domainadmin_dn =).*#${1} $ENV{LDAP_ADMIN_BASEDN}#' settings.ini
    perl -pi -e 's#(bind_dn =).*#${1} $ENV{LDAP_ADMIN_DN}#' settings.ini
    perl -pi -e 's#(bind_pw =).*#${1} $ENV{LDAP_ADMIN_PW}#' settings.ini

    cat >> ${TIP_FILE} <<EOF
Official Web-based Admin Panel (iRedAdmin):
    * Version: ${IREDADMIN_VERSION}
    * Configuration files:
        - ${HTTPD_SERVERROOT}/iRedAdmin-${IREDADMIN_VERSION}/
        - ${HTTPD_SERVERROOT}/iRedAdmin-${IREDADMIN_VERSION}/settings.ini*
    * URL:
        - https://${HOSTNAME}/iredadmin/
    * Login account:
        - Username: ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}, password: ${DOMAIN_ADMIN_PASSWD_PLAIN}
    * Settings:

        [iredadmin]
        dbn = mysql
        host = ${MYSQL_SERVER}
        port = ${MYSQL_PORT}
        db = ${IREDADMIN_DB_NAME}
        user = ${IREDADMIN_DB_USER}
        passwd = ${IREDADMIN_DB_PASSWD}

        [ldap]
        uri = ldap://${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}/
        protocol_version = ${LDAP_BIND_VERSION}
        basedn = ${LDAP_BASEDN}
        domainadmin_dn = ${LDAP_ADMIN_BASEDN}
        bind_dn = ${LDAP_ADMIN_DN}
        bind_pw = ${LDAP_ADMIN_PW}

        [policyd]
        dbn = mysql
        host = ${MYSQL_SERVER}
        port = ${MYSQL_PORT}
        db = ${POLICYD_DB_NAME}
        user = ${POLICYD_DB_USER}
        passwd = ${POLICYD_DB_PASSWD}

    * See also:
        - ${HTTPD_CONF_DIR}/iredadmin.conf

EOF

    echo 'export status_iredadmin_config="DONE"' >> ${STATUS_FILE}
}
