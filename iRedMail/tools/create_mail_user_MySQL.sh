#!/bin/sh

# -------------------------------------------------------------------
# Filename: create_mail_user_MySQL.sh
# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Lastest update date:     2008.10.24
# Purpose:  Import users to MySQL database from plain text file.
# Project:  iRedMail (http://code.google.com/p/iredmail/)
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Usage:
#   * Edit these variables:
#       DOMAIN='iredmail.org'
#       DEFAULT_PASSWD='888888'
#       USE_DEFAULT_PASSWD='NO'
#       USE_NAME_AS_PASSWD='YES'
#       DEFAULT_QUOTA='100'   # 100 -> 100M
#   * Prepare your user list file, such as 'userlist.txt'. One name
#     per line, without domain name. e.g.:
#
#       user1
#       user2
#       user3
#
#   * Run this script to generate SQL files used to import to MySQL
#     database later.
#
#       # sh create_mail_user_MySQL.sh userlist.txt
#
#     It will generate file 'output.sql' in current directory, open
#     it and confirm all records are correct.
#
#   * Import output.sql into MySQL database.
#
#       # mysql -uroot -p vmail
#       mysql> SOURCE /path/to/output.sql;
#
#   That's all.
# -------------------------------------------------------------------

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
DOMAIN='iredmail.org'
DEFAULT_PASSWD='888888'
USE_DEFAULT_PASSWD='NO'
USE_NAME_AS_PASSWD='YES'
DEFAULT_QUOTA='100'   # 100 -> 100M

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
EOF
        # Don't insert alias.
        #INSERT INTO alias (address, goto, domain, active)
        #    VALUES ('${username}@${DOMAIN}', '${username}@${DOMAIN}', '${DOMAIN}', '1');
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
