#!/bin/sh

# Filename: dovecot-quota-warning.sh
# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>
# Date:     2008.10.28
# Version:  0.1
# Purpose:  Send mail to notify user when his mailbox quota exceeds a
#           specified limit.
# Project:  iRedMail: Open Source Mail Server Solution for Red Hat
#           Enterprise Linux and CentOS 5.x.
#           - http://code.google.com/p/iredmail/
#           - http://www.iredmail.org/

PERCENT=$1

cat << EOF | /usr/libexec/dovecot/deliver -d ${USER} -c /etc/dovecot.conf
From: postmaster@iredmail.org
Subject: Mailbox Quota Warning: ${PERCENT}% Full.

Mailbox quota report:

    * Your mailbox is now ${PERCENT}% full, please clear some files for
      further mails.

EOF
