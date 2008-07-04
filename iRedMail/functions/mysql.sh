# -------------------------------------------------------
# -------------------- MySQL ----------------------------
# -------------------------------------------------------
mysql_initialize()
{
    ECHO_INFO "Starting MySQL."
    /etc/init.d/mysqld restart >/dev/null

    ECHO_INFO -n "Sleep 5 seconds for MySQL daemon initialize:"
    for i in $(seq 5 -1 1); do
        echo -n " ${i}s" && sleep 1
    done
    echo '.'

    echo '' > ${MYSQL_INIT_SQL}

    if [ X"${MYSQL_FRESH_INSTALLATION}" == X"YES" ]; then
        ECHO_INFO "Setting MySQL admin's password: ${MYSQL_ROOT_USER}."
        /usr/bin/mysqladmin -u root password "${MYSQL_ROOT_PASSWD}"

        cat >> ${MYSQL_INIT_SQL} <<EOF
/* Drop database 'test'. */
DROP DATABASE test;

/* Delete empty username. */
USE mysql;

DELETE FROM user WHERE User='';
DELETE FROM db WHERE User='';
EOF
    else
        :
    fi

    ECHO_INFO "Generating SQL template for postfix virtual hosts: ${MYSQL_INIT_SQL}."
    export FIRST_DOMAIN_ADMIN_PASSWD="$(openssl passwd -1 ${FIRST_DOMAIN_ADMIN_PASSWD})"
    export FIRST_USER_PASSWD="$(openssl passwd -1 ${FIRST_USER_PASSWD})"

    # Generate SQL.
    # Mailbox format is 'Maildir/' by default.
    cat >> ${MYSQL_INIT_SQL} <<EOF
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
INSERT INTO admin (username,password,created) VALUES ("${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${FIRST_DOMAIN_ADMIN_PASSWD}", NOW());
INSERT INTO domain_admins (username,domain,created) VALUES ("${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${FIRST_DOMAIN}", NOW());

/* Add domain admin. */
INSERT INTO mailbox (username,password,maildir,quota,domain,created) VALUES ("${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}","${FIRST_DOMAIN_ADMIN_PASSWD}","${FIRST_DOMAIN}/${FIRST_DOMAIN_ADMIN_NAME}/",0, "${FIRST_DOMAIN}",NOW());
INSERT INTO alias (address,goto,domain,created) VALUES ("${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}", "${FIRST_DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}", "${FIRST_DOMAIN}", NOW());

/* Add your first user. */
INSERT INTO mailbox (username,password,maildir,quota,domain,created) VALUES ("${FIRST_USER}@${FIRST_DOMAIN}","${FIRST_USER_PASSWD}","${FIRST_DOMAIN}/${FIRST_USER}/",10, "${FIRST_DOMAIN}", NOW());
INSERT INTO alias (address,goto,domain,created) VALUES ("${FIRST_USER}@${FIRST_DOMAIN}", "${FIRST_USER}@${FIRST_DOMAIN}", "${FIRST_DOMAIN}", NOW());
EOF

    # Maildir format.
    export FIRST_DOMAIN
    export FIRST_DOMAIN_ADMIN_NAME
    export FIRST_USER
    [ X"${HOME_MAILBOX}" == X"mbox" ] && perl -pi -e 's#(.*$ENV{FIRST_DOMAIN}/$ENV{FIRST_DOMAIN_ADMIN_NAME})/(.*)#${1}${2}#' ${MYSQL_INIT_SQL}
    [ X"${HOME_MAILBOX}" == X"mbox" ] && perl -pi -e 's#(.*$ENV{FIRST_DOMAIN}/$ENV{FIRST_USER})/(.*)#${1}${2}#' ${MYSQL_INIT_SQL}

    ECHO_INFO -n "Import postfix virtual hosts/users: ${MYSQL_INIT_SQL}."
    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
SOURCE ${MYSQL_INIT_SQL};
FLUSH PRIVILEGES;
EOF

    if [ X"$?" == X"0" ]; then
        echo -e "\t\t[ OK ]"
    else
        echo -e "\t\t[ FAILED ]"
    fi

    cat >> ${TIP_FILE} <<EOF
MySQL:
    * Data directory:
        - /var/lib/mysql
    * RC script:
        - /etc/init.d/mysqld
    * Log file:
        - /var/log/mysqld.log
    * See also:
        - ${MYSQL_INIT_SQL}
        - ${SAMPLE_SQL}

EOF

    echo 'export status_mysql_initialize="DONE"' >> ${STATUS_FILE}
}
