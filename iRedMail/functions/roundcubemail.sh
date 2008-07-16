# -----------------------
# Roundcube.
# -----------------------
rcm_install()
{
    cd ${MISC_DIR}

    # Extract source tarball.
    extract_pkg ${RCM_TARBALL} ${HTTPD_SERVERROOT}

    ECHO_INFO "Set correct permission for Roundcubemail: ${RCM_HTTPD_ROOT}."
    chown -R root:root ${RCM_HTTPD_ROOT}
    chown -R apache:apache ${RCM_HTTPD_ROOT}/{temp,logs}
    chmod 0000 ${RCM_HTTPD_ROOT}/{CHANGELOG,INSTALL,LICENSE,README,UPGRADING,installer,SQL}

    echo 'export status_rcm_install="DONE"' >> ${STATUS_FILE}
}

rcm_config()
{
    ECHO_INFO "Import MySQL database and privileges for Roundcubemail."

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWD} <<EOF
/* Create database and grant privileges. */
CREATE DATABASE ${RCM_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${RCM_DB}.* TO ${RCM_DB_USER}@localhost IDENTIFIED BY '${RCM_DB_PASSWD}';


/* Import Roundcubemail SQL template. */
USE ${RCM_DB};
SOURCE ${RCM_HTTPD_ROOT}/SQL/mysql5.initial.sql;

/*
  Grant privileges for Roundcubemail, so that user can change
  their own password and setting mail forwarding.
*/
GRANT UPDATE,SELECT ON ${VMAIL_DB}.mailbox TO ${RCM_DB_USER}@localhost;
GRANT INSERT,UPDATE,SELECT ON ${VMAIL_DB}.alias TO ${RCM_DB_USER}@localhost;

FLUSH PRIVILEGES;
EOF

    ECHO_INFO "Configure database for Roundcubemail: ${RCM_HTTPD_ROOT}/config/*."
    cd ${RCM_HTTPD_ROOT}/config/
    cp -f db.inc.php.dist db.inc.php
    cp -f main.inc.php.dist main.inc.php

    cd ${RCM_HTTPD_ROOT}/config/
    if [ X"${BACKEND}" == X"MySQL" ]; then
        perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"mysql://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'RCM_DB'}";#' db.inc.php
    else
        :
    fi

    perl -pi -e 's#(.*default_host.*= )(.*)#${1}"$ENV{'IMAP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_server.*= )(.*)#${1}"$ENV{'SMTP_SERVER'}";#' main.inc.php
    perl -pi -e 's#(.*smtp_user.*= )(.*)#${1}"%u";#' main.inc.php
    perl -pi -e 's#(.*smtp_pass.*= )(.*)#${1}"%p";#' main.inc.php
    perl -pi -e 's#(.*smtp_auth_type.*= )(.*)#${1}"LOGIN";#' main.inc.php
    perl -pi -e 's#(.*create_default_folders.*)(FALSE)(.*)#${1}TRUE${3}#' main.inc.php

    # Set defeault domain.
    perl -pi -e 's#(.*username_domain.*=)(.*)#${1} "$ENV{FIRST_DOMAIN}";#' main.inc.php
    perl -pi -e 's#(.*locale_string.*)(en)(.*)#${1}$ENV{RCM_DEFAULT_LOCALE}${3}#' main.inc.php
    perl -pi -e 's#(.*timezone.*)(intval.*)#${1}8; //${2}#' main.inc.php
    perl -pi -e 's#(.*enable_spellcheck.*)(TRUE)(.*)#${1}FALSE${3}#' main.inc.php
    perl -pi -e 's#(.*default_charset.*=)(.*)#${1}"UTF-8";#' main.inc.php

    # Set useragent, add project info.
    perl -pi -e 's#(.*rcmail_config.*useragent.*=).*#${1} "RoundCube WebMail";#' main.inc.php

    ECHO_INFO "Create directory alias for Roundcubemail."
    cat > ${HTTPD_CONF_DIR}/roundcubemail.conf <<EOF
${CONF_MSG}
Alias /mail "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
Alias /webmail "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
Alias /roundcube "${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/"
EOF

    # Roundcubemail-0.1.1 only.
    ECHO_INFO "Patch: Add missing localization items for zh_CN."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/zh_CN.labels.inc.patch >/dev/null

    ECHO_INFO "Patch: Fix IMAP folder name with Chinese characters."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_national_imap_folder_name.patch >/dev/null

    ECHO_INFO "Patch: Attachment display and save with Chiense characters."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_PEAR_Mail_Mail_Mime_addAttachment_basename.patch >/dev/null

    ECHO_INFO "Patch: Change Password and Setting Mail Forwarding."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_chpwd_forward.patch >/dev/null

    cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_chpwd_forward_skins.patch >/dev/null

    ECHO_INFO "Patch: Performance Improvement for Roundcubemail-0.1.1."
    cd ${RCM_HTTPD_ROOT} && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/performance-jh1.diff >/dev/null

    ECHO_INFO "Add another skin and icon set: default-labels."
    extract_pkg ${MISC_DIR}/roundcubemail-0.1.1-skin-default-labels.tar.bz2 ${RCM_HTTPD_ROOT}/skins/ && \
    extract_pkg ${MISC_DIR}/roundcubemail-0.1.1-buttons-zh_CN.tar.bz2 ${RCM_HTTPD_ROOT}/skins/default-labels/images/ && \
    cd ${RCM_HTTPD_ROOT}/skins/default-labels/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/roundcubemail-0.1.1_chpwd_forward_skins.patch >/dev/null && \
    cp -f ${RCM_HTTPD_ROOT}/skins/default/{colorpicker,editor_ui,editor_content}.css ${RCM_HTTPD_ROOT}/skins/default-labels/ && \
    perl -pi -e 's#(.*rcmail_config.*skin_path.*=).*#${1} "skins/default-labels/";#' ${RCM_HTTPD_ROOT}/config/main.inc.php
    # In Roundcubemail-0.2, option 'skin_path' was replaced by 'skin'!
    #perl -pi -e 's#(.*rcmail_config.*skin.*=).*#${1} "default-labels";#' ${RCM_HTTPD_ROOT}/config/main.inc.php

    ECHO_INFO "Patch: Display Username."
    cd ${RCM_HTTPD_ROOT}/skins/default/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/display_username.patch >/dev/null && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/display_username_skin_default.patch >/dev/null

    cd ${RCM_HTTPD_ROOT}/skins/default-labels/ && \
    patch -p0 < ${PATCH_DIR}/roundcubemail/display_username.patch >/dev/null

    cat >> ${TIP_FILE} <<EOF
WebMail(Roundcubemail):
    * Configuration files:
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/config/
    * URL:
        - http://$(hostname)/mail/
        - http://$(hostname)/webmail/
    * See also:
        - ${HTTPD_CONF_DIR}/roundcubemail.conf
        - ${RCM_HTTPD_ROOT}/skins/${rcm_skin_cn}

EOF

    echo 'export status_rcm_config="DONE"' >> ${STATUS_FILE}
}
