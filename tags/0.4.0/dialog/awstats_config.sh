#!/bin/sh

# Author:	Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------------
# -------------------- Awstats ---------------------
# --------------------------------------------------

. ${CONF_DIR}/awstats

if [ X"${BACKEND}" == X"OpenLDAP" -o X"${BACKEND}" == X"MySQL" ]; then
    :
else
    # Set username for awstats access.
    while : ; do
        ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Specify username for access awstats from web browser" \
        --inputbox "\
Please specify username for access awstats from web browser.

Example:

    * michaelbibby

" 20 76 2>/tmp/awstats_username

        AWSTATS_USERNAME="$(cat /tmp/awstats_username)"
        [ X"${AWSTATS_USERNAME}" != X"" ] && break
    done

    echo "export AWSTATS_USERNAME='${AWSTATS_USERNAME}'" >>${CONFIG_FILE}
    rm -f /tmp/awstats_username

    # Set password for awstats user.
    while : ; do
        ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "Password for awstats user: ${AWSTATS_USERNAME}" \
        --insecure --passwordbox "\
Please specify password for awstats user: ${AWSTATS_USERNAME}

Warning:

    * EMPTY password is *NOT* permit.

" 20 76 2>/tmp/awstats_passwd

        AWSTATS_PASSWD="$(cat /tmp/awstats_passwd)"
        [ X"${AWSTATS_PASSWD}" != X"" ] && break
    done

    echo "export AWSTATS_PASSWD='${AWSTATS_PASSWD}'" >>${CONFIG_FILE}
    rm -f /tmp/awstats_passwd
fi
