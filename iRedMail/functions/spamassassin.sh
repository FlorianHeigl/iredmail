#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# ---------------------------------------------------------
# SpamAssassin.
# ---------------------------------------------------------
sa_config()
{
    ECHO_INFO "==================== SpamAssassin ===================="

    backup_file ${SA_LOCAL_CF}

    ECHO_INFO "Generate new configuration file: ${SA_LOCAL_CF}."
    cp -f ${SAMPLE_DIR}/sa.local.cf ${SA_LOCAL_CF}

    #ECHO_INFO "Disable plugin: URIDNSBL."
    #perl -pi -e 's/(^loadplugin.*Mail.*SpamAssassin.*Plugin.*URIDNSBL.*)/#${1}/' ${SA_INIT_PRE}

    ECHO_INFO "Enable crontabs for SpamAssassin update."
    if [ X"${DISTRO}" == X"RHEL" ]; then
        chmod 0644 /etc/cron.d/sa-update
        perl -pi -e 's/#(10.*)/${1}/' /etc/cron.d/sa-update
    elif [ X"${DISTRO}" == X"UBUNTU" -o X"${DISTRO}" == X"DEBIAN" ]; then
        perl -pi -e 's#^(CRON=)0#${1}1#' /etc/cron.daily/spamassassin
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
SpamAssassin:
    * Configuration files:
        - /etc/mail/spamassassin/

    - Rules:
        * /usr/share/spamassassin/

EOF

    echo 'export status_sa_config="DONE"' >> ${STATUS_FILE}
}
