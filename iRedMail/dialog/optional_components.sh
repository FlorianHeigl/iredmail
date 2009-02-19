#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------------
# ------------- SPF & DKIM -------------------------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "SPF & DKIM" \
        --checklist "\
Do you want to support SPF and DKIM?

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

# --------------------------------------------------
# ------------- pysieved: managesieve service ------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Managesieve Server" \
    --radiolist "\
Do you want to use managesieve service?

The ManageSieve protocol was proposed to manage sieve scripts on the
server without the need for direct file system access by the users.

" 20 76 3 \
    "pysieved" "Python Managesieve Server." "on" \
    2>/tmp/managesieve

MANAGESIEVE="$(cat /tmp/managesieve)"
rm -f /tmp/managesieve

if [ ! -z ${MANAGESIEVE} ]; then
    export USE_MANAGESIEVE='YES'
    echo "export USE_MANAGESIEVE='YES'" >> ${CONFIG_FILE}

    # pysieved.
    echo ${MANAGESIEVE} | grep -i 'pysieved' >/dev/null 2>&1
    if [ X"$?" == X"0" ]; then
        export USE_PYSIEVED='YES'
        echo "export USE_PYSIEVED='YES'" >> ${CONFIG_FILE}
    else
        :
    fi
else
    :
fi

# --------------------------------------------------
# ------------- POP3(s)/IMAP(s) --------------------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "POP3, POP3S, IMAP, IMAPS" \
    --checklist "\
Do you want to support POP3, POP3S, IMAP, IMAPS?
" 20 76 6 \
    "POP3" "Post Office Protocol." "on" \
    "POP3S" "Secure POP3 over SSL." "on" \
    "IMAP" "Internet Message Access Protocol." "on" \
    "IMAPS" "Secure IMAP over SSL." "on" \
    2>/tmp/dovecot_features

DOVECOT_FEATURES="$(cat /tmp/dovecot_features)"
rm -f /tmp/dovecot_features

echo ${DOVECOT_FEATURES} | grep -i '\<POP3\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_POP3='YES' && echo "export USE_POP3='YES'" >>${CONFIG_FILE}

echo ${DOVECOT_FEATURES} | grep -i '\<POP3S\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_POP3S='YES' && echo "export USE_POP3S='YES'" >>${CONFIG_FILE}

echo ${DOVECOT_FEATURES} | grep -i '\<IMAP\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_IMAP='YES' && echo "export USE_IMAP='YES'" >>${CONFIG_FILE}

echo ${DOVECOT_FEATURES} | grep -i '\<IMAPS\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_IMAPS='YES' && echo "export USE_IMAPS='YES'" >>${CONFIG_FILE}

# Check enable dovecot or not.
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

# WebMail.
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "WebMail Program" \
    --checklist "\
Please choose your favorite webmail program.
" 20 76 5 \
    "SquirrelMail" "WebMail program, written in PHP." "on" \
    "Roundcubemail" "WebMail program (PHP, XHTML, CSS2, AJAX)." "on" \
    "ExtMail" "WebMail program from ExtMail project." "off" \
    "Horde WebMail" "WebMail program." "off" \
    2> /tmp/webmail

webmail="$(cat /tmp/webmail)"
rm -f /tmp/webmail

echo ${webmail} | grep -i 'roundcubemail' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_RCM='YES' && echo "export USE_RCM='YES'" >> ${CONFIG_FILE}

echo ${webmail} | grep -i 'squirrelmail' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_SM='YES' && echo "export USE_SM='YES'" >>${CONFIG_FILE}

echo ${webmail} | grep -i 'extmail' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_EXTMAIL='YES' && echo "export USE_EXTMAIL='YES'" >>${CONFIG_FILE}

echo ${webmail} | grep -i 'Horde' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_HORDE='YES' && echo "export USE_HORDE='YES'" >>${CONFIG_FILE}

# Promot to choose the prefer language for webmail.
[ X"${webmail}" != X"" ] && . ${DIALOG_DIR}/default_language.sh

# ----------------------------------------
# Optional components for special backend.
# ----------------------------------------

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
${PROG_NAME} provides several optional components for LDAP backend, you can
use them by your own:
" 20 76 5 \
    "phpLDAPadmin" "Web-based LDAP browser to manage your LDAP server." "on" \
    "phpMyAdmin" "Web-based MySQL database management." "on" \
    "Awstats" "Advanced web and mail log analyzer." "on" \
    "Mailgraph" "Mail statistics RRDtool frontend for Postfix." "on" \
    2>/tmp/ldap_optional_components

    LDAP_OPTIONAL_COMPONENTS="$(cat /tmp/ldap_optional_components)"

    echo ${LDAP_OPTIONAL_COMPONENTS} | grep -i 'phpldapadmin' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_PHPLDAPADMIN='YES' && echo "export USE_PHPLDAPADMIN='YES'" >>${CONFIG_FILE}

    echo ${LDAP_OPTIONAL_COMPONENTS} | grep -i 'phpmyadmin' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_PHPMYADMIN='YES' && echo "export USE_PHPMYADMIN='YES'" >>${CONFIG_FILE}

    echo ${LDAP_OPTIONAL_COMPONENTS} | grep -i 'awstats' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_AWSTATS='YES' && echo "export USE_AWSTATS='YES'" >>${CONFIG_FILE}

    echo ${LDAP_OPTIONAL_COMPONENTS} | grep -i 'mailgraph' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_MAILGRAPH='YES' && echo "export USE_MAILGRAPH='YES'" >>${CONFIG_FILE}

    rm /tmp/ldap_optional_components

elif [ X"${BACKEND}" == X"MySQL" ]; then
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
${PROG_NAME} provides several optional components for MySQL backend, you can use
them by your own:
" 20 76 5 \
    "phpMyAdmin" "Web-based MySQL database management." "on" \
    "PostfixAdmin" "Web-based program to manage domains and users stored in MySQL." "on" \
    "Awstats" "Advanced web and mail log analyzer." "on" \
    "Mailgraph" "Mail statistics RRDtool frontend for Postfix." "on" \
    2>/tmp/mysql_optional_components

    MYSQL_OPTIONAL_COMPONENTS="$(cat /tmp/mysql_optional_components)"
    rm -f /tmp/mysql_optional_components

    echo ${MYSQL_OPTIONAL_COMPONENTS} | grep -i 'phpmyadmin' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_PHPMYADMIN='YES' && echo "export USE_PHPMYADMIN='YES'" >>${CONFIG_FILE}

    echo ${MYSQL_OPTIONAL_COMPONENTS} | grep -i 'postfixadmin' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_POSTFIXADMIN='YES' && echo "export USE_POSTFIXADMIN='YES'" >>${CONFIG_FILE}

    echo ${MYSQL_OPTIONAL_COMPONENTS} | grep -i 'awstats' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_AWSTATS='YES' && echo "export USE_AWSTATS='YES'" >>${CONFIG_FILE}

    echo ${MYSQL_OPTIONAL_COMPONENTS} | grep -i 'mailgraph' >/dev/null 2>&1
    [ X"$?" == X"0" ] && USE_MAILGRAPH='YES' && echo "export USE_MAILGRAPH='YES'" >>${CONFIG_FILE}

else
    # No hook for other backend yet.
    :
fi

# Used when you use OpenLDAP as backend, only prompt for MySQL root password.
[ X"${BACKEND}" == X"OpenLDAP" ] && . ${DIALOG_DIR}/mysql_config.sh

# Used when you use MySQL as backend.
[ X"${USE_POSTFIXADMIN}" == X"YES" ] && . ${DIALOG_DIR}/postfixadmin_config.sh

# Used when you use awstats.
[ X"${USE_AWSTATS}" == X"YES" ] && . ${DIALOG_DIR}/awstats_config.sh
