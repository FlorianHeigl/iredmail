# -------------------------------------------------------
# ---------------- Apache & PHP -------------------------
# -------------------------------------------------------

apache_php_config()
{
    backup_file ${HTTPD_CONF}

    ECHO_INFO "Disable 'AddDefaultCharset' in Apache."
    perl -pi -e 's/^(AddDefaultCharset UTF-8)/#${1}/' ${HTTPD_CONF}

    backup_file ${PHP_INI}

    ECHO_INFO "Increase 'memory_limit' to 128M in ${PHP_INI}."
    perl -pi -e 's/^(memory_limit = )/${1}128M ;/' ${PHP_INI}

    ECHO_INFO "Increase 'upload_max_filesize', 'post_max_size' to 10/12M in ${PHP_INI}."
    perl -pi -e 's/^(upload_max_filesize.*=)/${1}10M; #/' ${PHP_INI}
    perl -pi -e 's/^(post_max_size.*=)/${1}12M; #/' ${PHP_INI}

    cat >> ${TIP_FILE} <<EOF
Apache & PHP:
    * Configuration files:
        - /etc/httpd/conf/
        - /etc/httpd/conf.d/
        - /etc/php.ini
    * Directories:
        - ${HTTPD_SERVERROOT}
        - ${HTTPD_DOCUMENTROOT}

EOF

    echo 'export status_apache_php_config="DONE"' >> ${STATUS_FILE}
}
