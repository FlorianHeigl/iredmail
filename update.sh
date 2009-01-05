#!/bin/sh
# Author: atyu30 <iopenbsd (at) gmail.com>
#
#Setting
PC0=`date +%Y%m%d%H%M`
LOG=svnupdate.log
echo $PC0 >> $LOG
svn update >> $LOG
