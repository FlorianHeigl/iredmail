#!/bin/sh

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)

# Purpose: Import users from a plain text file.
# Plain text file format: one name, one line. e.g.
# -----------------------
# userA
# userB
# userC
# -----------------------

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
DEFAULT_QUOTA='10240'   # 10240 -> 10M (10240/1024)

# Cyrpt the password.
CRYPT_PASSWD="$(openssl passwd -1 ${DEFAULT_PASSWD})"

# SQL file.
SQL="./output.sql"
echo '' > ${SQL}

generate_sql()
{
    while read username
    do
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

if [ -f $1 ]; then
    userlist="$1"

    # Use 'dos2unix' convert file format.
    which dos2unix
    [ X"$?" == X"0" ] && dos2unix ${userlist}

    # Create SQL template.
    generate_sql ${userlist} && \
    echo "Please import SQL file manually after you verify the data is correct:"
    echo "${SQL}"
else
    echo "Usage: sh $0 userlist.txt"
fi
