#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

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
# ---------------------- ejabberd -----------------------
# -------------------------------------------------------

ejabberd_config()
{
    ECHO_INFO "==================== ejabberd ===================="

    backup_file ${EJABBERD_CONF}

    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        cp ${EJABBERD_CONF}.example ${EJABBERD_CONF}
        cp ${EJABBERD_CONF}.example ${EJABBERD_CONF}

    ECHO_INFO "Add first domain (${FIRST_DOMAIN}) as virtual host."
    perl -pi -e 's#^({hosts,.*)#%%%${1}#g' ${EJABBERD_CONF}
    cat >> ${EJABBERD_CONF} <<EOF
%%% Virtual domains.
{hosts, ["${FIRST_DOMAIN}"]}.
EOF

    ECHO_INFO "Make ejabberd authenticate user against OpenLDAP."
    # Disable other auth mothods.
    perl -pi -e 's#^({auth_method,.*)#%%%${1}#' ${EJABBERD_CONF}

    cat >> ${EJABBERD_CONF} <<EOF
%%% Authenticate against LDAP.
{auth_method, ldap}.
{ldap_servers, ["${LDAP_SERVER_HOST}"]}.
%%% {ldap_encrypt, tls}.
{ldap_port, ${LDAP_SERVER_PORT}}.
{ldap_base, "${LDAP_BASEDN}"}.
{ldap_rootdn, "${LDAP_BINDDN}"}.
{ldap_password, "${LDAP_BINDPW}"}.
%%% Enable both normal mail user and mail admin.
{ldap_filter, "(&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_JABBER}))"}.
{ldap_uids, [{"mail", "%u@%d"}]}.
EOF

    ECHO_INFO "Enable starttls/ssl support."
    # RHEL/CentOS
    perl -pi -e 's#(.*)(%%)(.*certfile.*path.*t.*etc.*ejabberd.pem.*starttls.*)#${1}{certfile, "$ENV{EJABBERD_PEM}"}, starttls,#' ${EJABBERD_CONF}
    # Debian/Ubuntu.
    perl -pi -e 's#(.*)(%%)(.*starttls,.*certfile.*path.*t.*etc.*ejabberd.pem.*)#${1}{certfile, "$ENV{EJABBERD_PEM}"}, starttls#' ${EJABBERD_CONF}

    # Enable tls, port 5223.
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*{5223,.*ejabberd_c2s,.*\)#\1\3#' ${EJABBERD_CONF}
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*{access,.*c2s},\)#\1\3#' ${EJABBERD_CONF}
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*{shaper,.*c2s_shaper},\)#\1\3#' ${EJABBERD_CONF}
    # RHEL/CentOS
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*\)\({certfile,.*},\)\(.*tls,\)#\1\3{certfile, "'${EJABBERD_PEM}'"},\5#' ${EJABBERD_CONF}
    # Debian/Ubuntu
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*tls,.*\)\({certfile,.*},\)#\1\3{certfile, "'${EJABBERD_PEM}'"}#' ${EJABBERD_CONF}
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*{max_stanza_size.*\)#\1\3#' ${EJABBERD_CONF}
    sed -i '/5223/,/5269/ s#\(.*\)\(%%\)\(.*]},\)#\1\3#' ${EJABBERD_CONF}

    echo 'export status_ejabberd_config="DONE"' >> ${STATUS_FILE}
}
