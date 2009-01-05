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

# 'sort' will break in zh env.
export LC_ALL=C

MAILLOG='/var/log/maillog'
OUTPUT='helo.count.iredmail'

grep 'helo=' ${MAILLOG} | awk -F'helo=<' '{print $2}' | awk -F'>' '{print $1}' > helo.all.iredmail
sort helo.all.iredmail | uniq -c | sort -nr > ${OUTPUT}
rm -f helo.all.iredmail

echo "Please check result file: ${OUTPUT}."

