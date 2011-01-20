#!/usr/bin/env bash

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

install_all()
{
    ALL_PKGS=''
    ENABLED_SERVICES=''
    DISABLED_SERVICES=''

    ###########################
    # Enable syslog or rsyslog.
    #
    if [ X"${DISTRO}" == X"RHEL" -o X"${DISTRO}" == X"SUSE" ]; then
        # RHEL/CENTOS, SuSE
        ENABLED_SERVICES="syslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"DEBIAN" ]; then
        # Debian.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"UBUNTU" ]; then
        # Ubuntu.
        if [ X"${DISTRO_CODENAME}" == X"karmic" -o X"${DISTRO_CODENAME}" == X"lucid" ]; then
            # Ubuntu 9.10, 10.04.
            ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
        else
            ENABLED_SERVICES="sysklogd ${ENABLED_SERVICES}"
        fi
    fi
    #### End syslog ####

    #################
    # Apache and PHP.
    #
    if [ X"${USE_EXIST_AMP}" != X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} httpd.${ARCH} mod_ssl.${ARCH} php.${ARCH} php-common.${ARCH} php-imap.${ARCH} php-gd.${ARCH} php-mbstring.${ARCH} libmcrypt.${ARCH} php-mcrypt.${ARCH} php-xml.${ARCH} php-mysql.${ARCH} php-ldap.${ARCH} php-mhash.${ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} httpd"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} apache2-prefork apache2-mod_php5 php5-iconv php5-ldap php5-mysql php5-mcrypt php5-mbstring php5-hash php5-gettext php5-dom php5-json php5-intl php5-fileinfo"
            ENABLED_SERVICES="${ENABLED_SERVICES} apache2"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} apache2 apache2-mpm-prefork apache2.2-common libapache2-mod-php5 libapache2-mod-auth-mysql php5-cli php5-imap php5-gd php5-mcrypt php5-mysql php5-ldap php5-mhash"
            ENABLED_SERVICES="${ENABLED_SERVICES} apache2"
        else
            :
        fi
    else
        :
    fi
    #### End Apache & PHP ####

    ###############
    # Postfix.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix.${ARCH}"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # On OpenSuSE, postfix already has ldap_table support.
        ALL_PKGS="${ALL_PKGS} postfix"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre"
    else
        :
    fi

    ENABLED_SERVICES="${ENABLED_SERVICES} postfix"
    #### End Postfix ####

    #############
    # Awstats.
    #
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch"
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        else
            :
        fi
    else
        :
    fi
    #### End Awstats ####

    ################
    # MySQL server.
    #
    # Note: mysql server is always required, used to store extra data,
    #       such as policyd, roundcube webmail data.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} mysqld"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} mysql-community-server mysql-community-server-client"
        ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} mysql-server mysql-client"
        ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
    #elif [ X"${DISTRO}" == X"UBUNTU" ]; then
    #    # Use mysql 5.0.x on Ubuntu 9.10 and earlier versions, 5.1.x on 10.04
    #    # and later versions.
    #    if [ X"${DISTRO_CODENAME}" == X"hardy" -o \
    #        X"${DISTRO_CODENAME}" == X"intrepid" -o \
    #        X"${DISTRO_CODENAME}" == X"jaunty" -o \
    #        X"${DISTRO_CODENAME}" == X"karmic" ]; then
    #        ALL_PKGS="${ALL_PKGS} mysql-server-5.0 mysql-client-5.0"
    #    else
    #        ALL_PKGS="${ALL_PKGS} mysql-server-5.1 mysql-client-5.1"
    #    fi
    #    ENABLED_SERVICES="${ENABLED_SERVICES} mysql"
    else
        :
    fi
    #### End MySQL server ####
    
    #################################################
    # Backend: OpenLDAP or MySQL, and extra packages.
    #
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # OpenLDAP server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap.${ARCH} openldap-clients.${ARCH} openldap-servers.${ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} ldap"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} openldap2 openldap2-client"
            ENABLED_SERVICES="${ENABLED_SERVICES} ldap"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-ldap slapd ldap-utils libnet-ldap-perl"
            ENABLED_SERVICES="${ENABLED_SERVICES} slapd"
        else
            :
        fi
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # MySQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql.${ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} postfix-mysql apache2-mod_auth_mysql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-mysql"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql"
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
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} policyd"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix-policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} postfix-policyd"

        if [ X"${DISTRO_CODENAME}" == X"lucid" ]; then
            # Don't invoke dbconfig-common on Ubuntu.
            dpkg-divert --rename /etc/dbconfig-common/postfix-policyd.conf
            mkdir -p /etc/dbconfig-common/ 2>/dev/null
            cat > /etc/dbconfig-common/postfix-policyd.conf <<EOF
dbc_install='true'
dbc_upgrade='false'
dbc_remove=''
dbc_dbtype='mysql'
dbc_dbuser='postfix-policyd'
dbc_dbpass="${POLICYD_DB_PASSWD}"
dbc_dbserver=''
dbc_dbport=''
dbc_dbname='postfixpolicyd'
dbc_dbadmin='root'
dbc_basepath=''
dbc_ssl=''
dbc_authmethod_admin=''
dbc_authmethod_user=''
EOF
        fi
    else
        :
    fi

    # Dovecot.
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot.${ARCH} dovecot-sieve.${ARCH} dovecot-managesieve.${ARCH}"

            # We will use Dovecot SASL auth mechanism, so 'saslauthd'
            # is not necessary, should be disabled.
            DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot12 dovecot12-backend-mysql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d"
        else
            :
        fi

        ENABLED_SERVICES="${ENABLED_SERVICES} dovecot"
    else
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="procmail.${ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} saslauthd"
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="procmail"
        fi
    fi

    # Amavisd-new & ClamAV & Altermime.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new.${ARCH} clamd.${ARCH} clamav.${ARCH} clamav-db.${ARCH} spamassassin.${ARCH} altermime.${ARCH} perl-LDAP.noarch perl-IO-Compress.noarch"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamd"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new clamav clamav-db spamassassin altermime perl-ldap perl-DBD-mysql"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamd freshclam"
        DISABLED_SERVICES="${DISABLED_SERVICES} clamav-milter spamd spampd"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl clamav-freshclam clamav-daemon spamassassin altermime"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${AMAVISD_RC_SCRIPT_NAME} clamav-daemon clamav-freshclam"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"
    else
        :
    fi

    # SPF.
    if [ X"${ENABLE_SPF}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # SPF implemention via perl-Mail-SPF.
            ALL_PKGS="${ALL_PKGS} perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            # SPF implemention via perl-Mail-SPF.
            ALL_PKGS="${ALL_PKGS} perl-Mail-SPF"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} libmail-spf-perl"
        else
            :
        fi
    else
        :
    fi

    # pysieved.
    # Warning: Do *NOT* add 'pysieved' service in 'ENABLED_SERVICES' here.
    #          We don't have rc/init script under ${DIR_RC_SCRIPTS} till
    #          package is installed.
    #if [ X"${USE_MANAGESIEVE}" == X"YES" ]; then
    #    # Note for Ubuntu & Debian:
    #    # Dovecot shipped in Debian/Ubuntu has managesieve plugin patched.
    #    [ X"${DISTRO}" == X"RHEL" ] && ALL_PKGS="${ALL_PKGS} pysieved.noarch"
    #else
    #    :
    #fi

    ############
    # iRedAPD.
    #
    if [ X"${USE_IREDAPD}" == X"YES" ]; then
        [ X"${DISTRO}" == X"RHEL" ] && ALL_PKGS="${ALL_PKGS} python-ldap.${ARCH}"
        [ X"${DISTRO}" == X"SuSE" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
        [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
        # Don't append 'iredapd' to ${ENABLED_SERVICES} since we don't have
        # RC script ready in early stage.
        #ENABLED_SERVICES="${ENABLED_SERVICES} iredapd"
    else
        :
    fi
    #### End iRedAPD ####

    #############
    # iRedAdmin.
    #
    if [ X"${USE_IREDADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} python-jinja2.${ARCH} python-webpy.noarch python-ldap.${ARCH} MySQL-python.${ARCH} mod_wsgi.${ARCH}"
            [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap.${ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            # Note: Web.py will be installed locally via 'easy_install'.
            ALL_PKGS="${ALL_PKGS} apache2-mod_wsgi python-jinja2 python-ldap python-mysql python-setuptools"
            [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} libapache2-mod-wsgi python-mysqldb python-ldap python-jinja2 python-netifaces python-webpy"
            [ X"${USE_IREDAPD}" != "YES" ] && ALL_PKGS="${ALL_PKGS} python-ldap"
        fi
    else
        :
    fi
    #### End iRedAdmin ####

    ############################
    # Misc packages & services.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2.${ARCH} acl.${ARCH} patch.${ARCH} vixie-cron.${ARCH} tmpwatch.${ARCH} crontabs.noarch dos2unix.${ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} crond"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tmpwatch dos2unix"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tofrodos"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    else
        :
    fi
    #### End Misc packages & services ####

    # Disable Ubuntu firewall rules, we have iptables init script and rule file.
    [ X"${DISTRO}" == X"UBUNTU" ] && export DISABLED_SERVICES="${DISABLED_SERVICES} ufw"

    #
    # ---- Ubuntu 10.04 special. ----
    #
    if [ X"${DISTRO_CODENAME}" == X"lucid" ]; then
        # Install phpLDAPadmin.
        if [ X"${USE_PHPLDAPADMIN}" == X"YES" ]; then
            ALL_PKGS="${ALL_PKGS} phpldapadmin"
        fi

        # Install phpMyAdmin-3.x.
        if [ X"${USE_PHPMYADMIN}" == X"YES" ]; then
            ALL_PKGS="${ALL_PKGS} phpmyadmin"
        fi
    fi
    #
    # ---- End Ubuntu 10.04 special. ----
    #

    export ALL_PKGS ENABLED_SERVICES

    # Install all packages.
    install_all_pkgs()
    {
        eval ${install_pkg} ${ALL_PKGS}
        if [ X"${DISTRO}" == X"SUSE" -a X"${USE_IREDADMIN}" == X"YES" ]; then
            ECHO_DEBUG "Install web.py (${MISC_DIR}/web.py-*.tar.bz)."
            easy_install ${MISC_DIR}/web.py-*.tar.gz >/dev/null
        fi
        echo 'export status_install_all_pkgs="DONE"' >> ${STATUS_FILE}
    }

    # Enable/Disable services.
    enable_all_services()
    {
        # Enable services.
        eval ${enable_service} ${ENABLED_SERVICES} >/dev/null

        # Disable services.
        eval ${disable_service} ${DISABLED_SERVICES} >/dev/null

        if [ X"${DISTRO}" == X"SUSE" ]; then
            eval ${disable_service} SuSEfirewall2_setup SuSEfirewall2_init >/dev/null
        fi

        echo 'export status_enable_all_services="DONE"' >> ${STATUS_FILE}
    }

    check_status_before_run install_all_pkgs
    check_status_before_run enable_all_services
}
