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

# --------------------------------------------
# ClamAV.
# --------------------------------------------

clamav_config()
{
    ECHO_INFO "==================== ClamAV ===================="

    export CLAMD_LOCAL_SOCKET CLAMD_LISTEN_ADDR
    ECHO_INFO "Configure ClamAV: ${CLAMD_CONF}."
    perl -pi -e 's/^(TCPSocket.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's#^(TCPAddr).*#${1} $ENV{'CLAMD_LISTEN_ADDR'}#' ${CLAMD_CONF}
    perl -pi -e 's#^(LocalSocket).*#${1} $ENV{'CLAMD_LOCAL_SOCKET'}#' ${CLAMD_CONF}
    perl -pi -e 's#^(LogFile).*#${1} $ENV{'CLAMD_LOGFILE'}#' ${CLAMD_CONF}

    ECHO_INFO "Configure freshclam: ${FRESHCLAM_CONF}."
    perl -pi -e 's#^(DatabaseMirror).*#${1} $ENV{'FRESHCLAM_DATABASE_MIRROR'}#' ${CLAMD_CONF}
    perl -pi -e 's-^#(PidFile)(.*)-${1} $ENV{FRESHCLAM_PID_FILE} #${2}-' ${FRESHCLAM_CONF}
    perl -pi -e 's#^(UpdateLogFile).*#${1} $ENV{'FRESHCLAM_LOGFILE'}#' ${CLAMD_CONF}

    if [ X"${DISTRO}" == X"RHEL" ]; then
        ECHO_INFO "Copy freshclam init startup script and enable it."
        cp -f ${FRESHCLAM_INIT_FILE_SAMPLE} /etc/rc.d/init.d/freshclam
        chmod +x /etc/rc.d/init.d/freshclam
        eval ${enable_service} freshclam
        export ENABLED_SERVICES="${ENABLED_SERVICES} freshclam"
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
ClamAV:
    * Configuration files:
        - ${CLAMD_CONF}
        - ${FRESHCLAM_CONF}
        - /etc/logrotate.d/clamav
    * RC scripts:
        - RHEL/CentOS:
            + /etc/init.d/clamd 
            + /etc/init.d/freshclam
        - Debian & Ubuntu:
            + /etc/init.d/clamav-daemon
            + /etc/init.d/clamav-freshclam
    * Log files:
        - ${CLAMD_LOGFILE}
        - ${FRESHCLAM_LOGFILE}

EOF

    echo 'export status_clamav_config="DONE"' >> ${STATUS_FILE}
}
