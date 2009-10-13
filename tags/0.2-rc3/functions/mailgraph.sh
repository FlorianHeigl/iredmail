# -------------------------------------------------
# Mailgraph
# -------------------------------------------------
mailgraph_setup()
{
    ECHO_INFO "Setup mailgraph for mail log monitor."

    cp -f ${SAMPLE_DIR}/mailgraph/mailgraph.cgi ${HTTPD_SERVERROOT}/cgi-bin/
    chmod 0755 ${HTTPD_SERVERROOT}/cgi-bin/mailgraph.cgi

    cp -f ${SAMPLE_DIR}/mailgraph/mailgraph.css ${HTTPD_DOCUMENTROOT}/mailgraph.css

    cp -f ${SAMPLE_DIR}/mailgraph/mailgraph.pl /usr/local/bin/
    chmod 0755 /usr/local/bin/mailgraph.pl

    cp -f ${SAMPLE_DIR}/mailgraph/mailgraph-init /etc/init.d/mailgraph
    chmod 0755 /etc/init.d/mailgraph
    chkconfig --level 35 mailgraph on

    # Create dir to store rrd files.
    # We use /var/lib/mailgraph/ instead of '/var/lib/'.
    mkdir /var/lib/mailgraph/

    if [ X"${USE_EXTMAIL}" == X"YES" ]; then
        chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} \
            ${HTTPD_SERVERROOT}/cgi-bin/ \
            ${HTTPD_SERVERROOT}/cgi-bin/mailgraph.cgi
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
mailgraph:
    * URL:
        - http://$(hostname)/cgi-bin/mailgraph.cgi"
    * See also:
        - /etc/init.d/mailgraph
        - /usr/local/bin/mailgraph.pl
        - ${HTTPD_DOCUMENTROOT}/mailgraph.css
        - /var/lib/mailgraph/

EOF

    echo 'export status_mailgraph_setup="DONE"' >> ${STATUS_FILE}
}
