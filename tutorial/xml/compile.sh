#!/bin/sh

# Author:   Michael Bibby
# Mail:     michaelbibby (at) gmail (dot) com
# Date:     2008.01.24
# Purpose:  Compile 'XML' files to 'html' format.

xsltproc \
    --stringparam html.stylesheet docbook.css \
    --stringparam admon.graphics 1 \
    --stringparam admon.graphics.extension '.png' \
    --stringparam admon.graphics.path 'images/' \
    --stringparam section.autolabel 1 \
    --stringparam section.label.includes.component.label 1 \
    --stringparam toc.section.depth 8 \
    /usr/share/sgml/docbook/xsl-stylesheets-1.69.1-5.1/html/chunk.xsl \
    Mail_Server_Solution_for_OpenBSD.xml 
