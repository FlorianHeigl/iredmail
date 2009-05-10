#!/bin/bash

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)

# Note: config file will be sourced in 'conf/functions', check_env().

. ./conf/global
. ./conf/functions

trap "exit 255" 2

# Initialize config file.
echo '' > ${CONFIG_FILE}

DIALOG='dialog --no-collapse --insecure --ok-label Next --no-cancel'
DIALOG_BACKTITLE="${PROG_NAME}: Open Source Mail Server Solution for RHEL/CentOS/Debian/Ubuntu."

# Welcome message.
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Welcome and thanks for use" \
    --yesno "\
Thanks for your use of ${PROG_NAME}.
Bug report, feedback, suggestion are always welcome.

Contact us:

    * Forum: http://www.iredmail.org/forum/

NOTE:

    Ctrl-C will abort this wizard.
" 20 76

# Exit when user choose 'exit'.
[ X"$?" != X"0" ] && ECHO_INFO "Exit." && exit 0

# VMAIL_USER_HOME_DIR
VMAIL_USER_HOME_DIR="/home/vmail"
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "HOME directory of VMAIL user" \
    --inputbox "\
Please specify the HOME directory of vmail user: ${VMAIL_USER_NAME}.

EXAMPLE:

    * ${VMAIL_USER_HOME_DIR}

NOTE:

    * All mails will be stored in this HOME directory, so it may take
      large disk space.
" 20 76 "${VMAIL_USER_HOME_DIR}" 2>/tmp/vmail_user_home_dir

VMAIL_USER_HOME_DIR="$(cat /tmp/vmail_user_home_dir)"
export VMAIL_USER_HOME_DIR="${VMAIL_USER_HOME_DIR}" && echo "export VMAIL_USER_HOME_DIR='${VMAIL_USER_HOME_DIR}'" >>${CONFIG_FILE}
export SIEVE_DIR="${VMAIL_USER_HOME_DIR}/sieve" && echo "export SIEVE_DIR='${SIEVE_DIR}'" >>${CONFIG_FILE}
rm -f /tmp/vmail_user_home_dir

# --------------------------------------------------
# --------------------- Backend --------------------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Choose your prefer backend" \
    --radiolist "\
We provide two backends and the homologous webmail programs:

    +----------+---------------+--------------+
    | Backend  | Web Mail      | Admin tool   |
    +----------+---------------+--------------+
    | OpenLDAP |               | phpLDAPadmin |
    +----------+ RoundcubeMail +--------------+
    | MySQL    |               | PostfixAdmin |
    +----------+---------------+--------------+

TIP:
    * Use 'Space' key to select item.

" 20 76 2 \
    "OpenLDAP" "An open source implementation of LDAP protocol. " "on" \
    "MySQL" "The world's most popular open source database." "off" \
    2>/tmp/backend

BACKEND="$(cat /tmp/backend)"
echo "export BACKEND='${BACKEND}'" >> ${CONFIG_FILE}
rm -f /tmp/backend

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    . ${DIALOG_DIR}/ldap_config.sh
else
    :
fi

# MySQL server is required as backend or used to store policyd/roundcube data.
. ${DIALOG_DIR}/mysql_config.sh

#
# Virtual domain configuration.
#
. ${DIALOG_DIR}/virtual_domain_config.sh

#
# For optional components.
#
. ${DIALOG_DIR}/optional_components.sh

#
# Set mail alias for root.
#
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Specify mail alias for 'root' user" \
    --inputbox "\
Please specify a *E-Mail* address for 'root' user alias.

Mail deliver failure notice will send to this alias address instead of
system account 'root'.

EXAMPLE:

    * ${FIRST_USER}@${FIRST_DOMAIN}
" 20 76 "${FIRST_USER}@${FIRST_DOMAIN}" 2>/tmp/mail_alias_root

MAIL_ALIAS_ROOT=$(cat /tmp/mail_alias_root)
echo "export MAIL_ALIAS_ROOT='${MAIL_ALIAS_ROOT}'" >> ${CONFIG_FILE}
rm -f /tmp/mail_alias_root

# Append EOF tag in config file.
echo "#EOF" >> ${CONFIG_FILE}

#
# Ending message.
#
cat <<EOF
Configuration completed.

*************************************************************************
***************************** WARNING ***********************************
*************************************************************************
*                                                                       *
* Please do remember to *REMOVE* configuration file after installation  *
* completed successfully.                                               *
*                                                                       *
*   * ${CONFIG_FILE}
*                                                                       *
*************************************************************************
EOF

ECHO_INFO -n "Continue? [Y|n]"
read ANSWER

case ${ANSWER} in
    N|n)
        ECHO_INFO "Canceled, Exit."
        exit 255
        ;;
    Y|y|*)
        :
        ;;
esac
