#!/bin/sh

# Filename: get_helo_count.sh
# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>
# Date:     2008.10.24
# Version:  0.1
# Purpose:  Get HELO identified from maillog.
# Project:  iRedMail: Open Source Mail Server Solution for Red Hat
#           Enterprise Linux and CentOS 5.x.
#           - http://code.google.com/p/iredmail/
#           - http://www.iredmail.org/

# We suggest you send top 50 entries to mail address iredmail.helo@gmail.com
# to help iRedMail project reduce spam, all iRedMail users will get benefits
# from it.
# We suggest you send top 50 helo hostnames to mail address iredmail.helo@gmail.com
# via crontab job, it will help iRedMail project reduce spam, all iRedMail
# users will get benefits from it.
#
#    # wget http://iredmail.googlecode.com/svn/trunk/tools/get_helo_count.sh -O /root/get_helo_count.sh
#    # crontab -e -u root
#
#    1   4   *   *   *   /bin/sh /root/get_helo_count.sh | mail -s "HELO count" iredmail.helo@gmail.com
#
# It will run '/root/get_helo_count.sh' at 04:01 every day, and mail the top 50
# entries to iredmail.helo@gmail.com.

# 'sort' will break in zh env.
export LC_ALL=C

MAILLOG='/var/log/maillog'

grep 'helo=' ${MAILLOG} | grep 'postfix/smtpd' | awk '{print $1, $2, $6, $11, $NF}' | awk -F':' '{print $1,$2}' | awk -F'helo=<' '{print $1,$2}' | awk -F'>' '{print $1}' | sort | uniq -c | sort -nr
