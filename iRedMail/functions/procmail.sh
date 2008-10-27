#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

enable_procmail()
{
    ECHO_INFO "Setup procmail as Mail Deliver Agent(MDA)."

    ECHO_INFO "Copy ${SAMPLE_DIR}/procmailrc as ${PROCMAILRC}."
    cp -f ${SAMPLE_DIR}/procmailrc ${PROCMAILRC}

    ECHO_INFO "Setup Postfix transport in ${POSTFIX_FILE_MASTER_CF}."
    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
dovecot unix    -       n       n       -       -      pipe
  flags=DRhu user=${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} argv=${PROCMAIL_BIN} -r -t SENDER=\${sender} RECIPIENT=\${recipient} DOMAIN=\${nexthop} -m USER=\${user} EXTENSION=\${extension} ${PROCMAILRC}
EOF

    ECHO_INFO "Setup transport in Postfix."
    postconf -e mailbox_command="${PROCMAIL_BIN} -f- -a \${EXTENSION}"

    ECHO_INFO "Setup procmail log file: ${PROCMAIL_LOGFILE}."
    touch ${PROCMAIL_LOGFILE}
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${PROCMAIL_LOGFILE}
    chmod 0700 ${PROCMAIL_LOGFILE}

    ECHO_INFO "Setup logrotate for procmail log file: ${PROCMAIL_LOGFILE}."
    cat >> ${PROCMAIL_LOGROTATE_FILE} <<EOF
${PROCMAIL_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 vmail vmail
    missingok

    # Use bzip2 for compress.
    #compresscmd $(which bzip2)
    #uncompresscmd $(which bunzip2)
    #compressoptions -9
    #compressext .bz2 

    postrotate
        /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
EOF

    echo 'export status_enable_procmail="DONE"' >> ${STATUS_FILE}
}
