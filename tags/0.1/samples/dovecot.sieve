#require ["fileinto", "reject"];
require ["fileinto"];

if header :matches ["X-Spam-Flag"] ["YES"] {
    fileinto "Junk";
    # Stop here so that we do not reply to spammers.
    stop;
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
