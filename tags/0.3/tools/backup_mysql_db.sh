#!/bin/sh

# Filename: backup_mysql_db.sh
# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Date:     2007.09.16
# Purpose:  Backup specified mysql databases.

# Copyright:
#
# This shell script is shipped within iRedMail project, released under
# GPL v2.
# ----

# Usage:
#   * Add crontab job for whichever user, such as root:
#
#       # crontab -e -u root
#       1   4   *   *   *   /bin/sh /path/to/backup_mysql_db.sh
#   
#   * Make sure 'crond' service is running when system startup:
#
#       # chkconfig --level 345 crond on
# ----

# -----------------------------------------------------------------
# ---- Modify below variables to suit your need ----
# -----------------------------------------------------------------
# Where to store backup copies.
BACKUP_ROOTDIR='/backup/mysql/'

# MySQL user and password.
MYSQL_USER='root'
MYSQL_PASSWD='root_password'

# Which database(s) we should backup.
DATABASES="mysql vmail policyd roundcubemail"

# Database character set.
DB_CHARACTER_SET="utf8"

# Compress: YES | NO.
COMPRESS="YES"

# Delete plain SQL file after compressed. Compressed copy will be
# remained.
DELETE_PLAIN_SQL_FILE="YES"

# -----------------------------------------------------------------
# ---- You do *NOT* need to modify below lines. ----
# -----------------------------------------------------------------
MONTH="$(/bin/date +%Y.%m)"
DATE="$(/bin/date +%Y.%m.%d)"

BACKUP_DIR="${BACKUP_ROOTDIR}/db/${DATE}"

# Check necessery directory.
[ -d ${BACKUP_DIR} ] || mkdir -p ${BACKUP_DIR}

# Logfile directory.
LOG_DIR="${BACKUP_ROOTDIR}/logs/${MONTH}/"
[ -d ${LOG_DIR} ] || mkdir -p ${LOG_DIR}

LOGFILE="${LOG_DIR}/backup-mysql-${DATE}.log"

# create and init log file.
echo -e "\nLog init at: ${DATE}." >${LOGFILE}
echo "Operator: Michael Bibby(michaelbibby@gmail.com)." >>${LOGFILE}
# ---- End log ----

backup_db()
{
        # USAGE:
        # backup dbname
        output_sql="${BACKUP_DIR}/${1}-${DATE}.sql"

        mysqldump \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWD} \
        --default-character-set=${DB_CHARACTER_SET} \
        $1 > ${output_sql}
}

# Backup.
for i in ${DATABASES}
do
        echo -n "Backup database: $i..." >> ${LOGFILE}
        backup_db $i
        echo -e "\tDone" >>${LOGFILE}
done

# Compress plain SQL file.
if [ X"${COMPRESS}" == X"YES" ]; then
    for i in $(ls ${BACKUP_DIR}/*)
    do
        echo -n "Compress: $i..." >>${LOGFILE}
        bzip2 $i
        echo -e "\tDone" >>${LOGFILE}
    done
else
    :
fi

# Size of the backup file.
du -sh ${BACKUP_DIR}/* >>${LOGFILE}

# Delete plain SQL file after compressed.
if [ X"${DELETE_PLAIN_SQL_FILE}" == X"YES" ]; then
    rm -f ${BACKUP_DIR}/*sql 
else
    :
fi
