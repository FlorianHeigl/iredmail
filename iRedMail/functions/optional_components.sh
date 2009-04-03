#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------
# Install all optional components.
# -------------------------------------------
optional_components()
{
    # Roundcubemail.
    [ X"${USE_RCM}" == X"YES" ] && \
        check_status_before_run rcm_install && \
        check_status_before_run rcm_config

    # phpLDAPadmin.
    [ X"${USE_PHPLDAPADMIN}" == X"YES" ] && \
        check_status_before_run pla_install

    # phpMyAdmin
    [ X"${USE_PHPMYADMIN}" == X"YES" ] && \
        check_status_before_run phpmyadmin_install

    # PostfixAdmin.
    [ X"${USE_POSTFIXADMIN}" == X"YES" ] && \
        check_status_before_run postfixadmin_install

    # Awstats.
    [ X"${USE_AWSTATS}" == X"YES" ] && \
        check_status_before_run awstats_config_basic && \
        check_status_before_run awstats_config_weblog && \
        check_status_before_run awstats_config_maillog && \
        check_status_before_run awstats_config_crontab
}
