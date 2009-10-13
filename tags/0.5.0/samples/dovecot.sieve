#
# Sample dovecot sieve global rules. It should be localted at:
#   /var/mail/.dovecot.sieve
# Refer to 'sieve_global_path' parameter for the file localtion
# in dovecot.conf on your server.
#
# Shipped within iRedMail project:
#   * http://code.google.com/p/iredmail/
#

# For more information, please refer to official documentation:
# http://wiki.dovecot.org/LDA/Sieve

require ["fileinto", "reject", "include"];

# -------------------------------------------------
# --------------- Global sieve rules --------------
# -------------------------------------------------

# Spam control.
if header :matches ["X-Spam-Flag"] ["YES"] {
    # If you want to copy this spam mail to other people, uncomment
    # the below line.
    # Note: one person, one command.
    #redirect "user1@domain.ltd";
    #redirect "user2@domain.ltd";

    # Keep this mail in INBOX.
    #keep;

    # If you ensure it is really a spam, drop it to 'Junk', and stop
    # here so that we do not reply to spammers.
    fileinto "Junk";

    # Do not waste resource on spam mail.
    stop;

    # If you ensure they are spam, you can discard it.
    #discard;
}
