#!/bin/bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Date:     $LastChangedDate: 2008-03-02 21:11:40 +0800 (Sun, 02 Mar 2008) $
# Purpose:  Fetch all extra packages we need to build mail server.

ROOTDIR="$(pwd)"
CONF_DIR="${ROOTDIR}/../conf"

. ${CONF_DIR}/global
. ${CONF_DIR}/functions

FETCH_CMD="wget -cq --referer ${PROG_NAME}-${PROG_VERSION}"

#
# Mirror site.
# Site directory structure:
#
#   ${MIRROR}/
#           |- pkgs/
#               |- 5/
#               |- 6/ (not present yet)
#           |- misc/
#
# You can find nearest mirror in this page:
#   http://code.google.com/p/iredmail/wiki/Mirrors
#
MIRROR='http://www.iredmail.org/yum'

# Where to store binary packages and source tarball.
PKG_DIR="${ROOTDIR}/pkgs"
MISC_DIR="${ROOTDIR}/misc"

if [ X"${DISTRO}" == X"RHEL" ]; then
    export PKGFILE="MD5.rhel"               # File contains MD5.
    export PKGLIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(\.${ARCH}\.|\.noarch\.)" | awk -F'pkgs/' '{print $2}' )"
    export fetch_pkgs="fetch_pkgs_rhel"     # Function used to fetch binary packages.
    export create_repo="create_repo_rhel"   # Function used to create yum repository.

elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
    export PKGFILE="MD5.debian"             # File contains MD5.
    export PKGLIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(_${ARCH}|_all)" | awk -F'pkgs/' '{print $2}' )"
    export fetch_pkgs="fetch_pkgs_debian"   # Function used to fetch binary packages.
    export create_repo="create_repo_debian" # Function used to create apt repository.
else
    :
fi

# Binary packages.
export pkg_total=$(echo ${PKGLIST} | wc -w | awk '{print $1}')
export pkg_counter=1

# Misc file (source tarball) list.
MISCLIST="$(cat ${ROOTDIR}/MD5.misc | awk -F'misc/' '{print $2}')"


mirror_notify()
{
    cat <<EOF
*********************************************************************
**************************** Mirrors ********************************
*********************************************************************
* If you can't fetch packages, please try to use another mirror site
* listed in below url:
*
*   - http://code.google.com/p/iredmail/wiki/Mirrors
*
*********************************************************************
EOF

    echo 'export status_mirror_notify="DONE"' >> ${STATUS_FILE}
}

prepare_dirs()
{
    ECHO_INFO "Creating necessary directories..."
    for i in ${PKG_DIR} ${MISC_DIR}
    do
        [ -d "${i}" ] || mkdir -p "${i}"
    done
}

check_pkg_which()
{
    ECHO_INFO "Checking necessary package: which.${ARCH}..."
    for i in $(echo $PATH|sed 's/:/ /g'); do
        [ -x $i/which ] && export HAS_WHICH='YES'
    done

    if [ X"${HAS_WHICH}" != X'YES' ]; then
        eval ${install_pkg} which.${ARCH}
        if [ X"$?" != X"0" ]; then
            ECHO_INFO "Please install package 'createrepo' first." && exit 255
        else
            echo 'export status_check_pkg_which="DONE"' >> ${STATUS_FILE}
        fi
    else
        :
    fi
}

check_pkg_createrepo()
{
    ECHO_INFO "Checking necessary package: createrepo.noarch..."
    which createrepo >/dev/null 2>&1

    if [ X"$?" != X"0" ]; then
        eval ${install_pkg} createrepo.noarch
        if [ X"$?" != X"0" ]; then
            ECHO_INFO "Please install package 'createrepo' first." && exit 255
        else
            echo 'export status_check_createrepo="DONE"' >> ${STATUS_FILE}
        fi
    else
        :
    fi
}

fetch_pkgs_rhel()
{
    if [ X"${DOWNLOAD_PKGS}" == X"YES" ]; then
        cd ${PKG_DIR}

        for i in ${PKGLIST}; do
            url="${MIRROR}/rpms/5/${i}"
            ECHO_INFO "* ${pkg_counter}/${pkg_total}: ${url}"
            ${FETCH_CMD} ${url}

            pkg_counter=$((pkg_counter+1))
        done
    else
        :
    fi
}

fetch_pkgs_debian()
{
    if [ X"${DOWNLOAD_PKGS}" == X"YES" ]; then
        cd ${PKG_DIR}

        for i in ${PKGLIST}; do
            url="${MIRROR}/apt/debian/lenny/${i}"
            ECHO_INFO "* ${pkg_counter}/${pkg_total}: ${url}"
            ${FETCH_CMD} ${url}

            pkg_counter=$((pkg_counter+1))
        done
    else
        :
    fi
}

fetch_misc()
{
    if [ X"${DOWNLOAD_PKGS}" == X"YES" ]; then
        # Fetch all misc packages.
        cd ${MISC_DIR}

        misc_total=$(echo ${MISCLIST} | wc -w | awk '{print $1}')
        misc_count=1

        ECHO_INFO "==================== Fetching Source Tarballs ===================="

        for i in ${MISCLIST}
        do
            url="${MIRROR}/misc/${i}"
            ECHO_INFO "* ${misc_count}/${misc_total}: ${url}"

            cd ${MISC_DIR}
            ${FETCH_CMD} ${url}

            misc_count=$((misc_count + 1))
        done
    else
        :
    fi
}

check_md5()
{
    cd ${ROOTDIR}

    ECHO_INFO "==================== Validate Packages via md5sum. ===================="

    for i in ${PKGFILE} MD5.misc; do
        ECHO_INFO -n "Validating via file: ${i}..."
        md5sum -c ${ROOTDIR}/${i} |grep 'FAILED'

        if [ X"$?" == X"0" ]; then
            echo -e "\n${INFO_FLAG} MD5 check failed. Check your rpm packages. Script exit...\n"
            exit 255
        else
            echo -e "\t[ OK ]"
            echo 'export status_fetch_pkgs="DONE"' >> ${STATUS_FILE}
            echo 'export status_fetch_misc="DONE"' >> ${STATUS_FILE}
            echo 'export status_check_md5="DONE"' >> ${STATUS_FILE}
        fi
    done
}

create_repo_rhel()
{
    # createrepo
    ECHO_INFO -n "Generating yum repository..."
    cd ${PKG_DIR} && createrepo . >/dev/null 2>&1 && echo -e "\t[ OK ]"

    # Backup old repo file.
    if [ -f ${LOCAL_REPO_FILE} ]; then
        cp ${LOCAL_REPO_FILE} ${LOCAL_REPO_FILE}.${DATE}
    else
        :
    fi

    # Generate new repo file.
    cat > ${LOCAL_REPO_FILE} <<EOF
[${LOCAL_REPO_NAME}]
name=Yum repo generated by ${PROG_NAME}: http://${PROG_NAME}.googlecode.com/
baseurl=file://${PKG_DIR}/
enabled=1
gpgcheck=0
priority=1
EOF

    echo 'export status_create_yum_repo="DONE"' >> ${STATUS_FILE}
}

create_repo_debian()
{
    # Use dpkg-scanpackages to create a local apt repository.
    ECHO_INFO "Generating apt repository..."

    cd ${ROOTDIR} && \
    dpkg-scanpackages ${PKG_DIR} /dev/null | gzip > ${PKG_DIR}/Packages.gz

    ECHO_INFO "Append local repository to /etc/apt/sources.list."
    grep 'iRedMail_Local$' /etc/apt/sources.list
    [ X"$?" != X"0" ] && echo -e "deb file:${PKG_DIR}/ ./   # iRedMail_Local" >> /etc/apt/sources.list
}

echo_end_msg()
{
    cat <<EOF
********************************************************
* All tasks had been finished Successfully. Next step:
*
*   # cd ..
*   # sh ${PROG_NAME}.sh
*
********************************************************

EOF
}

if [ -e ${STATUS_FILE} ]; then
    . ${STATUS_FILE}
else
    echo '' > ${STATUS_FILE}
fi

check_user root && \
check_arch && \
check_status_before_run check_pkg_which && \
check_status_before_run check_pkg_createrepo && \
prepare_dirs && \
ECHO_INFO "==================== Fetching Binary Packages ====================" && \
${fetch_pkgs} && \
fetch_misc && \
check_md5 && \
${create_repo} && \
check_dialog && \
echo_end_msg
