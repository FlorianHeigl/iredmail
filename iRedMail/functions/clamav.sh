#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------
# ClamAV.
# --------------------------------------------

clamav_config()
{
    ECHO_INFO "Configure ClamAV: ${CLAMD_CONF}."
    perl -pi -e 's/^(TCPSocket.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(TCPAddr )/${1}no #/' ${CLAMD_CONF}

    # The following options are no longer supported in ClamAV 0.93.
    perl -pi -e 's/^(MailMaxRecursion.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(ArchiveMaxFileSize.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(ArchiveMaxRecursion.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(ArchiveMaxFiles.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(ArchiveMaxCompressionRatio.*)/#${1}/' ${CLAMD_CONF}
    perl -pi -e 's/^(ArchiveBlockMax.*)/#${1}/' ${CLAMD_CONF}

    ECHO_INFO "Configure freshclam: ${FRESHCLAM_CONF}."
    perl -pi -e 's-^#(PidFile)(.*)-${1} $ENV{FRESHCLAM_PID_FILE} #${2}-' ${FRESHCLAM_CONF}

    ECHO_INFO "Copy freshclam init startup script and enable it."
    cp -f ${FRESHCLAM_INIT_FILE_SAMPLE} /etc/rc.d/init.d/freshclam
    chmod +x /etc/rc.d/init.d/freshclam
    eval ${disable_service} freshclam

    cat >> ${TIP_FILE} <<EOF
ClamAV:
    * Configuration files:
        - ${CLAMD_CONF}
        - ${FRESHCLAM_CONF}
        - /etc/logrotate.d/clamav
    * RC scripts:
        - /etc/init.d/clamd
        - /etc/init.d/freshclam
    * Log files:
        - /var/log/clamav/clamd.log
        - /var/log/clamav/freshclam.log

EOF

    echo 'export status_clamav_config="DONE"' >> ${STATUS_FILE}
}
