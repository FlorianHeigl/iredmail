#!/usr/bin/env bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# Configure pysieved.
pysieved_config()
{
    ECHO_INFO "==================== Pysieved ===================="

    backup_file ${PYSIEVED_INI}

    ECHO_INFO "Setting up managesieve server: pysieved."

    cat > ${PYSIEVED_INI} <<EOF
${CONF_MSG}
[main]
# Authentication back-end to use
auth    = Dovecot

# User DB back-end to use
userdb  = Virtual

# Storage back-end to use
storage = Dovecot

# Bind to what address?  (Ignored with --stdin)
bindaddr = ${PYSIEVED_BINDADDR}

# Listen on what port?  (Ignored with --stdin)
port    = ${PYSIEVED_PORT}

# Write a pidfile here
pidfile = ${PYSIEVED_PIDFILE}

[Virtual]
# Append username to this for home directories
base = ${SIEVE_DIR}

# What UID and GID should own all files?  -1 to not bother
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}

# Switch user@host.name to host.name/user?
hostdirs = True

[Dovecot]
# How do we identify ourself to Dovecot? Default is 'pysieved'.
service = managesieve

# Path to Dovecot's auth socket (do not set unless you're using
# Dovecot auth)
mux = ${DOVECOT_SOCKET_MUX}

# Path to Dovecot's master socket (if using Dovecot userdb lookup)
master = ${DOVECOT_SOCKET_MASTER}

# Path to sievec
sievec = ${DOVECOT_SIEVEC}

# Where in user directory to store scripts.
scripts = .

# Filename used for the active SIEVE filter (see README.Dovecot)
active = ${SIEVE_RULE_FILENAME}

# What user/group owns the mail storage (-1 to never setuid/setgid)
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}
EOF

    # Modify pysieved source, replace 'os.mkdir' by 'os.makedirs'.
    pysieved_dovecot_py="$(eval ${LIST_FILES_IN_PKG} pysieved|grep 'dovecot.py$')"
    [ ! -z ${pysieved_dovecot_py} ] && perl -pi -e 's#os.mkdir#os.makedirs#' ${pysieved_dovecot_py}

    # Create directory to store pid file.
    pysieved_pid_dir="$(dirname ${PYSIEVED_PIDFILE})"
    mkdir -p ${pysieved_pid_dir} 2>/dev/null
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${pysieved_pid_dir}

    # Copy init script and enable it.
    cp -f ${SAMPLE_DIR}/pysieved.init.rhel /etc/init.d/pysieved
    chmod +x /etc/init.d/pysieved
    eval ${enable_service} pysieved

    # Disable pysieved in xinetd.
    pysieved_xinetd_conf="$(eval ${LIST_FILES_IN_PKG} pysieved | grep 'xinetd' | grep 'pysieved$')"
    if [ ! -z ${pysieved_xinetd_conf} ]; then
        perl -pi -e 's#(.*disable.*=).*#${1} yes#' ${pysieved_xinetd_conf}
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
pysieved:
    * Configuration files:
        - ${PYSIEVED_INI}
    * RC script:
        - /etc/init.d/pysieved (RHEL/CentOS only)

EOF

    echo 'export status_pysieved_config="DONE"' >> ${STATUS_FILE}
}

managesieve_config()
{
    if [ X"${USE_MANAGESIEVE}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # Use pysieved.
            check_status_before_run pysieved_config
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # Dovecot is patched and ships managesieve protocal.
            perl -pi -e 's#^(protocols =.*)#${1} managesieve#' ${DOVECOT_CONF}
            cat >> ${DOVECOT_CONF} <<EOF
protocol managesieve {
    # IP or host address where to listen in for connections.
    listen = ${MANAGESIEVE_BINDADDR}:${MANAGESIEVE_PORT}

    # Specifies the location of the symbolic link pointing to the
    # active script in the sieve storage directory.
    sieve = ${SIEVE_DIR}/%Ld/%Ln/${SIEVE_RULE_FILENAME}

    # This specifies the path to the directory where the uploaded scripts are stored.
    sieve_storage = ${SIEVE_DIR}/%Ld/%Ln/

    # Login executable location.
    login_executable = /usr/lib/dovecot/managesieve-login

    # managesieve executable location. See mail_executable for IMAP for
    # examples how this could be changed.
    mail_executable = /usr/lib/dovecot/managesieve

    # Maximum managesieve command line length in bytes.
    managesieve_max_line_length = 65536

    # To fool ManageSieve clients that are focused on CMU's timesieved
    # you can specify the IMPLEMENTATION capability that the dovecot
    # reports to clients (e.g. 'Cyrus timsieved v2.2.13').
    managesieve_implementation_string = dovecot
}
EOF
        else
            :
        fi
    else
        :
    fi
}
