#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# Configure pysieved.

pysieved_config()
{
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

# Append username to this for home directories
base = ${SIEVE_DIR}

# What UID and GID should own all files?  -1 to not bother
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}

# Switch user@host.name to host.name/user?
hostdirs = True

[Dovecot]
# Path to Dovecot's auth socket (do not set unless you're using
# Dovecot auth)
mux = ${DOVECOT_SOCKET_MUX}

# Path to Dovecot's master socket (if using Dovecot userdb lookup)
master = ${DOVECOT_SOCKET_MASTER}

# Path to sievec
sievec = ${DOVECOT_SIEVEC}

# Where in user directory to store scripts
scripts = ${PYSIEVED_RULE_DIR}

# What user/group owns the mail storage (-1 to never setuid/setgid)
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}
EOF

    # Copy init script.
    cp -f ${SAMPLE_DIR}/pysieved.init /etc/init.d/

    echo 'export status_pysieved_config="DONE"' >> ${STATUS_FILE}
}
