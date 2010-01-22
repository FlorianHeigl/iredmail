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

    ECHO_INFO "Add first domain (${FIRST_DOMAIN}) as virtual host."
    perl -pi -e 's#^({hosts,.*)#%%%${1}#g' ${EJABBERD_CONF}
    cat >> ${EJABBERD_CONF} <<EOF
${CONF_MSG}
%%% Virtual domains.
{hosts, ["${FIRST_DOMAIN}"]}.
EOF

    ECHO_INFO "Make ejabberd authenticate user against OpenLDAP."
    cat >> ${EJABBERD_CONF} <<EOF
%%% Authenticate against LDAP.
{auth_method, ldap}.
{ldap_servers, ["${LDAP_SERVER_HOST}"]}.
%%% {ldap_encrypt, tls}.
{ldap_port, ${LDAP_SERVER_PORT}}.
{ldap_base, "${LDAP_SUFFIX}"}.
{ldap_rootdn, "${LDAP_BINDDN}"}.
{ldap_password, "${LDAP_BINDPW}"}.
%%% Enable both normal mail user and mail admin.
{ldap_filter, "(&(|(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(objectClass=${LDAP_OBJECTCLASS_MAILADMIN}))(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_JABBER}))"}.
{ldap_uids, [{"mail", "%u@%d"}]}.
EOF

    ECHO_INFO "Enable starttls/ssl support."
    perl -pi -e 's#(.*)(%%)(.*certfile.*path.*t.*etc.*ejabberd.pem.*starttls.*)#${1}{certfile, "/etc/ejabberd/ejabberd.pem"}, starttls,#' ${EJABBERD_CONF}
    perl -pi -e 's#(.*)(%%)(.*certfile.*path.*t.*etc.*ejabberd.pem.* tls.*)#${1}{certfile, "/etc/ejabberd/ejabberd.pem"}, tls,#' ${EJABBERD_CONF}

    echo 'export status_ejabberd_config="DONE"' >> ${STATUS_FILE}
}
