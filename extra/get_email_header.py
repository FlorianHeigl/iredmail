#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

import sys

# For email parse.
import email
from email.Header import decode_header
from email.Message import Message
#from email.Iterators import typed_subpart_iterator
#from email.Utils import getaddresses

def getDecodeHeader(header_text, default='ascii'):
    """Decode the specified header.
    """

    try:
        headers = decode_header(header_text)
        header_sections = [unicode(text, charset or default) for text, charset in headers]
        return u"".join(header_sections)
    except Exception, e:
        print "Error get decode header in func getDecodeHeader: ", e


msg = email.message_from_file(sys.stdin)
print getDecodeHeader(msg['X-Mozilla-Status'])
