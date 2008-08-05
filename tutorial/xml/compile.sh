#!/bin/sh

# Author:   Zhang Huangbin
# Mail:     michaelbibby (at) gmail.com
# Date:     2008.08.02
# Purpose:  Compile 'XML' files to 'html' format, used for iRedMail
#           project.
# Note:     Works fine on RHEL 5.x.

# Modify lastest update time.
export UPDATE_TIME="$(/bin/date '+%Y.%m.%d %H:%M')"
perl -pi -e 's#(.*Lastest update time: )(.*)(\..*)#${1}$ENV{UPDATE_TIME}${3}#' bookinfo.xml

xsltproc \
    --stringparam html.stylesheet 'docbook.css' \
    --stringparam admon.graphics 1 \
    --stringparam admon.graphics.extension '.png' \
    --stringparam admon.graphics.path 'images/' \
    --stringparam section.autolabel 1 \
    --stringparam section.label.includes.component.label 1 \
    --stringparam toc.section.depth 8 \
    /usr/share/sgml/docbook/xsl-stylesheets-1.69.1-5.1/html/chunk.xsl \
    iRedMail.xml 


# Browse tutorial directly from '/svn/trunk/tutorial/':
#svn propset svn:mime-type 'text/html' *html
