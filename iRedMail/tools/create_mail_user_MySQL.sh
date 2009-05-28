#!/usr/bin/env bash

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
#       DEFAULT_PASSWD='888888'
#       USE_DEFAULT_PASSWD='NO'
#       DEFAULT_QUOTA='100'   # 100 -> 100M
#
#   * Run this script to generate SQL files used to import to MySQL
#     database later.
#
#       # sh create_mail_user_MySQL.sh domain.ltd user [user1 user2 user3 ...]
#
#     It will generate file 'output.sql' in current directory, open
#     it and confirm all records are correct.
#
#   * Import output.sql into MySQL database.
#
#       # mysql -uroot -p
#       mysql> USE vmail;
#       mysql> SOURCE /path/to/output.sql;
#
#   That's all.
# -------------------------------------------------------------------

# ChangeLog:
#   - Improve file detect.
#   - Drop output message of 'which dos2unix'.

# --------- CHANGE THESE VALUES ----------
# Password setting.
# Note: password will be crypted in MD5.
DEFAULT_PASSWD='88888888'
USE_DEFAULT_PASSWD='NO'     # If set to 'NO', password is the same as username.

# Default mail quota.
DEFAULT_QUOTA='100'   # 100 -> 100M

# -------------- You may not need to change variables below -------------------
# Mailbox format: mbox, Maildir.
MAILBOX_FORMAT='Maildir'

# Time stamp, will be appended in maildir.
DATE="$(date +%Y.%m.%d.%H.%M.%S)"

# Path to SQL template file.
SQL="output.sql"
echo '' > ${SQL}

# Cyrpt the password.
if [ X"${USE_DEFAULT_PASSWD}" == X"YES" ]; then
    export CRYPT_PASSWD="$(openssl passwd -1 ${DEFAULT_PASSWD})"
else
    :
fi

generate_sql()
{
    # Get domain name.
    DOMAIN="$1"
    shift 1

    for i in $@; do
        username="$i"

        if [ X"${USE_DEFAULT_PASSWD}" != X"YES" ]; then
            export CRYPT_PASSWD="$(openssl passwd -1 ${username})"
        else
            :
        fi

        # Different maildir format: maildir, mbox.
        if [ X"${MAILBOX_FORMAT}" == X"Maildir" ]; then
            maildir="${DOMAIN}/${username}-${DATE}/"
        else
            maildir="${DOMAIN}/${username}-${DATE}"
        fi

        cat >> ${SQL} <<EOF
INSERT INTO mailbox (username, password, name, maildir, quota, domain, active)
    VALUES ('${username}@${DOMAIN}', '${CRYPT_PASSWD}', '${username}', '${maildir}', '${DEFAULT_QUOTA}', '${DOMAIN}', '1');
EOF
        # Don't insert alias.
        #INSERT INTO alias (address, goto, domain, active)
        #    VALUES ('${username}@${DOMAIN}', '${username}@${DOMAIN}', '${DOMAIN}', '1');
    done
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 domain_name username [user2 user3 user4 ...]"
else
    # Generate SQL template.
    generate_sql $@ && \
    cat <<EOF

SQL template file was generated successfully, Please import it
*MANUALLY* after verify the records:

    - ${SQL}

Steps to import these users looks like below:

    # mysql -uroot -p
    mysql> USE vmail;
    mysql> SOURCE ${SQL};

EOF
fi
