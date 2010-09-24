#!/usr/bin/env bash

# Filename: backup_mysql.sh
# Author:   Zhang Huangbin (zhb@iredmail.org)
# Date:     2007.09.16
# Purpose:  Backup specified mysql databases with command 'mysqldump'.
# License:  This shell script is part of iRedMail project, released under
#           GPL v2.

###########################
# REQUIREMENTS
###########################
#
#   * Required commands:
#       + mysqldump
#       + du
#       + bzip2 or gzip     # If bzip2 is not available, change 'CMD_COMPRESS'
#                           # to use 'gzip'.
#

###########################
# USAGE
###########################
#
#   * It stores all backup copies in directory '/backup' by default, you can
#     change it in variable $BACKUP_ROOTDIR below.
#
#   * Set correct values for below variables:
#
#       BACKUP_ROOTDIR
#       MYSQL_USER
#       MYSQL_PASSWD
#       DATABASES
#       DB_CHARACTER_SET
#       COMPRESS
#       DELETE_PLAIN_SQL_FILE
#
#   * Add crontab job for root user (or whatever user you want):
#
#       # crontab -e -u root
#       1   4   *   *   *   bash /path/to/backup_mysql.sh
#   
#   * Make sure 'crond' service is running, and will start automatically when
#     system startup:
#
#       # ---- On RHEL/CentOS ----
#       # chkconfig --level 345 crond on
#       # /etc/init.d/crond status
#
#       # ---- On Debian/Ubuntu ----
#       # update-rc.d cron defaults
#       # /etc/init.d/cron status
#

###########################
# DIRECTORY STRUCTURE
###########################
#
#   $BACKUP_ROOTDIR             # Default is /backup
#       |- mysql/               # Used to store all backed up databases.
#           |- YEAR.MONTH/
#               |- YEAR.MONTH.DAY/
#                   |- DB.YEAR.MONTH.DAY.MIN.HOUR.SECOND.sql
#                               # Backup copy, plain SQL file.
#                               # Note: it will be removed immediately after
#                               # it was compressed with success and 
#                               # DELETE_PLAIN_SQL_FILE='YES'
#
#                   |- DB.YEAR.MONTH.DAY.HOUR.MINUTE.SECOND.sql.bz2
#                               # Backup copy, compressed SQL file.
#
#       |- logs/
#           |- YEAR.MONTH/
#               |- mysql-YEAR.MONTH.DAY.MIN.HOUR.SECOND.log     # Log file
#

#########################################################
# Modify below variables to fit your need ----
#########################################################
# Where to store backup copies.
BACKUP_ROOTDIR='/backup'

# MySQL user and password.
MYSQL_USER='root'
MYSQL_PASSWD='root_password'

# Which database(s) we should backup. Multiple databases MUST be seperated by
# a SPACE.
DATABASES="mysql vmail policyd roundcubemail"

# Database character set for ALL databases.
# Note: Currently, it doesn't support to specify character set for each databases.
DB_CHARACTER_SET="utf8"

# Compress plain SQL file: YES, NO.
COMPRESS="YES"

# Delete plain SQL files after compressed. Compressed copy will be remained.
DELETE_PLAIN_SQL_FILE="YES"

#########################################################
# You do *NOT* need to modify below lines.
#########################################################
# Commands.
CMD_DATE='/bin/date'
CMD_DU='du -sh'
CMD_COMPRESS='bzip2 -9'
CMD_MYSQLDUMP='mysqldump'

# Date.
MONTH="$(${CMD_DATE} +%Y.%m)"
DAY="$(${CMD_DATE} +%Y.%m.%d)"
DATE="$(${CMD_DATE} +%Y.%m.%d.%H.%M.%S)"

# Define, check, create directories.
BACKUP_DIR="${BACKUP_ROOTDIR}/mysql/${MONTH}/${DAY}"

# Check and create directories.
[ -d ${BACKUP_DIR} ] || mkdir -p ${BACKUP_DIR} 2>/dev/null

# Logfile directory. Default is /backup/logs/YYYY.MM/.
LOG_DIR="${BACKUP_ROOTDIR}/logs/${MONTH}/"
[ -d ${LOG_DIR} ] || mkdir -p ${LOG_DIR} 2>/dev/null

# Log file. Default is /backup/logs/YYYY.MM/mysql-YYYY.MM.DD.log.
LOGFILE="${LOG_DIR}/mysql-${DATE}.log"

# Initialize log file.
echo "* Starting backup: ${DATE}." >${LOGFILE}
echo "* Log file: ${LOGFILE}." >>${LOGFILE}
echo "* Backup copies: ${BACKUP_DIR}." >>${LOGFILE}

backup_db()
{
    # USAGE:
    #  # backup dbname
    output_sql="${BACKUP_DIR}/${1}.${DATE}.sql"

    mysqldump \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWD} \
        --default-character-set=${DB_CHARACTER_SET} \
        $1 > ${output_sql}
}

# Backup.
for db in ${DATABASES}
do
        echo -n "* Backing up database: ${db}..." >>${LOGFILE}
        backup_db ${db} >>${LOGFILE} 2>&1
        echo -e "\tDone" >>${LOGFILE}
done

# Compress plain SQL file.
if [ X"${COMPRESS}" == X"YES" ]; then
    for sql_file in $(ls ${BACKUP_DIR}/*); do
        echo -n "* Compressing plain SQL file: ${sql_file}..." >>${LOGFILE}
        ${CMD_COMPRESS} ${sql_file} >>${LOGFILE} 2>&1

        if [ X"$?" == X"0" ]; then
            echo -e "\tDone" >>${LOGFILE}

            # Delete plain SQL file after compressed.
            if [ X"${DELETE_PLAIN_SQL_FILE}" == X"YES" -a -f ${sql_file} ]; then
                echo -n "* Removing plain SQL file: ${sql_file}..." >>${LOGFILE}
                rm -f ${BACKUP_DIR}/*sql >>${LOGFILE} 2>&1
                [ X"$?" == X"0" ] && echo -e "\tDone" >>${LOGFILE}
            fi
        fi
    done
fi

# Append file size of backup files.
echo "* File size:" >>${LOGFILE}
${CMD_DU} ${BACKUP_DIR}/* >>${LOGFILE}

echo "* Backup complete."
