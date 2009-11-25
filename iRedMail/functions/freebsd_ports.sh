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

    # Make it don't popup dialog while building ports.
    export BATCH=yes

    # m4. DEPENDENCE.
    cd /usr/ports/devel/m4 && make clean && make WITHOUT_LIBSIGSEGV=true install

    # Cyrus-SASL2. DEPENDENCE.
    cd /usr/ports/security/cyrus-sasl2 && make clean && make \
        WITH_BDB=true \
        WITH_MYSQL=true \
        WITH_DEV_URANDOM=true \
        WITH_KEEP_DB_OPEN=true \
        WITH_AUTHDAEMOND=true \
        WITH_LOGIN=true \
        WITH_PLAIN=true \
        WITH_CRAM=true \
        WITH_DIGEST=true \
        WITH_OTP=true \
        WITH_NTLM=true \
        WITHOUT_PGSQL=true \
        WITHOUT_SQLITE=true \
        WITHOUT_ALWAYSTRUE=true \
        install

    # Perl 5.8. REQUIRED.
    cd /usr/ports/lang/perl5.8 && make clean && make \
        WITHOUT_DEBUGGING=true \
        WITH_GDBM=true \
        WITH_PERL_MALLOC=true \
        WITH_PERL_64BITINT=true \
        WITH_THREADS=true \
        WITH_SUIDPERL=true \
        WITH_SITECUSTOMIZE=true \
        WITH_USE_PERL=true \
        install


    # OpenSLP. DEPENDENCE.
    cd /usr/ports/net/openslp && make clean && make \
        WITH_SLP_SECURITY=true \
        WITH_ASYNC_API=true \
        install

    # MySQL-server. REQUIRED.
    cd /usr/ports/databases/mysql50-server && make clean && make \
        WITH_CHARSET=utf8 \
        WITH_XCHARSET=all \
        WITH_OPENSSL=yes \
        WITH_COLLATION=utf8_general_ci \
        install

    ENABLED_SERVICES="${ENABLED_SERVICES} mysql"

    # OpenLDAP v2.4. REQUIRED for LDAP backend.
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        cd /usr/ports/net/openldap24-server && make clean && make \
            WITH_SASL=true \
            WITHOUT_DYNACL=true \
            WITHOUT_ACI=true \
            WITH_DNSSRV=true \
            WITH_PASSWD=true \
            WITH_PERL=true \
            WITH_RELAY=true \
            WITH_SHELL=true \
            WITH_SOCK=true \
            WITH_ODBC=true \
            WITH_RLOOKUPS=true \
            WITH_SLP=true \
            WITH_SLAPI=true \
            WITH_TCP_WRAPPERS=true \
            WITH_BDB=true \
            WITH_ACCESSLOG=true \
            WITH_AUDITLOG=true \
            WITH_COLLECT=true \
            WITH_CONSTRAINT=true \
            WITH_DDS=true \
            WITH_DEREF=true \
            WITH_DYNGROUP=true \
            WITH_DYNLIST=true \
            WITH_LASTMOD=true \
            WITH_MEMBEROF=true \
            WITH_PPOLICY=true \
            WITH_PROXYCACHE=true \
            WITH_REFINT=true \
            WITH_RETCODE=true \
            WITH_RWM=true \
            WITH_SEQMOD=true \
            WITH_SYNCPROV=true \
            WITH_TRANSLUCENT=true \
            WITH_UNIQUE=true \
            WITH_VALSORT=true \
            WITHOUT_SMBPWD=true \
            WITH_DYNAMIC_BACKENDS=true \
            install
    fi

    ENABLED_SERVICES="${ENABLED_SERVICES} slapd"

    # Dovecot v1.2.x. REQUIRED.
    cd /usr/ports/mail/dovecot && make clean && make \
        WITH_KQUEUE=true \
        WITH_SSL=true \
        WITH_IPV6=true \
        WITH_POP3=true \
        WITH_LDA=true \
        WITH_MANAGESIEVE=true \
        WITH_GSSAPI=true \
        WITHOUT_VPOPMAIL=true \
        WITH_BDB=true \
        WITH_LDAP=true \
        WITHOUT_PGSQL=true \
        WITH_MYSQL=true \
        WITHOUT_SQLITE=true \
        install

    cd /usr/ports/mail/dovecot-managesieve/ && make clean && make install
    cd /usr/ports/mail/dovecot-sieve && make clean && make install

    ENABLED_SERVICES="${ENABLED_SERVICES} dovecot"

    # ca_root_nss. DEPENDENCE.
    cd /usr/ports/security/ca_root_nss && make clean && make \
        WITHOUT_ETCSYMLINK=true \
        install

    # libssh2. DEPENDENCE.
    cd /usr/ports/security/libssh2 && make clean && make \
        WITHOUT_GCRYPT=true \
        install

    # Curl. DEPENDENCE.
    cd /usr/ports/ftp/curl && make clean && make \
        WITHOUT_CARES=true \
        WITHOUT_CURL_DEBUG=true \
        WITHOUT_GNUTLS=true \
        WITH_IPV6=true \
        WITHOUT_KERBEROS4=true \
        WITHOUT_LDAP=true \
        WITHOUT_LDAPS=true \
        WITH_LIBIDN=true \
        WITH_LIBSSH2=true \
        WITH_NTLM=true \
        WITH_OPENSSL=true \
        WITH_PROXY=true \
        WITHOUT_TRACKMEMORY=true \
        install

    # libusb. DEPENDENCE.
    cd /usr/ports/devel/libusb && make clean && make \
        WITHOUT_SGML=true \
        install

    # pth. DEPENDENCE.
    cd /usr/ports/devel/pth && make clean && make \
        WITH_OPTIMIZED_CFLAGS=true \
        install

    # GnuPG. DEPENDENCE.
    cd /usr/ports/security/gnupg && make clean && make \
        WITH_LDAP=true \
        WITH_SCDAEMON=true \
        WITH_CURL=true \
        WITH_GPGSM=true \
        WITH_CAMELLIA=true \
        WITH_KDNS=true \
        WITH_NLS=true \
        install

    # p5-IO-Socket-SSL. DEPENDENCE.
    cd /usr/ports/security/p5-IO-Socket-SSL && make clean && make \
        WITH_IDN=true \
        install

    cd /usr/ports/archivers/p5-Archive-Tar && make clean && make \
        WITH_TEXT_DIFF=true \
        install

    cd /usr/ports/dns/p5-Net-DNS && make clean && make \
        WITH_IPV6=true \
        install

    # SpamAssassin. REQUIRED.
    cd /usr/ports/mail/p5-Mail-SpamAssassin && make clean && make \
        WITH_AS_ROOT=true \
        WITH_SPAMC=true \
        WITH_SACOMPILE=true \
        WITH_DKIM=true \
        WITH_SSL=true \
        WITH_GNUPG=true \
        WITH_MYSQL=true \
        WITHOUT_PGSQL=true \
        WITH_RAZOR=true \
        WITH_SPF_QUERY=true \
        WITH_RELAY_COUNTRY=true \
        install

    DISABLED_SERVICES="${DISABLED_SERVICES} spamd"

    # AlterMIME. REQUIRED.
    cd /usr/ports/mail/altermime && make clean && make install

    # Amavisd-new. REQUIRED.
    cd /usr/ports/mail/p5-MIME-Tools && make clean && make install
    cd /usr/ports/devel/p5-IO-stringy/ && make clean && make install
    cd /usr/ports/sysutils/p5-Unix-Syslog && make clean && make install
    cd /usr/ports/net/p5-Net-Server && make clean && make install
    cd /usr/ports/security/p5-Digest-SHA && make clean && make install
    cd /usr/ports/converters/p5-Convert-TNEF && make clean && make install
    cd /usr/ports/converters/p5-Convert-UUlib && make clean && make install
    cd /usr/ports/archivers/p5-Archive-Zip && make clean && make install
    cd /usr/ports/security/p5-Authen-SASL && make clean && make WITH_KERBEROS=true install
    cd /usr/ports/security/amavisd-new && make clean && make \
        WITH_BDB=true \
        WITH_MYSQL=true \
        WITH_LDAP=true \
        WITH_SASL=true \
        WITH_SPAMASSASSIN=true \
        WITH_P0F=true \
        WITH_ALTERMIME=true \
        WITH_FILE=true \
        WITH_RAR=true \
        WITH_UNRAR=true \
        WITH_ARJ=true \
        WITH_UNARJ=true \
        WITH_LHA=true \
        WITH_ARC=true \
        WITH_NOMARCH=true \
        WITH_CAB=true \
        WITH_RPM=true \
        WITH_ZOO=true \
        WITH_UNZOO=true \
        WITH_LZOP=true \
        WITH_FREEZE=true \
        WITH_P7ZIP=true \
        WITH_MSWORD=true \
        WITH_TNEF=true \
        WITHOUT_SQLITE=true \
        WITHOUT_PGSQL=true \
        WITHOUT_MILTER=true \
        install

    ENABLED_SERVICES="${ENABLED_SERVICES} amavisd amavis_p0fanalyzer"

    # Pcre. REQUIRED.
    cd /usr/ports/devel/pcre && make clean && make install

    # Postfix v2.5. REQUIRED.
    cd /usr/ports/mail/postfix25/ && make clean && make \
        WITH_PCRE=true \
        WITHOUT_SASL2=true \
        WITH_DOVECOT=true \
        WITHOUT_SASLKRB=true \
        WITHOUT_SASLKRB5=true \
        WITHOUT_SASLKMIT=true \
        WITH_TLS=true \
        WITH_BDB=true \
        WITH_MYSQL=true \
        WITHOUT_PGSQL=true
        WITH_OPENLDAP=true \
        WITH_CDB=true \
        WITHOUT_NIS=true \
        WITHOUT_VDA=true \
        WITHOUT_TEST=true \
        install

    ENABLED_SERVICES="${ENABLED_SERVICES} postfix"
    DISABLED_SERVICES="${DISABLED_SERVICES} sendmail sendmail_submit sendmail_outbound sendmail_msq_queue"

    # Policyd v1.8x. REQUIRED.
    cd /usr/ports/mail/postfix-policyd-sf && make clean && make install

    ENABLED_SERVICES="${ENABLED_SERVICES} policyd"

    # ClamAV. REQUIRED.
    cd /usr/ports/security/clamav/ && make clean && make \
        WITH_ARC=true \
        WITH_ARJ=true \
        WITH_LHA=true \
        WITH_UNZOO=true \
        WITH_UNRAR=true \
        WITH_ICONV=true \
        WITHOUT_MILTER=true \
        WITHOUT_LDAP=true \
        WITHOUT_STDERR=true \
        WITHOUT_EXPERIMENTAL=true \
        install

    ENABLED_SERVICES="${ENABLED_SERVICES} clamav_clamd clamav_freshclam"

    # Apr. DEPENDENCE.
    cd /usr/ports/devel/apr && make clean && make \
        WITH_THREADS=true \
        WITH_IPV6=true \
        WITH_GDBM=true \
        WITH_BDB=true \
        WITHOUT_NDBM=true \
        WITH_LDAP=true \
        WITH_MYSQL=true \
        WITHOUT_PGSQL=true \
        install

    # Python v2.6. REQUIRED.
    cd /usr/ports/lang/python26 && make clean && make \
        WITH_THREADS=true \
        WITHOUT_HUGE_STACK_SIZE=true \
        WITHOUT_SEM=true \
        WITH_PTH=true \
        WITH_UCS4=true \
        WITH_PYMALLOC=true \
        WITH_IPV6=true \
        WITH_FPECTL=true \
        install

    # Apache v2.2.x. REQUIRED.
    cd /usr/ports/www/apache22/ && make clean && make \
        WITH_APR_FROM_PORTS=true \
        WITH_THREADS=true \
        WITH_MYSQL=true \
        WITHOUT_PGSQL=true \
        WITHOUT_SQLITE=true \
        WITH_IPV6=true \
        WITH_BDB=true \
        WITH_AUTH_BASIC=true \
        WITH_AUTH_DIGEST=true \
        WITH_AUTHN_FILE=true \
        WITH_AUTHN_DBD=true \
        WITH_AUTHN_DBM=true \
        WITH_AUTHN_ANON=true \
        WITH_AUTHN_DEFAULT=true \
        WITH_AUTHN_ALIAS=true \
        WITH_AUTHZ_HOST=true \
        WITH_AUTHZ_GROUPFILE=true \
        WITH_AUTHZ_USER=true \
        WITH_AUTHZ_DBM=true \
        WITH_AUTHZ_OWNER=true \
        WITH_AUTHZ_DEFAULT=true \
        WITH_CACHE=true \
        WITH_DISK_CACHE=true \
        WITH_FILE_CACHE=true \
        WITH_MEM_CACHE=true \
        WITH_DAV=true \
        WITH_DAV_FS=true \
        WITH_BUCKETEER=true \
        WITH_CASE_FILTER=true \
        WITH_CASE_FILTER_IN=true \
        WITH_EXT_FILTER=true \
        WITH_LOG_FORENSIC=true \
        WITH_OPTIONAL_HOOK_EXPORT=true \
        WITH_OPTIONAL_HOOK_IMPORT=true \
        WITH_OPTIONAL_FN_IMPORT=true \
        WITH_OPTIONAL_FN_EXPORT=true \
        WITH_LDAP=true \
        WITH_AUTHNZ_LDAP=true \
        WITH_ACTIONS=true \
        WITH_ALIAS=true \
        WITH_ASIS=true \
        WITH_AUTOINDEX=true \
        WITH_CERN_META=true \
        WITH_CGI=true \
        WITH_CHARSET_LITE=true \
        WITH_DBD=true \
        WITH_DEFLATE=true \
        WITH_DIR=true \
        WITH_DUMPIO=true \
        WITH_ENV=true \
        WITH_EXPIRES=true \
        WITH_HEADERS=true \
        WITH_IMAGEMAP=true \
        WITH_INCLUDE=true \
        WITH_INFO=true \
        WITH_LOG_CONFIG=true \
        WITH_LOGIO=true \
        WITH_MIME=true \
        WITH_MIME_MAGIC=true \
        WITH_NEGOTIATION=true \
        WITH_REWRITE=true \
        WITH_SETENVIF=true \
        WITH_SPELING=true \
        WITH_STATUS=true \
        WITH_UNIQUE_ID=true \
        WITH_USERDIR=true \
        WITH_USERTRACK=true \
        WITH_VHOST_ALIAS=true \
        WITH_FILTER=true \
        WITH_VERSION=true \
        WITH_PROXY=true \
        WITH_PROXY_CONNECT=true \
        WITH_PATCH_PROXY_CONNECT=true \
        WITH_PROXY_FTP=true \
        WITH_PROXY_HTTP=true \
        WITH_PROXY_AJP=true \
        WITH_PROXY_BALANCER=true \
        WITH_SSL=true \
        WITH_SUEXEC=true \
        WITH_CGID=true \
        install

    ENABLED_SERVICES="${ENABLED_SERVICES} apache22"

    # PHP5. REQUIRED.
    cd /usr/ports/lang/php5 && make clean && make \
        WITH_CLI=true \
        WITH_CGI=true \
        WITH_APACHE=true \
        WITHOUT_DEBUG=true \
        WITH_SUHOSIN=true \
        WITH_MULTIBYTE=true \
        WITH_IPV6=true \
        WITH_MAILHEAD=true \
        WITH_REDIRECT=true \
        WITH_DISCARD=true \
        WITH_FASTCGI=true \
        WITH_PATHINFO=true \
        install

    # PHP extensions. REQUIRED.
    cd /usr/ports/lang/php5-extensions && make clean && make \
        WITHOUT_BCMATH=true \
        WITH_BZ2=true \
        WITHOUT_CALENDAR=true \
        WITH_CTYPE=true \
        WITH_CURL=true \
        WITHOUT_DBA=true \
        WITHOUT_DBASE=true \
        WITH_DOM=true \
        WITHOUT_EXIF=true \
        WITHOUT_FILEINFO=true \
        WITH_FILTER=true \
        WITHOUT_FRIBIDI=true \
        WITHOUT_FTP=true \
        WITH_GD=true \
        WITH_GETTEXT=true \
        WITHOUT_GMP=true \
        WITH_HASH=true \
        WITH_ICONV=true \
        WITH_IMAP=true \
        WITHOUT_INTERBASE=true \
        WITH_JSON=true \
        WITH_LDAP=true \
        WITH_MBSTRING=true \
        WITH_MCRYPT=true \
        WITH_MHASH=true \
        WITHOUT_MING=true \
        WITHOUT_MSSQL=true \
        WITH_MYSQL=true \
        WITH_MYSQLI=true \
        WITHOUT_NCURSES=true \
        WITHOUT_ODBC=true \
        WITH_OPENSSL=true \
        WITHOUT_PCNTL=true \
        WITH_PCRE=true \
        WITHOUT_PDF=true \
        WITH_PDO=true \
        WITH_PDO_SQLITE=true \
        WITHOUT_PGSQL=true \
        WITH_POSIX=true \
        WITHOUT_PSPELL=true \
        WITHOUT_READLINE=true \
        WITHOUT_RECODE=true \
        WITH_SESSION=true \
        WITHOUT_SHMOP=true \
        WITH_SIMPLEXML=true \
        WITHOUT_SNMP=true \
        WITHOUT_SOAP=true \
        WITHOUT_SOCKETS=true \
        WITH_SPL=true \
        WITH_SQLITE=true \
        WITHOUT_SYBASE_CT=true \
        WITHOUT_SYSVMSG=true \
        WITHOUT_SYSVSEM=true \
        WITHOUT_SYSVSHM=true \
        WITHOUT_TIDY=true \
        WITH_TOKENIZER=true \
        WITHOUT_WDDX=true \
        WITH_XML=true \
        WITH_XMLREADER=true \
        WITHOUT_XMLRPC=true \
        WITH_XMLWRITER=true \
        WITHOUT_XSL=true \
        WITHOUT_YAZ=true \
        WITH_ZIP=true \
        WITH_ZLIB=true \
        install

    if [ X"${USE_IREDADMIN}" == X"YES" ]; then
        # mod_wsgi.
        cd /usr/ports/www/mod_wsgi && make clean && make install
    fi

    # Re-export PATH.
    export PATH="${PATH}"
}
