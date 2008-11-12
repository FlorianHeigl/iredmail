#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

horde_install()
{
    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${HORDE_TARBALL} ${HTTPD_DOCUMENTROOT}
    mv ${HTTPD_DOCUMENTROOT}/horde-webmail-${HORDE_VERSION} ${HORDE_HTTPD_ROOT}

    ECHO_INFO "Set correct permission for Horde webmail: ${HORDE_HTTPD_ROOT}."
    # Secure config files.
    chown -R apache:root ${HORDE_HTTPD_ROOT}/config
    chown -R apache:root ${HORDE_HTTPD_ROOT}/*/config
    chmod -R go-rwx ${HORDE_HTTPD_ROOT}/config
    chmod -R go-rwx ${HORDE_HTTPD_ROOT}/*/config

    # Secure scripts.
    chown -R root:root ${HORDE_HTTPD_ROOT}/scripts
    chown -R root:root ${HORDE_HTTPD_ROOT}/*/scripts
    chmod -R go-rwx ${HORDE_HTTPD_ROOT}/scripts
    chmod -R go-rwx ${HORDE_HTTPD_ROOT}/*/scripts

    # Secure test.php.
    chmod a-rwx ${HORDE_HTTPD_ROOT}/test.php
    chmod a-rwx ${HORDE_HTTPD_ROOT}/*/test.php

    echo 'export status_horde_install="DONE"' >> ${STATUS_FILE}
}

horde_config()
{
    ECHO_INFO "Import MySQL database for Horde webmail."
    horde_db_template="/tmp/horde_db_template.sql"
    cp -f ${HORDE_DB_TEMPLATE} ${horde_db_template}
    # Set database user password.
    perl -pi -e 's#(.*PASSWORD.*)horde(.*)#${1}$ENV{HORDE_DB_PASSWD}${2}#' ${horde_db_template}
    # Set charset.
    perl -pi -e 's#^(CREATE DATABASE horde)(.*)#${1} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;#' ${horde_db_template}

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
SOURCE ${horde_db_template};
EOF

    rm -f ${horde_db_template}

    php ${HORDE_HTTPD_ROOT}/scripts/setup.php >/dev/null 2>&1 <<EOF
/horde
1
mysql
0
${HORDE_DB_USER}
${HORDE_DB_PASSWD}
unix
${MYSQL_SOCKET}
${HORDE_DB_NAME}
utf-8
false
0
EOF

    # Hack configuration file. 
    # Cookie setting.
    cd ${HORDE_HTTPD_ROOT}/config/ && \
    perl -pi -e 's#(.*conf.*cookie.*domain.*=).*#${1} "";#' conf.php
    perl -pi -e 's#(.*nls.*defaults.*language.*=).*#${1} "$ENV{HORDE_DEFAULT_LANGUAGE}";#' nls.php

    # Empty default email footer msg.
    echo '' > ${HORDE_HTTPD_ROOT}/imp/config/trailer.txt    # Automatic appended email footer msg.

    ECHO_INFO "Create directory alias for Horde WebMail."
    cat > ${HTTPD_CONF_DIR}/horde.conf <<EOF
${CONF_MSG}
<Directory ${HORDE_HTTPD_ROOT}>
    Options +FollowSymLinks

    # horde.org's recommended PHP settings:
    php_admin_flag safe_mode off
    php_admin_flag magic_quotes_runtime off
    php_flag session.use_trans_sid off
    php_flag session.auto_start off
    php_admin_flag file_uploads on

    # Optional - required for weather block in Horde to function
    php_admin_flag allow_url_fopen on

    # If horde dies while trying to handle large email file attachments,
    #  you are probably hitting PHP's memory limit.  Raise that limit here,
    #  but use caution
    # Set to your preference - memory_limit should be at least 32M
    #  and be greater than the value set for post_max_size
    #php_value memory_limit 32M
    #php_value post_max_size 20M
    #php_value upload_max_filesize 10M

    # /usr/share/pear is needed for PEAR. ${HORDE_HTTPD_ROOT} is needed for Horde itself
    # TODO: Set an appropriate include_path, too. Might even increase speed a bit.
    php_admin_value open_basedir "${HORDE_HTTPD_ROOT}:${HORDE_HTTPD_ROOT}/config:/usr/share/pear:/tmp"
    php_admin_flag register_globals off
</Directory>

<Directory ${HORDE_HTTPD_ROOT}/config>
    Order Deny,Allow
    Deny from all
</Directory>

# Deny access to files that are not served directly by the webserver
<DirectoryMatch "^${HORDE_HTTPD_ROOT}/(.*/)?(config|lib|locale|po|scripts|templates)/(.*)?">
    Order Deny,Allow
    Deny from all
</DirectoryMatch>

# Deny access to the test.php files except from localhost
#<LocationMatch "^/horde/(.*/)?test.php">
#    Order Deny,Allow
#    Deny from all
#    Allow from 127.0.0.1
#</LocationMatch>
EOF

    cat >> ${TIP_FILE} <<EOF
WebMail(Horde WebMail(${HORDE_VERSION}):
    * Configuration files:
        - ${HTTPD_CONF_DIR}/horde.conf
        - ${HORDE_HTTPD_ROOT}/
        - ${HORDE_HTTPD_ROOT}/config/*
        - ${HORDE_HTTPD_ROOT}/imp/config/*
EOF

    echo 'export status_horde_config="DONE"' >> ${STATUS_FILE}
}

# Turba is an address book program.
horde_config_turba()
{
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        ECHO_INFO "Setting up global LDAP address book for Horde (Turba)."

        cat >> ${HORDE_TURBA_CONFIG_DIR}/sources.php <<EOF
\$cfgSources['localldap'] = array('title' => _("Global Address Book."),
                                 'type' => 'ldap',
                                 'params' => array('server'    => "${LDAP_SERVER_HOST}",
                                                   'port'      => "${LDAP_SERVER_PORT}",
                                                   'tls'       => false,
                                                   'root'      => "${LDAP_ATTR_DOMAIN_DN_NAME}=${FIRST_DOMAIN},${LDAP_BASEDN}",
                                                   'bind_dn'   => "${LDAP_BINDDN}",
                                                   'bind_password' => "${LDAP_BINDPW}",
                                                   'version'   => ${LDAP_BIND_VERSION},
                                                   'scope'     => 'one',
                                                   'charset'   => 'utf-8',
                                                   'sizelimit' => 200),
                                 'map'    => array('__key'     => 'dn',
                                                   'name'      => 'cn',
                                                   'email'     => 'mail'),
                                 'search' => array('name', 'email'),
                                 'strict' => array('dn'),
                                 'public' => true,
                                 'readonly' => true,
                                 'admin' => array(),
                                 'export' => true,
                                 'browse' => true);
EOF
    else
        :
    fi
}

# Ingo is Email Filter Rules Manager.
horde_config_ingo()
{
    if [ X"${USE_MANAGESIEVE}" == X"YES" ]; then
        ECHO_INFO "Setting up managesieve service (pysieved) for Horde (Ingo)."

        backup_file ${HORDE_INGO_CONFIG_DIR}/backends.php
        cat > ${HORDE_INGO_CONFIG_DIR}/backends.php <<EOF
<?php
\$backends['sieve'] = array(
    'driver' => 'timsieved',
    'preferred' => "${FIRST_DOMAIN}",
    'hordeauth' => false,
    'params' => array(
        // Hostname of the timsieved server
        'hostspec' => "${PYSIEVED_BINDADDR}",
        // Login type of the server
        'logintype' => 'LOGIN',
        // Enable/disable TLS encryption
        'usetls' => false,
        // Port number of the timsieved server
        'port' => ${PYSIEVED_PORT},
        // Name of the sieve script
        'scriptname' => "${SIEVE_RULE_FILENAME}",
    ),
    'script' => 'sieve',
    'scriptparams' => array(),
    'shares' => false
);
EOF
    else
        :
    fi
}
