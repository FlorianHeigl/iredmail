#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# Please refer another file: functions/backend.sh

# -------------------------------------------------------
# -------------------- MySQL ----------------------------
# -------------------------------------------------------
mysql_initialize()
{
    ECHO_INFO "==================== MySQL ===================="

    ECHO_INFO "Starting MySQL."
    ${MYSQLD_INIT_SCRIPT} restart >/dev/null

    ECHO_INFO -n "Sleep 5 seconds for MySQL daemon initialize:"
    for i in $(seq 5 -1 1); do
        echo -n " ${i}s" && sleep 1
    done
    echo '.'

    echo '' > ${MYSQL_INIT_SQL}

    if [ X"${MYSQL_FRESH_INSTALLATION}" == X"YES" ]; then
        ECHO_INFO "Setting MySQL admin's password: ${MYSQL_ROOT_USER}."
        mysqladmin -u root password "${MYSQL_ROOT_PASSWD}"

        cat >> ${MYSQL_INIT_SQL} <<EOF
/* Delete empty username. */
USE mysql;

DELETE FROM user WHERE User='';
DELETE FROM db WHERE User='';
EOF
    else
        :
    fi

    ECHO_INFO "Initialize MySQL database."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
SOURCE ${MYSQL_INIT_SQL};
FLUSH PRIVILEGES;
EOF

    cat >> ${TIP_FILE} <<EOF
MySQL:
    * Data directory:
        - /var/lib/mysql
    * RC script:
        - ${MYSQLD_INIT_SCRIPT}
    * Log file:
        - /var/log/mysqld.log
    * SSL Cert keys:
        - ${SSL_CERT_FILE}
        - ${SSL_KEY_FILE}
    * See also:
        - ${MYSQL_INIT_SQL}

EOF

    echo 'export status_mysql_initialize="DONE"' >> ${STATUS_FILE}
}

# It's used only when backend is MySQL.
mysql_import_vmail_users()
{
    ECHO_INFO "Generating SQL template for postfix virtual hosts: ${MYSQL_VMAIL_SQL}."
    export DOMAIN_ADMIN_PASSWD="$(openssl passwd -1 ${DOMAIN_ADMIN_PASSWD})"
    export FIRST_USER_PASSWD="$(openssl passwd -1 ${FIRST_USER_PASSWD})"

    # Generate SQL.
    # Mailbox format is 'Maildir/' by default.
    cat >> ${MYSQL_VMAIL_SQL} <<EOF
/* Create database for virtual hosts. */
CREATE DATABASE IF NOT EXISTS ${VMAIL_DB} CHARACTER SET utf8;

/* Permissions. */
GRANT SELECT ON ${VMAIL_DB}.* TO ${MYSQL_BIND_USER}@localhost IDENTIFIED BY "${MYSQL_BIND_PW}";
GRANT SELECT,INSERT,DELETE,UPDATE ON ${VMAIL_DB}.* TO ${MYSQL_ADMIN_USER}@localhost IDENTIFIED BY "${MYSQL_ADMIN_PW}";

/* Initialize the database. */
USE ${VMAIL_DB};
SOURCE ${SAMPLE_SQL};

/* Add your first domain. */
INSERT INTO domain (domain,transport) VALUES ("${FIRST_DOMAIN}", "${TRANSPORT}");

/* Add your first domain admin. */
INSERT INTO admin (username,password,created) VALUES ("${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${DOMAIN_ADMIN_PASSWD}", NOW());
INSERT INTO domain_admins (username,domain,created) VALUES ("${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${FIRST_DOMAIN}", NOW());

/* Add domain admin. */
/*
INSERT INTO mailbox (username,password,name,maildir,quota,domain,created) VALUES ("${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${DOMAIN_ADMIN_PASSWD}","${DOMAIN_ADMIN_NAME}","${FIRST_DOMAIN}/${DOMAIN_ADMIN_NAME}/",0, "${FIRST_DOMAIN}",NOW());
INSERT INTO alias (address,goto,domain,created) VALUES ("${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}", "${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}", "${FIRST_DOMAIN}", NOW());
*/

/* Add your first normal user. */
INSERT INTO mailbox (username,password,name,storagebasedirectory,maildir,quota,domain,created) VALUES ("${FIRST_USER}@${FIRST_DOMAIN}","${FIRST_USER_PASSWD}","${FIRST_USER}","${VMAIL_USER_HOME_DIR}","$( hash_domain ${FIRST_DOMAIN})/$( hash_maildir ${FIRST_USER} )",100, "${FIRST_DOMAIN}", NOW());
INSERT INTO alias (address,goto,domain,created) VALUES ("${FIRST_USER}@${FIRST_DOMAIN}", "${FIRST_USER}@${FIRST_DOMAIN}", "${FIRST_DOMAIN}", NOW());
EOF

    ECHO_INFO -n "Import postfix virtual hosts/users: ${MYSQL_VMAIL_SQL}."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
SOURCE ${MYSQL_VMAIL_SQL};
FLUSH PRIVILEGES;
EOF

    if [ X"$?" == X"0" ]; then
        echo -e "\t\t[ OK ]"
    else
        echo -e "\t\t[ FAILED ]"
    fi

    cat >> ${TIP_FILE} <<EOF
Virtual Users:
    - ${MYSQL_VMAIL_SQL}
    - ${SAMPLE_SQL}

EOF

    echo 'export status_mysql_import_vmail_users="DONE"' >> ${STATUS_FILE}
}
