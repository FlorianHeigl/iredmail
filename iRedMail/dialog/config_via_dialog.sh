#!/bin/bash

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)

# Note: config file will be sourced in 'conf/functions', check_env().

. ./conf/global
. ./conf/functions

trap "exit 255" 2

# Initialize config file.
echo '' > ${CONFIG_FILE}

DIALOG='dialog --colors --no-collapse --insecure --ok-label Next --no-cancel'
DIALOG_BACKTITLE="${PROG_NAME}: Open Source Mail Server Solution for RHEL/CentOS/Debian/Ubuntu."

# Welcome message.
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Welcome and thanks for use" \
    --yesno "\
Thanks for your use of ${PROG_NAME}.
Bug report, feedback, suggestion are always welcome.

Contact author via mail: \Zb\Z2michaelbibby@gmail.com\Zn
Community: \Zb\Z2http://www.iredmail.org/forum/\Zn

NOTE:

    \Zb\Z1Ctrl-C will abort this wizard.\Zn
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

    * \Zb\Z1All mails will be stored in this HOME directory\Zn, so it may take
      large disk space.
" 20 76 "${VMAIL_USER_HOME_DIR}" 2>/tmp/vmail_user_home_dir

VMAIL_USER_HOME_DIR="$(cat /tmp/vmail_user_home_dir)"
export VMAIL_USER_HOME_DIR="${VMAIL_USER_HOME_DIR}" && echo "export VMAIL_USER_HOME_DIR='${VMAIL_USER_HOME_DIR}'" >>${CONFIG_FILE}
rm -f /tmp/vmail_user_home_dir

# --------------------------------------------------
# --------------------- Backend --------------------
# --------------------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Choose your \Zb\Z2prefer backend\Zn" \
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
    --title "Specify \Zb\Z2mail alias\Zn for 'root' user" \
    --inputbox "\
Please specify an \Zb\Z2E-Mail\Zn address for 'root' user alias.

\Zb\Z1Mail deliver failure notice and other system notify mails will be
send to this alias address instead of system account 'root'.\Zn

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
* Please do remember to *MOVE* configuration file after installation    *
* completed successfully.                                               *
*                                                                       *
*   * \Zb\Z2${CONFIG_FILE}\Zn
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
