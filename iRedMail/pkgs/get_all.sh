#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Date:     $LastChangedDate: 2008-03-02 21:11:40 +0800 (Sun, 02 Mar 2008) $
# Purpose:  Fetch all extra packages we need to build mail server.

ROOTDIR="$(dirname $0)"
CONF_DIR="${ROOTDIR}/../conf"

. ${CONF_DIR}/global
. ${CONF_DIR}/functions
. ${CONF_DIR}/core

check_user root
check_hostname

FETCH_CMD="wget -cq --referer ${PROG_NAME}-${PROG_VERSION}-${DISTRO}-X${DISTRO_CODENAME}-${ARCH}"

#
# Mirror site.
# Site directory structure:
#
#   ${MIRROR}/
#           |- yum/         # for RHEL/CentOS
#               |- rpms/
#                   |- 5/
#                   |- 6/   # Not present yet.
#               |- misc/    # Source tarballs.
#               |- srpms/   # Source RPMs.
#           |- apt/             # for Debian/Ubuntu
#               |- debian/      # For Debian
#                   |- lenny/   # For Debian (Lenny)
#
# You can find nearest mirror in this page:
#   http://code.google.com/p/iredmail/wiki/Mirrors
#

# Where to store binary packages and source tarball.
PKG_DIR="${ROOTDIR}/pkgs"
MISC_DIR="${ROOTDIR}/misc"

if [ X"${DISTRO}" == X"RHEL" ]; then
    export MIRROR='http://www.iredmail.org/yum'
    export PKGFILE="MD5.rhel"               # File contains MD5.
    export PKGLIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(\.${ARCH}\.|\.noarch\.)" | awk -F'pkgs/' '{print $2}' )"
    export MD5LIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(\.${ARCH}\.|\.noarch\.)" )"
    export fetch_pkgs="fetch_pkgs_rhel"     # Function used to fetch binary packages.
    export create_repo="create_repo_rhel"   # Function used to create yum repository.

    # Special package.
    # command: which.
    export BIN_WHICH='which'
    export PKG_WHICH="which.${ARCH}"
    # command: wget.
    export BIN_WGET='wget'
    export PKG_WGET="wget.${ARCH}"
    # command: createrepo.
    export BIN_CREATEREPO="createrepo"
    export PKG_CREATEREPO="createrepo.noarch"

elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
    export MIRROR='http://www.iredmail.org/apt'

    if [ X"${ARCH}" == X"x86_64" ]; then
        export pkg_arch='amd64'
    else
        export pkg_arch="${ARCH}"
    fi

    if [ X"${DISTRO}" == X"DEBIAN" ]; then
        export PKGFILE="MD5.debian"             # File contains MD5.
        export PKGLIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(_${pkg_arch}|_all)" | awk -F'pkgs/' '{print $2}' )"
        export MD5LIST="$( cat ${ROOTDIR}/${PKGFILE} | grep -E "(_${pkg_arch}|_all)" )"

    fi

    export fetch_pkgs="fetch_pkgs_debian"   # Function used to fetch binary packages.
    export create_repo="create_repo_debian" # Function used to create apt repository.

    # Special package.
    # command: which.
    export BIN_WHICH='which'
    export PKG_WHICH="debianutils"
    # command: wget.
    export BIN_WGET='wget'
    export PKG_WGET="wget"
    # command: dpkg-scanpackages.
    export BIN_CREATEREPO="dpkg-scanpackages"
    export PKG_CREATEREPO="dpkg-dev"
else
    :
fi

# Binary packages.
export pkg_total=$(echo ${PKGLIST} | wc -w | awk '{print $1}')
export pkg_counter=1

# Misc file (source tarball) list.
PKGMISC='MD5.misc'
MISCLIST="$(cat ${ROOTDIR}/${PKGMISC} | awk -F'misc/' '{print $2}')"


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
    ECHO_INFO "Creating necessary directories ..."
    for i in ${PKG_DIR} ${MISC_DIR}
    do
        [ -d "${i}" ] || mkdir -p "${i}"
    done
}

fetch_pkgs_rhel()
{
    if [ X"${DOWNLOAD_PKGS}" == X"YES" ]; then
        cd ${PKG_DIR}

        ECHO_INFO "==================== Fetching Binary Packages ===================="

        for i in ${PKGLIST}; do
            url="${MIRROR}/rpms/5/${i}"
            ECHO_INFO "* ${pkg_counter}/${pkg_total}: ${url}"
            ${FETCH_CMD} "${url}"

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

        if [ X"${PKGLIST}" != X"0" ]; then
            ECHO_INFO "==================== Fetching Binary Packages ===================="
            for i in ${PKGLIST}; do
                if [ X"${DISTRO}" == X"DEBIAN" ]; then
                    url="${MIRROR}/debian/lenny/${i}"
                fi

                ECHO_INFO "* ${pkg_counter}/${pkg_total}: ${url}"
                ${FETCH_CMD} "${url}"

                pkg_counter=$((pkg_counter+1))
            done
        else
            ECHO_INFO "============== Fetching Binary Packages [ SKIP ] =============="
        fi
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

            ${FETCH_CMD} "${url}"

            misc_count=$((misc_count + 1))
        done
    else
        :
    fi
}

check_md5()
{
    cd ${ROOTDIR}

    ECHO_INFO -n "Validate Packages via md5sum ..."

    md5file="$(mktemp)"
    echo -e "${MD5LIST}" > ${md5file}
    cat MD5.misc >> ${md5file}

    md5sum -c ${md5file} |grep 'FAILED' >/dev/null

    if [ X"$?" == X"0" ]; then
        ECHO_ERROR "MD5 check failed. Check your rpm packages. Script exit ...\n"
        exit 255
    else
        echo -e "\t[ OK ]"
        echo 'export status_fetch_pkgs="DONE"' >> ${STATUS_FILE}
        echo 'export status_fetch_misc="DONE"' >> ${STATUS_FILE}
        echo 'export status_check_md5="DONE"' >> ${STATUS_FILE}
    fi

    rm -f ${md5file}
}

create_repo_rhel()
{
    # createrepo
    ECHO_INFO -n "Generating yum repository ..."
    cd ${PKG_DIR} && ${BIN_CREATEREPO} . >/dev/null 2>&1 && echo -e "\t[ OK ]"

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
    ECHO_INFO -n "Generating local apt repository ..."

    # Warning: Use relative path of binary packages.
    cd ${ROOTDIR} && \
    ( ${BIN_CREATEREPO} $(basename ${PKG_DIR}) /dev/null > ${PKG_DIR}/Packages ) 2>/dev/null

    echo -e "\t[ OK ]"

    ECHO_INFO -n "Append local repository to /etc/apt/sources.list ..."
    grep 'iRedMail_Local$' /etc/apt/sources.list >/dev/null
    [ X"$?" != X"0" ] && echo -e "deb file://${ROOTDIR} $(basename ${PKG_DIR})/   # iRedMail_Local" >> /etc/apt/sources.list

    echo -e "\t[ OK ]"

    ECHO_INFO -n "Update apt repository data (apt-get update) ..."
    apt-get update

}

echo_end_msg()
{
    cat <<EOF
********************************************************
* All tasks had been finished Successfully. Next step:
*
*   # cd ..
*   # bash ${PROG_NAME}.sh
*
********************************************************

EOF
}

if [ -e ${STATUS_FILE} ]; then
    . ${STATUS_FILE}
else
    echo '' > ${STATUS_FILE}
fi

prepare_dirs

# Ubuntu 9.04 doesn't need to download extra binary packages.
if [ X"${DISTRO}" != X"UBUNTU" ]; then
    check_pkg ${BIN_WHICH} ${PKG_WHICH} && \
    check_pkg ${BIN_WGET} ${PKG_WGET} && \
    check_pkg ${BIN_CREATEREPO} ${PKG_CREATEREPO} && \
    eval ${fetch_pkgs} && \
    eval ${create_repo}
else
    :
fi

fetch_misc && \
check_md5 && \
check_pkg ${BIN_DIALOG} ${PKG_DIALOG} && \
echo_end_msg
