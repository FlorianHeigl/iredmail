#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Purpose:  Install & config necessary packages for iRedAPD.

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


iredapd_config()
{
    ECHO_INFO "Configure iRedAPD (postfix policy daemon)."

    # Create a low privilege user as daemon user.
    if [ X"${KERNEL_NAME}" == X"FreeBSD" ]; then
        pw useradd -s /sbin/nologin -d /home/iredapd -c "iRedAPD daemon user" -n ${IREDAPD_DAEMON_USER}
    else
        useradd -s /sbin/nologin -M -d /home/iredapd -c "iRedAPD daemon user" ${IREDAPD_DAEMON_USER}
    fi
    # Extract source tarball.
    cd ${MISC_DIR}
    [ -d ${IREDAPD_ROOT_DIR} ] || mkdir -p ${IREDAPD_ROOT_DIR}
    extract_pkg ${IREDAPD_TARBALL} ${IREDAPD_ROOT_DIR}

    ECHO_DEBUG "Configure iRedAPD."
    # Create symbol link.
    ln -s ${IREDAPD_ROOT_DIR}/iRedAPD-${IREDAPD_VERSION} ${IREDAPD_ROOT_DIR}/iredapd 2>/dev/null

    # Copy init rc script.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        cp ${SAMPLE_DIR}/iredapd.freebsd ${DIR_RC_SCRIPTS}/iredapd
    else
        cp ${IREDAPD_ROOT_DIR}/iredapd/rc_scripts/iredapd ${DIR_RC_SCRIPTS}/iredapd
    fi
    chmod 0555 ${DIR_RC_SCRIPTS}/iredapd
    chmod +x ${IREDAPD_ROOT_DIR}/iredapd/src/iredapd.py

    ECHO_DEBUG "Make iredapd start after system startup."
    eval ${enable_service} iredapd >/dev/null
    export ENABLED_SERVICES="${ENABLED_SERVICES} iredapd"

    # Copy sample config file.
    cd ${IREDAPD_ROOT_DIR}/iredapd/etc/
    cp iredapd.ini.sample iredapd.ini

    # Config iredapd.
    perl -pi -e 's#(listen_addr.*=).*#${1} $ENV{IREDAPD_LISTEN_ADDR}#' iredapd.ini
    perl -pi -e 's#(listen_port.*=).*#${1} $ENV{IREDAPD_LISTEN_PORT}#' iredapd.ini

    perl -pi -e 's#(run_as_user.*=).*#${1} $ENV{IREDAPD_DAEMON_USER}#' iredapd.ini
    perl -pi -e 's#(run_as_daemon.*=).*#${1} yes#' iredapd.ini

    perl -pi -e 's#(uri).*#${1} = ldap://$ENV{LDAP_SERVER_HOST}:$ENV{LDAP_SERVER_PORT}#' iredapd.ini
    perl -pi -e 's#(binddn).*#${1} = $ENV{LDAP_BINDDN}#' iredapd.ini
    perl -pi -e 's#(bindpw).*#${1} = $ENV{LDAP_BINDPW}#' iredapd.ini
    perl -pi -e 's#(basedn).*#${1} = $ENV{LDAP_BASEDN}#' iredapd.ini

    # Enable plugins.
    perl -pi -e 's#(plugins).*#${1} = maillist_access_policy#' iredapd.ini

    # FreeBSD.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        # Start iredapd when system start up.
        cat >> /etc/rc.conf <<EOF
# Start iredapd.
iredapd_enable="YES"
EOF
    fi

    cat >> ${TIP_FILE} <<EOF
iRedAPD - Postfix Policy Daemon:
    * Version: ${IREDAPD_VERSION}
    * Listen address: ${IREDAPD_LISTEN_ADDR}, port: ${IREDAPD_LISTEN_PORT}
    * Related files:
        - ${IREDAPD_ROOT_DIR}/iRedAPD-${IREDAPD_VERSION}/
        - ${IREDAPD_ROOT_DIR}/iredapd/
        - ${IREDAPD_ROOT_DIR}/iredapd/etc/iredapd.ini
EOF

    echo 'export status_iredapd_config="DONE"' >> ${STATUS_FILE}
}
