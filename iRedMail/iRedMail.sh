#!/bin/sh

# Author: Zhang Huangbin (michaelbibby <at> gmail.com)

# ------------------------------
# Define some global variables.
# ------------------------------
export ROOTDIR="$(pwd)"
export CONF_DIR="${ROOTDIR}/conf"
export FUNCTIONS_DIR="${ROOTDIR}/functions"
export DIALOG_DIR="${ROOTDIR}/dialog"
export PKG_DIR="${ROOTDIR}/pkgs/rpms"
export MISC_DIR="${ROOTDIR}/pkgs/misc"
export SAMPLE_DIR="${ROOTDIR}/samples"
export PATCH_DIR="${ROOTDIR}/patches"

. ${CONF_DIR}/global
. ${CONF_DIR}/functions

# ------------------------------
# Check target platform and environment.
# ------------------------------
check_arch && check_env

# ------------------------------
# Import variables.
# ------------------------------
# Source 'conf/httpd_php' first, other components need some variables
# defined in it.
. ${CONF_DIR}/httpd_php
. ${CONF_DIR}/openldap
. ${CONF_DIR}/phpldapadmin
. ${CONF_DIR}/mysql
. ${CONF_DIR}/postfix
. ${CONF_DIR}/policyd
. ${CONF_DIR}/pypolicyd-spf
. ${CONF_DIR}/dovecot
. ${CONF_DIR}/pysieved
. ${CONF_DIR}/procmail
. ${CONF_DIR}/amavisd
. ${CONF_DIR}/clamav
. ${CONF_DIR}/spamassassin
. ${CONF_DIR}/squirrelmail
. ${CONF_DIR}/roundcube
. ${CONF_DIR}/postfixadmin
. ${CONF_DIR}/phpmyadmin
. ${CONF_DIR}/extmail
. ${CONF_DIR}/horde
. ${CONF_DIR}/awstats

# ------------------------------
# Import functions.
# ------------------------------
# All packages.
. ${FUNCTIONS_DIR}/packages.sh

# User/Group: vmail. We will export vmail uid/gid here.
. ${FUNCTIONS_DIR}/user_vmail.sh

# Apache & PHP.
. ${FUNCTIONS_DIR}/apache_php.sh

# OpenLDAP.
. ${FUNCTIONS_DIR}/openldap.sh
. ${FUNCTIONS_DIR}/phpldapadmin.sh

# MySQL.
. ${FUNCTIONS_DIR}/mysql.sh
. ${FUNCTIONS_DIR}/postfixadmin.sh
. ${FUNCTIONS_DIR}/phpmyadmin.sh

# Switch.
. ${FUNCTIONS_DIR}/backend.sh

# Postfix.
. ${FUNCTIONS_DIR}/postfix.sh

# Policy service: Policyd & pypolicyd-spf.
. ${FUNCTIONS_DIR}/policy_service.sh

# Dovecot.
. ${FUNCTIONS_DIR}/dovecot.sh

# Managesieve.
. ${FUNCTIONS_DIR}/managesieve.sh

# Procmail.
. ${FUNCTIONS_DIR}/procmail.sh

# ClamAV.
. ${FUNCTIONS_DIR}/clamav.sh

# Amavisd-new.
. ${FUNCTIONS_DIR}/amavisd.sh

# SpamAssassin.
. ${FUNCTIONS_DIR}/spamassassin.sh

# SquirrelMail.
. ${FUNCTIONS_DIR}/squirrelmail.sh

# Roundcubemail.
. ${FUNCTIONS_DIR}/roundcubemail.sh

# Horde webmail.
. ${FUNCTIONS_DIR}/horde.sh

# ExtMail.
. ${FUNCTIONS_DIR}/extmail.sh

# Mailgraph.
. ${FUNCTIONS_DIR}/mailgraph.sh

# Awstats.
. ${FUNCTIONS_DIR}/awstats.sh

# Optional components.
. ${FUNCTIONS_DIR}/optional_components.sh

# Misc.
. ${FUNCTIONS_DIR}/misc.sh

# ************************************************************************
# *************************** Script Main ********************************
# ************************************************************************

# Install all packages.
check_status_before_run install_all || (ECHO_INFO "Package installation error, please check the output log."; exit 255)

# Create SSL/TLS cert file.
check_status_before_run gen_pem_key

# ------------------------------------------------
# User/Group: vmail
# ------------------------------------------------
check_status_before_run adduser_vmail

# ------------------------------------------------
# Apache & PHP.
# ------------------------------------------------
check_status_before_run apache_php_config

# ------------------------------------------------
# Install & Config Backend: OpenLDAP or MySQL.
# ------------------------------------------------
check_status_before_run backend_install

# ------------------------------------------------
# Postfix.
# ------------------------------------------------
check_status_before_run postfix_config_basic && \
check_status_before_run postfix_config_virtual_host && \
check_status_before_run postfix_config_sasl && \
check_status_before_run postfix_config_tls && \
check_status_before_run postfix_config_syslog

# ------------------------------------------------
# Policy service for Postfix: Policyd.
# ------------------------------------------------
check_status_before_run policy_service_config

# ------------------------------------------------
# Dovecot.
# ------------------------------------------------
check_status_before_run dovecot_config

# ------------------------------------------------
# Managesieve. 
# ------------------------------------------------
check_status_before_run managesieve_config

# -----------------------------------------------
# ClamAV.
# -----------------------------------------------
check_status_before_run clamav_config

# ------------------------------------------------
# Amavisd-new. (plus unrar, unarj, SpamAssassin)
# ------------------------------------------------
check_status_before_run amavisd_config
# SpamAssassin.
check_status_before_run sa_config

# -----------------------------------------------
# Optional components.
# -----------------------------------------------
optional_components

# -----------------------------------------------
# Clear away.
# -----------------------------------------------
check_status_before_run clear_away
