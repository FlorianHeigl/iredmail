#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# 'sort' will break in zh env.
export LC_ALL=C

grep 'helo=' /var/log/maillog | awk -F'helo=<' '{print $2}' | awk -F'>' '{print $1}' > /tmp/helo.all
sort /tmp/helo.all | uniq -c | sort -nr > /tmp/helo.count

