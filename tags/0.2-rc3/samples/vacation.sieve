#
# Sample dovecot sieve vacation implementment. It should be localted
# at:
#   /home/vmail/domain.ltd/username/.dovecot.sieve
# Replace /home/vmail/ by your mail store directory.
#
# Shipped within iRedMail project:
#   * http://iRedMail.googlecode.com/
#

# For more information, please refer to official documentation and
# RFC:
#   http://wiki.dovecot.org/LDA/Sieve
#   http://www.ietf.org/rfc/rfc5230.txt

require ["vacation"];

if header :contains ["accept-language", "content-language"] "en"
{
    vacation
        # Reply at most once a day to a same sender
        #:days 1
        :subject "Auto-Reply: I'm out of office."
        # List of recipient addresses which are included in the auto replying.
        # If a mail's recipient is not on this list, no vacation reply is sent for it.
        #:addresses ["j.doe@company.dom", "john.doe@company.dom"]
"I'm out of office, i will contact you when i'm back.

----
Best Regards.
";

} else {
    vacation
        # Reply at most once a day to a same sender
        #:days 1

        # Currently, Dovecot won't encode subject, so you can't use
        # Non-English characters in subject field.
        # The easiest way is let your webmail do that.
        :subject "Auto-Reply: I'm out of office."

        # Use 'mime' parameter to compose utf-8 message, you can use
        # Non-English characters in mail body.
        :mime
"MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

I'm out of office.
Here you can write down non-english characters in utf-8.
";
}
