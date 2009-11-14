#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------
# Mailman.
# -------------------------------------------------
mailman_config()
{
    ECHO_INFO "Initialize mailman."
    echo "MTA = 'Postfix'" >> /etc/mailman/mm_cfg.py
    echo "POSTFIX_STYLE_VIRTUAL_DOMAINS = ['${FIRST_DOMAIN}',]" >> /etc/mailman/mm_cfg.py

    ECHO_INFO "Create site-wide mailing list: mailman."
    /usr/lib/mailman/bin/newlist \
    mailman \
    ${FIRST_MAILING_LIST_OWNER} \
    ${FIRST_MAILING_LIST_OWNER_PASSWD} <<EOF
EOF

    ECHO_INFO "Add first mailing list: ${FIRST_MAILING_LIST_NAME}@${FIRST_DOMAIN}."
    /usr/lib/mailman/bin/newlist \
    ${FIRST_MAILING_LIST_NAME} \
    ${FIRST_MAILING_LIST_OWNER} \
    ${FIRST_MAILING_LIST_OWNER_PASSWD} <<EOF
EOF

    ECHO_INFO "Generate aliases in Mailman."
    chown mailman:mailman /etc/mailman/aliases*
    /usr/lib/mailman/bin/genaliases

    ECHO_INFO "Setting up Postfix for Mailman."
    postconf -e recipient_delimiter='+'
    postconf -e unknown_local_recipient_reject_code='550'
    postconf -e alias_maps="hash:${POSTFIX_FILE_ALIASES}, hash:/etc/mailman/aliases"

    echo "RedirectMatch ^/mailman[/]*$ http://$(hostname)/mailman/listinfo" >> ${HTTPD_CONF_DIR}/mailman.conf

    cat >> ${TIP_FILE} <<EOF
Mailman:
    * Configuration files:
        - /etc/mailman/
    * RC script:
        - /etc/init.d/mailman

EOF

    echo 'export status_mailman_config="DONE"' >> ${STATUS_FILE}
}
