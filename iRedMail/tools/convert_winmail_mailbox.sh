#!/bin/sh

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com )
# Date:     2008.06.11
# Purpose:  Convert WinMail user mailboxs to standard IMAP directory structure.

# Migration guide wrote in Chinese:
#   http://code.google.com/p/iRedMail/wiki/iRedMail_tut_Migration

# Usage:

# Your original WinMail user mailboxes.
source_dir='./'
# Copy to another directory, converted as standard IMAP directory structure.
target_dir='./'

for i in $(ls -d *@w-ibeda.com)
do
    username="$(echo $i | awk -F'@' '{print $1}')"
    domain="$(echo $i | awk -F'@' '{print $2}')"
    mailbox="${target_dir}/$domain/$username/"
    
    #mailbox="$(echo $i | awk -F'@' '{print $1"/"$2"/"}')"

    # Create necessary directories as mailbox format.
    # Inbox.
    mkdir -p ${mailbox}/{cur,new,tmp}
    # Sent,Junk,Drafts,Trash
    mkdir -p ${mailbox}/.{Sent,Junk,Drafts,Trash}/{cur,new,tmp}

    find_dir="${source_dir}/$i/"

    # Copy inbox.
    for email in $(find ${find_dir} -iname '*.in')
    do
        cp -f $email ${mailbox}/cur/
    done

    # Copy deleted mails.
    for email in $(find ${find_dir} -iname '*.del')
    do
        cp -f $email ${mailbox}/.Trash/
    done

    # Copy sent mails.
    for email in $(find ${find_dir} -iname '*.out')
    do
        cp -f $email ${mailbox}/.Sent/
    done
done
