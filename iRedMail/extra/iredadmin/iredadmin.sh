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

ROOTDIR="$(pwd)"
CONF_DIR="${ROOTDIR}/../../conf"

. ${CONF_DIR}/global
. ${CONF_DIR}/functions
. ${CONF_DIR}/core

. ${CONF_DIR}/apache_php

. ${ROOTDIR}/conf/iredadmin

check_user root

# Prepare all necessary packages.
ALL_PKGS=''

# Necessary devel packages, used for building python modules.
if [ X"${DISTRO}" == X"RHEL" ]; then
    ALL_PKGS="${ALL_PKGS} python-setuptools.noarch gcc.${ARCH} gcc-c++.${ARCH} openssl-devel.${ARCH} python-devel.${ARCH} openldap-devel.${ARCH} MySQL-python.${ARCH}"
elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
    ALL_PKGS="${ALL_PKGS} gcc python-setuptools python-dev libldap2-dev libmysqlclient15-dev libsasl2-dev libssl-dev libapache2-mod-wsgi"
fi

# Install binary packages.
ECHO_INFO "Install necessary devel packages, used for building python modules."
${install_pkg} ${ALL_PKGS}

ECHO_INFO "Install necessary python modules as dependences."
easy_install web.py Jinja2 python-ldap netifaces

if [ X"${DISTRO}" == X"RHEL" ]; then
    ECHO_INFO "Install apache module: mod_wsgi."
    rpm -ivh http://download.fedora.redhat.com/pub/epel/5/${ARCH}/mod_wsgi-2.1-2.el5.${ARCH}.rpm
elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
    ECHO_INFO "Enable apache module: wsgi."
    a2enmod wsgi
fi

ECHO_INFO "Configure apache."
backup_file ${HTTPD_CONF_DIR}/iredadmin.conf
cat > ${HTTPD_CONF_DIR}/iredadmin.conf <<EOF
WSGIScriptAlias /iredadmin ${HTTPD_SERVERROOT}/iredadmin/iredadmin.py/
Alias /iredadmin/static ${HTTPD_SERVERROOT}/iredadmin/static/
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

ECHO_INFO "Import sample database."
mysql -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
# Create databases.
CREATE DATABASE ${IREDADMIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# Import SQL template.
USE ${IREDADMIN_DB_NAME};
SOURCE ${ROOTDIR}/samples/iredadmin.sql;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${IREDADMIN_DB_NAME}.* TO ${IREDADMIN_DB_USER}@localhost IDENTIFIED BY "${IREDADMIN_DB_PASSWD}";

FLUSH PRIVILEGES;
EOF

ECHO_INFO "Generating [iredadmin] section for iredadmin in ${ROOTDIR}/settings.ini.part"
cat > ${ROOTDIR}/settings.ini.part <<EOF
[iredadmin]
# Database used to store iRedAdmin data. e.g. sessions, log.
dbn = mysql
host = localhost
port = 3306
db = ${IREDADMIN_DB_NAME}
user = ${IREDADMIN_DB_USER}
passwd = ${IREDADMIN_DB_PASSWD}
db_table_session = sessions
EOF

ECHO_INFO "Installation complete."
