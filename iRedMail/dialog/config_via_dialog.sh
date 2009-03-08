#!/bin/sh

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)

# Note: config file will be sourced in 'conf/functions', check_env().

. ./conf/global
. ./conf/functions

trap "exit 255" 2

check_arch

# Initialize config file.
echo '' > ${CONFIG_FILE}

DIALOG='dialog --no-collapse'
DIALOG_BACKTITLE="${PROG_NAME}: Mail Server Installation Wizard for RHEL/CentOS 5.x"

# Welcome message.
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Welcome and thanks for use" \
    --msgbox "\
Thanks for your use of ${PROG_NAME}.
Feedback, bug report, communication are all welcome.

Contact me if you need help for ${PROG_NAME} or RHEL/CentOS:

    * Author:   Zhang Huangbin
    * Mail:     michaelbibby (at) gmail.com

NOTE:

    Ctrl-C will abort this wizard.
" 20 76

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

    +--------------------+---------------+--------------+
    | Backend            | Web Mail      | Admin tool   |
    +--------------------+---------------+--------------+
    | MySQL(Recommended) | RoundcubeMail | PostfixAdmin |
    +--------------------+---------------+--------------+
    | OpenLDAP           | SquirrelMail  | phpLDAPadmin |
    +--------------------+---------------+--------------+

TIP:
    * Use 'Space' key to select item.

" 20 76 2 \
    "MySQL" "The world's most popular open source database." "on" \
    "OpenLDAP" "An open source implementation of LDAP protocol. " "off" \
    2>/tmp/backend

BACKEND="$(cat /tmp/backend)"
echo "export BACKEND='${BACKEND}'" >> ${CONFIG_FILE}
rm -f /tmp/backend

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    . ${DIALOG_DIR}/ldap_config.sh
elif [ X"${BACKEND}" == X"MySQL" ]; then
    . ${DIALOG_DIR}/mysql_config.sh
else
    :
fi

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

    * michaelbibby@gmail.com
" 20 76 2>/tmp/mail_alias_root

MAIL_ALIAS_ROOT=$(cat /tmp/mail_alias_root)
rm -f /tmp/mail_alias_root
echo "export MAIL_ALIAS_ROOT='${MAIL_ALIAS_ROOT}'" >> ${CONFIG_FILE}

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

echo -en "\n${OUTPUT_FLAG} Continue? [Y|n]"
read ANSWER

case ${ANSWER} in
    N|n)
        echo "${OUTPUT_FLAG} Canceled, Exit."
        exit 255
        ;;
    Y|y|*)
        :
        ;;
esac
