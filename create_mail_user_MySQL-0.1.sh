#!/bin/sh

# Filename: create_mail_user_MySQL.sh
# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Date:     2008.10.24
# Version:  0.1
# Purpose:  Import users from plain text file: one name, one line.
#           e.g.:
#
#           userA
#           userB
#           userC
#
# Project:  iRedMail: Open Source Mail Server Solution for Red Hat
#           Enterprise Linux and CentOS 5.x.
#           - http://code.google.com/p/iredmail/
#           - http://www.iredmail.org/

# ChangeLog:
#   - Improve file detect.
#   - Drop output message of 'which dos2unix'.

# Mailbox format: mbox, Maildir.
HOME_MAILBOX='Maildir'

# Maildir format.
# YES:  domain.ltd/username/Maildir/
# No:   domain.ltd/username/
MAILDIR_IN_MAILBOX='NO'
MAILDIR_STRING='Maildir/'

# You domain name.
DOMAIN='example.com'
DEFAULT_PASSWD='888888'
USE_DEFAULT_PASSWD='NO'
DEFAULT_QUOTA='10'   # 10 -> 10M

# SQL file.
SQL="./output.sql"
echo '' > ${SQL}

generate_sql()
{
    while read username
    do
        # Cyrpt the password.
        if [ X"${USE_DEFAULT_PASSWD}" == X"YES" ]; then
            CRYPT_PASSWD="$(openssl passwd -1 ${DEFAULT_PASSWD})"
        else
            CRYPT_PASSWD="$(openssl passwd -1 ${username})"
        fi

        # For maildir format.
        if [ X"${MAILDIR_IN_MAILBOX}" == X"YES" ]; then
            [ X"${HOME_MAILBOX}" == X"Maildir" ] && maildir="${DOMAIN}/${username}/${MAILDIR_STRING}/"
        else
            [ X"${HOME_MAILBOX}" == X"Maildir" ] && maildir="${DOMAIN}/${username}/"
        fi

        # For mbox.
        [ X"${HOME_MAILBOX}" == X"mbox" ] && maildir="${DOMAIN}/${username}"

        echo $username | grep '^#' >/dev/null
        if [ X"$?" != X"0" ]; then
            cat >> ${SQL} <<EOF
INSERT INTO mailbox (username, password, name, maildir, quota, domain, active)
    VALUES ('${username}@${DOMAIN}', '${CRYPT_PASSWD}', '${username}', '${maildir}', '${DEFAULT_QUOTA}', '${DOMAIN}', '1');
INSERT INTO alias (address, goto, domain, active)
    VALUES ('${username}@${DOMAIN}', '${username}@${DOMAIN}', '${DOMAIN}', '1');
EOF
        else
            :
        fi
    done < $1
}

if [ X"$#" == X"1" ]; then
    if [ -f $1 ]; then
        userlist="$1"

        # Use 'dos2unix' to convert file format.
        which dos2unix >/dev/null 2>&1
        [ X"$?" == X"0" ] && dos2unix ${userlist}

        # Generate SQL template.
        generate_sql ${userlist} && \
        cat <<EOF
Please import SQL file *MANUALLY* after verify the records:

    - ${SQL}

EOF
    else
        echo "Error: file does *NOT* exist: $1."
    fi
else
    echo "Usage: sh $0 userlist.txt"
fi
