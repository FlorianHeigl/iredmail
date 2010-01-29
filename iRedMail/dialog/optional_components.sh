#!/usr/bin/env bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

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

# ----------------------------------------
# Optional components for special backend.
# ----------------------------------------

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    ${DIALOG} \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
Note:
    * DKIM is recommended.
    * DNS record (TXT type) are required for both SPF and DKIM.
    * Please refer to file for more detail after installation:
      ${TIP_FILE}
" 20 76 7 \
    "SPF Validation" "Sender Policy Framework" "on" \
    "DKIM signing/verification" "DomainKeys Identified Mail" "on" \
    "iRedAdmin" "Official web-based iRedMail Admin Panel" "on" \
    "Roundcubemail" "WebMail program (PHP, AJAX)" "on" \
    "phpLDAPadmin" "Web-based OpenLDAP management tool" "on" \
    "phpMyAdmin" "Web-based MySQL management tool" "on" \
    "Awstats" "Advanced web and mail log analyzer" "on" \
    2>/tmp/optional_components

elif [ X"${BACKEND}" == X"MySQL" ]; then
    ${DIALOG} \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
Note:
    * DKIM is recommended.
    * DNS record (TXT type) are required for both SPF and DKIM.
    * Please refer to file for more detail after installation:
      ${TIP_FILE}
" 20 76 6 \
    "SPF Validation" "Sender Policy Framework" "on" \
    "DKIM signing/verification" "DomainKeys Identified Mail" "on" \
    "Roundcubemail" "WebMail program (PHP, AJAX)" "on" \
    "phpMyAdmin" "Web-based MySQL management tool" "on" \
    "PostfixAdmin" "Web-based mail account management tool" "on" \
    "Awstats" "Advanced web and mail log analyzer" "on" \
    2>/tmp/optional_components
else
    # No hook for other backend yet.
    :
fi

OPTIONAL_COMPONENTS="$(cat /tmp/optional_components)"
rm -f /tmp/optional_components

echo ${OPTIONAL_COMPONENTS} | grep -i '\<SPF\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && export ENABLE_SPF='YES' && echo "export ENABLE_SPF='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i '\<DKIM\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && export ENABLE_DKIM='YES' && echo "export ENABLE_DKIM='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'iredadmin' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_IREDADMIN='YES' && export USE_IREDADMIN='YES' && echo "export USE_IREDADMIN='YES'" >> ${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'roundcubemail' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_WEBMAIL='YES'
    export USE_RCM='YES'
    echo "export USE_WEBMAIL='YES'" >> ${CONFIG_FILE}
    echo "export USE_RCM='YES'" >> ${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpldapadmin' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_PHPLDAPADMIN='YES'
    echo "export USE_PHPLDAPADMIN='YES'" >>${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpmyadmin' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_PHPMYADMIN='YES'
    echo "export USE_PHPMYADMIN='YES'" >>${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'postfixadmin' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_POSTFIXADMIN='YES'
    echo "export USE_POSTFIXADMIN='YES'" >>${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'awstats' >/dev/null 2>&1
[ X"$?" == X"0" ] && USE_AWSTATS='YES' && echo "export USE_AWSTATS='YES'" >>${CONFIG_FILE}

# ----------------------------------------------------------------
# Promot to choose the prefer language for webmail.
[ X"${USE_WEBMAIL}" == X"YES" ] && . ${DIALOG_DIR}/default_language.sh

# Used when you use awstats.
[ X"${USE_AWSTATS}" == X"YES" ] && . ${DIALOG_DIR}/awstats_config.sh
