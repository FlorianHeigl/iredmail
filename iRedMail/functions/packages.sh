install_all()
{
    ALL_PKGS=''
    ENABLED_SERVICES=''
    DISABLED_SERVICES=''

    # Apache.
    ALL_PKGS="${ALL_PKGS} httpd.${ARCH} mod_ssl.${ARCH}"

    # PHP.
    ALL_PKGS="${ALL_PKGS} php.${ARCH} php-imap.${ARCH} php-gd.${ARCH} php-mbstring.${ARCH} libmcrypt.${ARCH} php-mcrypt.${ARCH} php-pear.noarch php-xml.${ARCH} php-pecl-fileinfo.${ARCH}"

    # Postfix.
    ALL_PKGS="${ALL_PKGS} postfix.${ARCH}"

    ENABLED_SERVICES="${ENABLED_SERVICES} httpd postfix"

    # Backend: OpenLDAP or MySQL.
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then

        # OpenLDAP server & client.
        ALL_PKGS="${ALL_PKGS} openldap.${ARCH} openldap-clients.${ARCH} openldap-servers.${ARCH}"

        # PHP extensions.
        ALL_PKGS="${ALL_PKGS} php-ldap.${ARCH}"

        # Postgrey.
        ALL_PKGS="${ALL_PKGS} postgrey"

        # For ExtMail.
        [ X"${USE_EXTMAIL}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} perl-LDAP"

        ENABLED_SERVICES="${ENABLED_SERVICES} ldap postgrey"

    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # MySQL server & client.
        [ X"${MYSQL_FRESH_INSTALLATION}" == X'YES' ] && \
            ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"

        # PHP extensions.
        ALL_PKGS="${ALL_PKGS} php-mysql.${ARCH}"

        # Policyd.
        ALL_PKGS="${ALL_PKGS} policyd.${ARCH}"

        # For ExtMail.
        [ X"${USE_EXTMAIL}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} libdbi-dbd-mysql.${ARCH} perl-DBD-mysql.${ARCH}"

        ENABLED_SERVICES="${ENABLED_SERVICES} mysqld policyd"
    else
        :
    fi

    # Cyrus-SASL.
    ALL_PKGS="${ALL_PKGS} cyrus-sasl.${ARCH} cyrus-sasl-lib.${ARCH} cyrus-sasl-plain.${ARCH} cyrus-sasl-md5.${ARCH}"

    # Dovecot.
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot.${ARCH} dovecot-sieve.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} dovecot"
    else
        ALL_PKGS="procmail.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} saslauthd"
    fi

    # Amavisd-new & ClamAV.
    ALL_PKGS="${ALL_PKGS} amavisd-new.${ARCH} clamd.${ARCH} clamav.${ARCH} clamav-db.${ARCH}"
    ENABLED_SERVICES="${ENABLED_SERVICES} amavisd clamd"
    DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    # SPF.
    if [ X"${ENABLE_SPF}" == X"YES" ]; then
        # Via pypolicyd-spf. It's *NOT* recommended. Reference:
        # http://code.google.com/p/iredmail/wiki/iRedMail_tut_SPF
        [ X"${SPF_PROGRAM}" == X'pypolicyd-spf' ] && ALL_PKGS="${ALL_PKGS} pydns.noarch pyspf.noarch"

        # Via perl-Mail-SPF.
        [ X"${SPF_PROGRAM}" == X'perl-Mail-SPF' ] && ALL_PKGS="${ALL_PKGS} perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"
    else
        :
    fi

    # RRDTools.
    [ X"${USE_MAILGRAPH}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} rrdtool.${ARCH} perl-rrdtool.${ARCH} perl-File-Tail.noarch"

    # Mailman.
    [ X"${USE_MAILMAN}" == X"YES" ] && \
        ALL_PKGS="${ALL_PKGS} mailman.${ARCH}" && \
        ENABLED_SERVICES="${ENABLED_SERVICES} mailman"

    # Misc.
    ALL_PKGS="${ALL_PKGS} bzip2.${ARCH} acl.${ARCH} mailx.${ARCH} patch.${ARCH} crontabs.noarch"
    ENABLED_SERVICES="${ENABLED_SERVICES} crond"

    # Install all packages.
    install_pkg ${ALL_PKGS}

    # Enable services.
    for i in ${ENABLED_SERVICES}; do
        chkconfig --level 345 $i on
    done

    # Disable services.
    for i in ${DISABLED_SERVICES}
    do
        chkconfig --level 345 $i off
    done

    echo 'export status_install_all="DONE"' >> ${STATUS_FILE}
}
