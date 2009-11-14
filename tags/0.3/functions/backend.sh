# -------------------------------------------------------
# ------------- Install and config backend. -------------
# -------------------------------------------------------
backend_install()
{
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # Install, config and initialize OpenLDAP.
        check_status_before_run openldap_config && \
        check_status_before_run openldap_tls_config && \
        check_status_before_run openldap_data_initialize
    else
        # Initialize MySQL.
        check_status_before_run mysql_initialize
    fi

    echo 'export status_backend_install="DONE"' >> ${STATUS_FILE}
}
