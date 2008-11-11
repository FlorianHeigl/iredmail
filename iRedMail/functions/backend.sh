#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------------------
# ------------- Install and config backend. -------------
# -------------------------------------------------------
backend_install()
{
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # Install, config and initialize OpenLDAP.
        check_status_before_run openldap_config && \
        check_status_before_run openldap_data_initialize

        # Check if we need MySQL to store some other data for other programs,
        # e.g. roundcube, policyd.
        if [ X"${USE_MYSQL}" == X"YES" ]; then
            check_status_before_run mysql_initialize
        else
            :
        fi
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # Initialize MySQL.
        check_status_before_run mysql_initialize
        check_status_before_run mysql_import_vmail_users
    else
        :
    fi
}
