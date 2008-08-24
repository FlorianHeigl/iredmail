#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# 'sort' will break in zh env.
export LC_ALL=C

grep 'helo=' /var/log/maillog | awk -F'helo=<' '{print $2}' | awk -F'>' '{print $1}' > helo.all.iredmail
sort helo.all.iredmail | uniq -c | sort -nr > helo.count.iredmail
rm -f helo.all.iredmail

