require ["fileinto", "reject"];

if header :matches ["X-Spam-Flag"] ["YES"] {
    # If you do not ensure it is really a spam, drop it to 'Junk',
    # and stop here so that we do not reply to spammers.
    #fileinto "Junk";
    keep;
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
