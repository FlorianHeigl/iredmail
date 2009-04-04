#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# ---------------------------------------------------------
# SpamAssassin.
# ---------------------------------------------------------
sa_config()
{
    backup_file ${SA_LOCAL_CF}

    ECHO_INFO "Generate new configuration file: ${SA_LOCAL_CF}."
    cp -f ${SAMPLE_DIR}/sa.local.cf ${SA_LOCAL_CF}

    #ECHO_INFO "Disable plugin: URIDNSBL."
    #perl -pi -e 's/(^loadplugin.*Mail.*SpamAssassin.*Plugin.*URIDNSBL.*)/#${1}/' ${SA_INIT_PRE}

    ECHO_INFO "Enable crontabs for SpamAssassin update."
    perl -pi -e 's/#(10.*)/${1}/' /etc/cron.d/sa-update

    cat >> ${TIP_FILE} <<EOF
SpamAssassin:
    * Configuration files:
        - /etc/mail/spamassassin/

    * RC script:
        - /etc/init.d/spamd

    - Rules:
        * /usr/share/spamassassin/

EOF

    echo 'export status_sa_config="DONE"' >> ${STATUS_FILE}
}
