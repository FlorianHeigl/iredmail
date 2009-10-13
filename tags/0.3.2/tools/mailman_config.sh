#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# ------------------------------------
# Mailman related configuration.
# ------------------------------------
${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "First Mailing List in Mailman" \
    --inputbox "\
Please specify the name of your first mailing list for your
virtual domain:

    * ${FIRST_DOMAIN}

The email address of this mailing list will looks like:

    * all@${FIRST_DOMAIN}

EXAMPLE:

    * all

" 20 76 "all" 2>/tmp/first_mailing_list_name

FIRST_MAILING_LIST_NAME="$(cat /tmp/first_mailing_list_name)"
rm -f /tmp/first_mailing_list_name
echo "export FIRST_MAILING_LIST_NAME='${FIRST_MAILING_LIST_NAME}'" >> ${CONFIG_FILE}

${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "The Person running the list: ${FIRST_MAILING_LIST_NAME}" \
    --inputbox "\
Please specify the *E-Mail* address of the person running the list:

    * ${FIRST_MAILING_LIST_NAME}

EXAMPLE:

    * michaelbibby@gmail.com
" 20 76 "root@${HOSTNAME}" 2>/tmp/first_mailing_list_owner

FIRST_MAILING_LIST_OWNER="$(cat /tmp/first_mailing_list_owner)"
rm -f /tmp/first_mailing_list_owner
echo "export FIRST_MAILING_LIST_OWNER='${FIRST_MAILING_LIST_OWNER}'" >> ${CONFIG_FILE}

while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Password for LDAP rootdn: ${LDAP_ROOTDN}" \
    --insecure --passwordbox "\
Please specify password for the person runing 'mailman' list:

    * ${FIRST_MAILING_LIST_OWNER}

Warnning:

    * EMPTY password is *NOT* permit.
" 20 76 2>/tmp/mailman_running_person_passwd

    FIRST_MAILING_LIST_OWNER_PASSWD="$(cat /tmp/mailman_running_person_passwd)"
    if [ ! -z "${FIRST_MAILING_LIST_OWNER_PASSWD}" ]; then
        break
    fi
done

rm -f /tmp/mailman_running_person_passwd
echo "export FIRST_MAILING_LIST_OWNER_PASSWD='${FIRST_MAILING_LIST_OWNER_PASSWD}'" >> ${CONFIG_FILE}
