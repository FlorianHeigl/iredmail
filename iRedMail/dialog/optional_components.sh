#!/bin/bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------------
# ------------- POP3(s)/IMAP(s) --------------------
# --------------------------------------------------
# Check enable dovecot or not. No dialog pages, but read from global
# variables defined in file 'conf/global'.
if [ X"${USE_POP3}" == X"YES" -o X"${USE_POP3S}" == X"YES" \
    -o X"${USE_IMAP}" == X"YES" -o X"${USE_IMAPS}" == X"YES" ]; then
    export ENABLE_DOVECOT="YES" && \
    echo 'export ENABLE_DOVECOT="YES"' >> ${CONFIG_FILE}

    # Which protocol will be enabled by Dovecot.
    DOVECOT_PROTOCOLS=''
    [ X"${USE_POP3}" == X"YES" ] && DOVECOT_PROTOCOLS="${DOVECOT_PROTOCOLS} pop3"
    [ X"${USE_POP3S}" == X"YES" ] && DOVECOT_PROTOCOLS="${DOVECOT_PROTOCOLS} pop3s" && export ENABLE_DOVECOT_SSL="YES"
    [ X"${USE_IMAP}" == X"YES" ] && DOVECOT_PROTOCOLS="${DOVECOT_PROTOCOLS} imap"
    [ X"${USE_IMAPS}" == X"YES" ] && DOVECOT_PROTOCOLS="${DOVECOT_PROTOCOLS} imaps" && export ENABLE_DOVECOT_SSL="YES"
    echo "export DOVECOT_PROTOCOLS='${DOVECOT_PROTOCOLS}'" >> ${CONFIG_FILE}

    if [ X"${ENABLE_DOVECOT_SSL}" == X"YES" ]; then
        echo 'export ENABLE_DOVECOT_SSL="YES"' >> ${CONFIG_FILE}
    else
        echo 'export ENABLE_DOVECOT_SSL="NO"' >> ${CONFIG_FILE}
    fi

else
    # Disable Dovecot.
    export ENABLE_DOVECOT="NO" && echo 'export ENABLE_DOVECOT="NO"' >> ${CONFIG_FILE}
    export ENABLE_DOVECOT_SSL="NO" && echo 'export ENABLE_DOVECOT_SSL="NO"' >> ${CONFIG_FILE}
fi

# --------------------------------------------------
# ------------- SPF & DKIM -------------------------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2SPF & DKIM\Zn" \
        --checklist "\
Do you want to support \Zb\Z2SPF and DKIM\Zn?

Note:
    * DKIM is recommended.
    * DNS record (txt type) are required for both.

Please refer to the following file for more details after
installation completed:

    * ${TIP_FILE}
" 20 76 4 \
    "SPF Validation" "Sender Policy Framework" "on" \
    "DKIM signing and verification" "DomainKeys Identified Mail" "on" \
    2>/tmp/spf_dkim

SPF_DKIM="$(cat /tmp/spf_dkim)"
rm -f /tmp/spf_dkim

echo ${SPF_DKIM} | grep -i '\<SPF\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && ENABLE_SPF='YES' && echo "export ENABLE_SPF='YES'" >>${CONFIG_FILE}

echo ${SPF_DKIM} | grep -i '\<DKIM\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && ENABLE_DKIM='YES' && echo "export ENABLE_DKIM='YES'" >>${CONFIG_FILE}

# ----------------------------------------
# Optional components for special backend.
# ----------------------------------------

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Optional Components\Zn for ${BACKEND} backend" \
    --checklist "\
${PROG_NAME} provides several \Zb\Z2optional components\Zn for LDAP backend, you can
use them by your own:
" 20 76 5 \
    "Roundcubemail" "WebMail program (PHP, XHTML, CSS2, AJAX)." "on" \
    "SquirrelMail" "WebMail program, written in PHP." "off" \
    "phpLDAPadmin" "Web-based LDAP browser to manage your LDAP server." "on" \
    "phpMyAdmin" "Web-based MySQL database management." "on" \
    "Awstats" "Advanced web and mail log analyzer." "on" \
    2>/tmp/optional_components

elif [ X"${BACKEND}" == X"MySQL" ]; then
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Optional Components\Zn for ${BACKEND} backend" \
    --checklist "\
${PROG_NAME} provides several \Zb\Z2optional components\Zn for MySQL backend, you can use
them by your own:
" 20 76 5 \
    "Roundcubemail" "WebMail program (PHP, XHTML, CSS2, AJAX)." "on" \
    "SquirrelMail" "WebMail program, written in PHP." "off" \
    "phpMyAdmin" "Web-based MySQL database management." "on" \
    "PostfixAdmin" "Web-based program to manage domains and users stored in MySQL." "on" \
    "Awstats" "Advanced web and mail log analyzer." "on" \
    2>/tmp/optional_components
else
    # No hook for other backend yet.
    :
fi

OPTIONAL_COMPONENTS="$(cat /tmp/optional_components)"
rm -f /tmp/optional_components

echo ${OPTIONAL_COMPONENTS} | grep -i 'roundcubemail' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_WEBMAIL='YES' && export USE_RCM='YES' && echo "export USE_RCM='YES'" >> ${CONFIG_FILE}

echo ${webmail} | grep -i 'squirrelmail' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_WEBMAIL='YES' && export USE_SM='YES' && echo "export USE_SM='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpldapadmin' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_PHPLDAPADMIN='YES' && echo "export USE_PHPLDAPADMIN='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpmyadmin' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_PHPMYADMIN='YES' && echo "export USE_PHPMYADMIN='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'postfixadmin' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_POSTFIXADMIN='YES' && echo "export USE_POSTFIXADMIN='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'awstats' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_AWSTATS='YES' && echo "export USE_AWSTATS='YES'" >>${CONFIG_FILE}

# ----------------------------------------------------------------
# Promot to choose the prefer language for webmail.
[ X"${USE_WEBMAIL}" == X"YES" ] && . ${DIALOG_DIR}/default_language.sh

# Used when you use MySQL as backend.
[ X"${USE_POSTFIXADMIN}" == X"YES" ] && . ${DIALOG_DIR}/postfixadmin_config.sh

# Used when you use awstats.
[ X"${USE_AWSTATS}" == X"YES" ] && . ${DIALOG_DIR}/awstats_config.sh
