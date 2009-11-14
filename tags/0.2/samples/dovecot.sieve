#
# Sample dovecot sieve global rules. It should be localted at:
#   /home/vmail/.dovecot.sieve
# Replace /home/vmail/ by your mail store directory.
#
# Shipped within iRedMail project:
#   * http://iRedMail.googlecode.com/
#

# For more information, please refer to official documentation:
# http://wiki.dovecot.org/LDA/Sieve

require ["fileinto", "reject", "include"];

# Personal sieve dir is variable 'sieve_dir' which setting in 
# /etc/dovecot-mysql.conf or /etc/dovecot-ldap.conf.
# Normally, it's user's maildir.

# Vacation.
include :personal ".vacation.sieve";

# User defined sieve rules.
#include :personal ".dovecot.sieve";

# You can include other user defined sieve script here.
#include :personal "sieve_script_name";

# -------------------------------------------------
# --------------- Global sieve rules --------------
# -------------------------------------------------
if header :matches ["X-Spam-Flag"] ["YES"] {
    # If you do not ensure it is really a spam, drop it to 'Junk',
    # and stop here so that we do not reply to spammers.
    #fileinto "Junk";

    # If you want to copy this spam mail to another person, uncomment
    # the below line. More then one people should use another 'redirect'
    # command.
    #redirect "user@domain.ltd";

    # Keep this mail in INBOX.
    keep;

    # Do not waste resource on spam mail.
    stop;

    # If you ensure they are spam, discard it.
    #discard;
}

#
# Mail size control.
#

# Single line.
#if size :over 1M {
#    reject "Mail size is larger than 1MB. Please contact michaelbibby <at> gmail to solve this issue.";
#}

# Multi lines.
#if size: over 2M {
#    reject text:
#Mail size is larger than 1MB.
#Please contact michaelbibby <at> gmail to solve this issue.
#.
#;
#}
