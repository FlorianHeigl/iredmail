#!/bin/sh

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)
# Date: 2008.03.29
# Purpose: Collect some log files and configuration files for rhms error 
#          analytic.

# Collect all ${ALL_FILES} to this directory.
COLLDIR="/tmp/rhms_sysreport/"
[ -d ${COLLDIR} ] || mkdir -p ${COLLDIR}
rm -rf ${COLLDIR}/*

# Compress and tar them.
TARBALL='/tmp/rhms_sysreport.tar.bz2'
rm -f ${TARBALL}

SERVICES='amavisd clamd dovecot freshclam httpd iptables ldap mailgraph postfix postgrey saslauthd spamassassin syslog'

# Which files we should collect.
FIREWALL='/etc/selinux/config
/etc/sysconfig/iptables
'

OPENLDAP='/etc/openldap/schema/rhms.schema
/etc/openldap/slapd.conf
/etc/openldap/ldap.conf
/var/log/openldap.log
'

POSTFIX='/etc/postfix/
/var/log/maillog
/usr/lib/sasl2/smtpd.conf
'

DOVECOT='/etc/dovecot.conf
/etc/dovecot-*.conf
/var/log/dovecot.log
/var/log/sieve.log
/home/vmail/.dovecot.sieve
'

CLAMAV='/etc/clamd.conf
/etc/freshclam.conf
/var/log/clamav/clamd.log
/var/log/clamav/freshclam.log
'

MISC='/etc/amavisd.conf
/etc/sysconfig/saslauthd
'

# Do not modify it unless you add new categories.
ALL_FILES="${FIREWALL} ${OPENLDAP} ${POSTFIX} ${DOVECOT} ${CLAMAV} ${MISC}"

# Function for file collection.
collectit()
{
    # $1 -> source_file or source_dir
    # $2 -> destination_dir

    if [ "$#" -ge 2 ]; then
        cp -rf $1 $2 2>/dev/null
    else [ "$#" -lt 2 ]
        echo "Usage: collectit [SOURCE_FILE | SOURCE_DIR] DESTINATION_DIR"
    fi
}

# Copy all files we need.
echo -n " * Copying files and directories..."
for i in ${ALL_FILES}; do
    collectit ${i} ${COLLDIR}
done
echo -e "\tDone."

# Check services status.
status_file="${COLLDIR}/services_status"
> ${status_file}

echo -n " * Checking services status..."
for i in ${SERVICES}; do
    /etc/init.d/$i status >>${status_file} 2>&1
done
echo -e "\tDone."

# Compress.
echo -n " * Generating tarball: ${TARBALL}"
tar cjvf ${TARBALL} ${COLLDIR} >/dev/null 2>&1
SIZE="$(du -sh ${TARBALL} | awk '{print $1}')"
echo -n "(${SIZE})..."
echo -e "\tDone."
