#!/bin/sh

# Filename: backup_iRedMail.sh
# Author:   Zhang Huangbin (michaelbibby@gmail.com)
# Purpose:  Backup all mail server related software configure files.
# Project:  Open Source Mail Server Solution for Red Hat Enterprise 
#           Linux and CentOS 5.x:
#           http://code.google.com/p/iredmail/

# -------------------------------------------------------------------
# --------------------------- USAGE ---------------------------------
# -------------------------------------------------------------------
# Run this script as root user:
#
#   # sh backup_iRedMail.sh
#
# It will collect mail server related configuration files and other
# stuffs and compress them as a tarball under /root/ by default.
# ------------------------------------------------------------------

# Last update:  2008.10.23
# ChangeLog:
#   - 08.10.27: Add directory: /var/lib/dovecot/. It maybe contains bdb
#               database of plugin expire.

export BACKUP_DIR='/root'
export DATE="$(/bin/date +%Y.%m.%d_%H.%M.%S)"
export BACKUP_TARBALL="${BACKUP_DIR}/iRedMail_Backup-${DATE}.tar"
export COMPRESSED='YES'
export COMPRESS_CMD='bzip2 -9'

check_user()
{
    # Check special user privilege to execute this script.
    if [ X"$(id -u)" != X"$(id -u ${1})" ]; then
        ECHO_INFO "Please run this script as user: ${1}."
        exit 255
    else
        :
    fi
}

# Function for file collection.
collectit()
{
    # $1 -> Tar file or tape device
    # $2, $3, $4, ... -> File(s) to append

    if [ "$#" -ge 2 ]; then
        tarfile="$1"
        shift 1
        tar rfp ${tarfile} $@ 2>/dev/null
    else [ "$#" -lt 2 ]
        echo "Usage: collectit <tar file or tape device> <file_to_append>"
    fi
}

# Which files we should collect.
FIREWALL='/etc/selinux/config
/etc/sysconfig/iptables
'

HTTPD="/etc/httpd/
/etc/logrotate.d/httpd
/etc/rc.d/init.d/httpd
/etc/sysconfig/httpd
"

PHP="/etc/php.ini"

OPENLDAP="/etc/openldap/
/etc/rc.d/init.d/ldap*
"

MYSQL="/etc/my.cnf*
/etc/rc.d/init.d/mysqld
"

POSTFIX="/etc/postfix/
/etc/rc.d/init.d/postfix
/etc/pam.d/smtp.postfix
/usr/lib/sasl2/smtpd.conf*
/usr/lib64/sasl2/smtpd.conf*
"

DOVECOT="/etc/dovecot*.conf*
/etc/logrotate.d/dovecot
/etc/rc.d/init.d/dovecot
/home/vmail/.dovecot.sieve
/var/lib/dovecot/
/var/www/sieve/
"

CLAMAV="/etc/clamd.conf
/etc/freshclam.conf
/etc/logrotate.d/clamav
/etc/logrotate.d/freshclam
/etc/cron.daily/freshclam
/etc/rc.d/init.d/clamd
/etc/rc.d/init.d/freshclam
"

AMAVISD='/etc/amavisd.conf
/etc/cron.daily/amavisd
/etc/logrotate.d/amavisd
/etc/sysconfig/amavisd
/etc/rc.d/init.d/amavisd
/var/lib/dkim/
/var/amavis/
/var/virusmails/
'

SPAMASSASSIN="/etc/mail/spamassassin/
"

PYSIEVED="/etc/pysieved.ini*
/etc/xinetd.d/pysieved
"

MISC="/etc/syslog.conf
/etc/sysctl.conf
/etc/sysconfig/network
/etc/sysconfig/network-scripts/ifcfg-eth*
/etc/sysconfig/saslauthd
/etc/pki/iRedMail*
"

# Do not modify it unless you add new categories.
ALL_FILES="${FIREWALL} ${HTTPD} ${PHP} ${OPENLDAP} ${MYSQL} ${POSTFIX}
${DOVECOT} ${CLAMAV} ${AMAVISD} ${SPAMASSASSIN} ${PYSIEVED} ${MISC}"

# Check user.
check_user root

# Create BACKUP_DIR.
[ -d ${BACKUP_DIR} ] || mkdir -p ${BACKUP_DIR}

# Copy all files we need.
echo -n " * Backup files and directories..."
collectit ${BACKUP_TARBALL} ${ALL_FILES}
echo -e "\tDone."

# Compress.
if [ X"${COMPRESSED}" == X"YES" ]; then
    echo -n " * Compress tarball: ${BACKUP_TARBALL}"
    ${COMPRESS_CMD} ${BACKUP_TARBALL}
    echo -e "\tDone."
else
    :
fi

cat <<EOF

********************************************************************
*************************** WARNING ********************************
********************************************************************
Script does *NOT* backup below files/data, please do it *MANUALLY*.

    - MySQL databases (Default: /var/lib/mysql).
    - Users' mailboxes (Default: /home/vmail).
    - Postfix queues (Default: /var/spool/postfix).

EOF
