#!/bin/bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

install_all()
{
    ALL_PKGS=''
    ENABLED_SERVICES=''
    DISABLED_SERVICES=''

    # Apache and PHP.
    if [ X"${USE_EXIST_AMP}" != X"YES" ]; then
        # Apache & PHP.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} httpd.${ARCH} mod_ssl.${ARCH} php.${ARCH} php-imap.${ARCH} php-gd.${ARCH} php-mbstring.${ARCH} libmcrypt.${ARCH} php-mcrypt.${ARCH} php-pear.noarch php-xml.${ARCH} php-pecl-fileinfo.${ARCH} php-eaccelerator.${ARCH} php-mysql.${ARCH} php-ldap.${ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} httpd"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} apache2 apache2-mpm-prefork apache2.2-common libapache2-mod-php5 libapache2-mod-auth-mysql php5-cli php5-imap php5-gd php5-mcrypt php5-mysql php5-ldap"
            ENABLED_SERVICES="${ENABLED_SERVICES} apache2"
        else
            :
        fi
    else
        :
    fi

    # Postfix.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix.${ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre postfix-mysql postfix-ldap"
    else
        :
    fi

    ENABLED_SERVICES="${ENABLED_SERVICES} postfix"

    # Awstats.
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        else
            :
        fi
    else
        :
    fi

    # Backend: OpenLDAP or MySQL.
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # OpenLDAP server & client.
        # Note: mysql server is required, used to store extra data,
        #       such as policyd, roundcube webmail data.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap.${ARCH} openldap-clients.${ARCH} openldap-servers.${ARCH}"

            # MySQL server. Used to store extra data, such as policyd, roundcube webmail.
            ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"

            ENABLED_SERVICES="${ENABLED_SERVICES} ldap mysqld"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} slapd ldap-utils mysql-server-5.0 mysql-client-5.0"

            ENABLED_SERVICES="${ENABLED_SERVICES} slapd mysql"
        else
            :
        fi
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # MySQL server & client.
        if [ X"${MYSQL_FRESH_INSTALLATION}" == X'YES' ]; then 
            if [ X"${DISTRO}" == X"RHEL" ]; then
                ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"

                # For Awstats.
                [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql.${ARCH}"

                ENABLED_SERVICES="${ENABLED_SERVICES} mysqld"

            elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
                ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"

                # For Awstats.
                [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql.${ARCH}"

                ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
            else
                :
            fi
        else
            :
        fi
    else
        :
    fi

    # Policyd.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} policyd.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} policyd"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix-policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} postfix-policyd"
    else
        :
    fi

    # Dovecot.
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot.${ARCH} dovecot-sieve.${ARCH}"

            # We will use Dovecot SASL auth mechanism, so 'saslauthd'
            # is not necessary, should be disabled.
            DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d"
        else
            :
        fi

        ENABLED_SERVICES="${ENABLED_SERVICES} dovecot"
    else
        ALL_PKGS="procmail.${ARCH}"
        [ X"${DISTRO}" == X"RHEL" ] && ENABLED_SERVICES="${ENABLED_SERVICES} saslauthd"
    fi

    # Amavisd-new & ClamAV.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new.${ARCH} clamd.${ARCH} clamav.${ARCH} clamav-db.${ARCH} spamassassin.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} amavisd clamd"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new clamav-freshclam clamav-daemon spamassassin"
        ENABLED_SERVICES="${ENABLED_SERVICES} amavis clamav-daemon clamav-freshclam"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"
    else
        :
    fi

    # SPF.
    if [ X"${ENABLE_SPF}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # SPF implemention via perl-Mail-SPF.
            ALL_PKGS="${ALL_PKGS} perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} libmail-spf-perl"
        else
            :
        fi
    else
        :
    fi

    # pysieved.
    # Warning: Do *NOT* add 'pysieved' service in 'ENABLED_SERVICES'.
    #          We don't have rc/init script under /etc/init.d/ now.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} pysieved.noarch"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        # TODO add pysieved
        #ALL_PKGS="${ALL_PKGS} "
        :
    else
        :
    fi

    # Misc.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2.${ARCH} acl.${ARCH} mailx.${ARCH} patch.${ARCH} crontabs.noarch dos2unix.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} crond"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl mailx patch cron tofrodos"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    else
        :
    fi

    export ALL_PKGS ENABLED_SERVICES

    # Install all packages.
    install_all_pkgs()
    {
        eval ${install_pkg} ${ALL_PKGS}
        echo 'export status_install_all_pkgs="DONE"' >> ${STATUS_FILE}
    }

    # Enable/Disable services.
    enable_all_services()
    {
        # Enable services.
        eval ${enable_service} ${ENABLED_SERVICES} >/dev/null

        # Disable services.
        eval ${disable_service} ${DISABLED_SERVICES} >/dev/null

        echo 'export status_enable_all_services="DONE"' >> ${STATUS_FILE}
    }

    check_status_before_run install_all_pkgs
    check_status_before_run enable_all_services
}

gen_pem_key()
{
    # Create necessary directories.
    [ -d ${SSL_FILE_DIR} ] || mkdir -p ${SSL_FILE_DIR}

    openssl req \
        -x509 -nodes -days 3650 -newkey rsa:1024 \
        -subj "/C=${TLS_COUNTRY}/ST=${TLS_STATE}/L=${TLS_CITY}/O=${TLS_COMPANY}/OU=${TLS_DEPARTMENT}/CN=${TLS_HOSTNAME}/emailAddress=${TLS_ADMIN}/" \
        -out ${SSL_CERT_FILE} -keyout ${SSL_KEY_FILE} >/dev/null 2>&1

    # Set correct file permission.
    chmod 0444 ${SSL_CERT_FILE}
    chmod 0400 ${SSL_KEY_FILE}
}
