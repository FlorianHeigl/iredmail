#!/usr/bin/env python
# encoding: utf-8

import os
import sys
import re
from random import randrange

# For email parse.
import email
from email.Header import decode_header
from email.Iterators import typed_subpart_iterator
from email.Utils import getaddresses

# ---- Date format process. ----
import time

# For web/URL process.
import urllib
import urllib2

# For XML parse.
import xml.dom.minidom

# Use ClientForm to upload attachments.
import ClientForm

# Global variables.
mailTimeFormat = "%Y%m%d%H%M%S"
dirTimeFormat = "%Y%m%d"
mailTextForwardURL = 'http://www.g5yp.com/email/mail_text_fwd.aspx'
mailAttachForwardURL = 'http://www.g5yp.com/email/mail_attach_fwd.aspx'
mailMIMEForwardURL = 'http://www.g5yp.com/email/mail_mime_fwd.aspx'

# Support format. This is regular express: filename end with: jpg, png, etc.
supportFormat = r'(jpeg|jpg|png|gif|bmp|wav|3gp)$'
attachmentDir = '/tmp/attachments/' + str(time.strftime(dirTimeFormat, time.localtime()))

# Enable MIME forward: YES || NO.
_uploadMIME = 'YES'
#_uploadMIME = 'NO'

randomLimit = int(999999999)
counter = 0
parts = []
attachList = []

def writeFullOrigMailToDisk(msg, mailFilePath):
    """Write original email."""

    try:
        f = open(mailFilePath, 'wb')
        f.write(msg.as_string())
        f.close()
    except Exception, e:
        print "Error write full original mail to disk in func writeFullOrigMailToDisk: ", e

def writeOrigAttachmentToDisk(msg, filename):
    try:
        origAttachmentFilename = msg.get_filename()

        attachmentFilename = attachmentDir + '/' \
                + attachmentPrefix + '-' \
                + str(mid) + '-' \
                + str(i) + '-' \
                + str(origAttachmentFilename)
        a = open(filename, 'wb')
        a.write(msg.get_payload(decode=1))
        a.close()
    except Exception, e:
        print "Error write original attachment to disk in func writeOrigAttachmentToDisk: ", e

def getDecodeHeader(header_text, default='ascii'):
    """Decode the specified header"""

    try:
        headers = decode_header(header_text)
        header_sections = [unicode(text, charset or default) for text, charset in headers]
        return u"".join(header_sections)
    except Exception, e:
        print "Error get decode header in func getDecodeHeader: ", e

def getMailBodyCharset(message, default="ascii"):
    """Get the message charset"""

    try:
        if message.get_content_charset():
            return message.get_content_charset()

        if message.get_charset():
            return message.get_charset()

        return default
    except Exception, e:
        print "Error get mail body charset in func getMailBodyCharset: ", e

def getMailBodyContent(message):
    """Get the body of the email message"""

    try:
        if message.is_multipart():
            #get the plain text version only
            text_parts = [part
                          for part in typed_subpart_iterator(message,
                                                             'text',
                                                             'plain')]
            body = []
            for part in text_parts:
                charset = getMailBodyCharset(part, getMailBodyCharset(message))
                body.append(unicode(part.get_payload(decode=True),
                                    charset,
                                    "replace"))

            return u"\n".join(body).strip()

        else: # if it is not multipart, the payload will be a string
              # representing the message body
            body = unicode(message.get_payload(decode=True),
                           getMailBodyCharset(message),
                           "replace")
        return body.strip()
    except Exception, e:
        print "Error get mail body content in func getMailBodyContent: ", e

def getAddresses(msg, header_field):
    """Get mail address. Support only 'from', 'to', 'cc'."""

    try:
        if msg.has_key(header_field):
            counter = 1
            addresses = ''
            fieldValues = getaddresses(msg.get_all(header_field))

            for i in fieldValues:
                if counter > 1:
                    addresses += ','

                addresses += i[1].lower()
                counter += 1
            
            return addresses
        else:
            return "None"
    except Exception, e:
        print "Error get address in func getAddresses: ", e

def getAttachment(msg):
    """Get mail attachment."""

    global counter
    global attachList
    global parts

    try:
        if msg.is_multipart():
            for item in msg.get_payload():
                getAttachment(item)
        else:
            disp = [counter]

            # 'content-location' is used in MMS mail.
            if 'content-location' in msg and re.match('image/', msg['content-type'].split()[0]):
                disp.append(msg['content-location'])

            # 'content-disposition' is used in normail mail.
            if 'content-disposition' in msg and msg.get_filename():
                disp.append(msg['content-disposition'])

            if len(disp) == 1:
                pass
            else:
                attachList.append(disp)
                parts.append(msg)
                counter += 1

            # Debug.
            #print "disp: ", disp
            #print "attachList: ", attachList
    except Exception, e:
        print "Error get mail attachment in func getAttachment: ", e

def uploadAttachment(url, attachment, mid, index=None):
    """Upload Attachment via URL."""

    attachment = attachment.lower()
    # ---- DEBUG ----
    #print "Upload attachment: ", attachment
    # ---- DEBUG ----
    try:
        r = urllib2.urlopen(url)
        forms = ClientForm.ParseResponse(r, backwards_compat=False)
        r.close()

        form = forms[0]
        form['mid'] = str(mid)
        if index:
            form['index'] = str(index)
        filename = attachment

        f = open(filename)
        form.add_file(f, 'application/octet-stream', attachment)
        r2 = urllib2.urlopen(form.click())
        r2.close()
    except Exception, e:
        print "Error upload attachment in func uploadAttachment: ", e

def getXMLTagValue(xmlString, tag):
    """Parse responsed XML string and get tag number."""

    # Debug.
    #print xmlString

    try:
        dom = xml.dom.minidom.parseString(xmlString)
        root = dom.documentElement
        node = root.getElementsByTagName(tag)[0]
        nodeText = ""
        for node in node.childNodes:
            if node.nodeType in ( node.TEXT_NODE, node.CDATA_SECTION_NODE):
                nodeText = nodeText + node.data
        return nodeText
    except Exception, e:
        print "Error get XML tag value in func getXMLTagValue: \n", e

def uploadMailHeader(url, xmlTag='mid'):
    try:
        # ---- DEBUG ----
        #print "uploadMailHeader"
        #print "uploadMailHeader URL: ", url
        #print "Response XML: ", response_xml
        # ---- DEBUG ----

        response_xml = urllib.urlopen(url).read()
        mid = str(getXMLTagValue(response_xml, xmlTag))
        return mid
    except Exception, e:
        print "Error upload mail header in func uploadMailHeader: \n", e

# Create directory to store attachments.
if not os.path.isdir(attachmentDir):
    #os.remove(attachmentDir)
    os.makedirs(attachmentDir)

# Read mail from Postfix pipe.
msg = email.message_from_file(sys.stdin)

# ---- DEBUG ----
#print getDecodeHeader(msg['X-Mms-Message-ID'])
# ---- DEBUG ----

# Get mail header fields.
# We need to convert string to 'utf-8' encode.
mailSubject = getDecodeHeader(msg['subject']).encode('utf-8')

# Get mail header field: 'from'.
mailFrom = getAddresses(msg, 'from')

# Get mail header field: 'to'.
mailTo = getAddresses(msg, 'to')
username, domain = mailTo.split('@', 1)
attachmentPrefix = str(username) + '-' \
        + str(domain) + '-' \
        + str(time.strftime(mailTimeFormat, time.localtime())) + '-' \
        + str(randrange(randomLimit)) + '-' \
        + str(randrange(randomLimit))

# Get mail header field: 'cc'.
mailCc = getAddresses(msg, 'cc')

# Get date time. We need to format the orig date string.
date = email.Utils.mktime_tz(email.Utils.parsedate_tz(msg['date']))
mailDate = time.strftime(mailTimeFormat, time.localtime(date))

# Get mail body.
mailBody = getMailBodyContent(msg).encode('utf-8')

# Generate URL values.
# Post data will be:
# http://www.xxxx.com/your_page.aspx?email=mailTo&subject=mailSubject&from=mailFrom&body=mailBody
values = { 'email': mailTo,
        'subject': mailSubject,
        'from': mailFrom,
        'to': mailTo,
        'cc': mailCc,
        'body': mailBody,
        }

# Encode URL and fetch response page.
# Response page should be wrote in standard XML format.
urlValues = urllib.urlencode(values)
fullURL = mailTextForwardURL + '?' + urlValues
#fullURL.replace('<', '&lt;')
#fullURL.replace('>', '&gt;')
#print fullURL

mid = uploadMailHeader(fullURL, xmlTag='mid')

if mid:
    pass
else:
    sys.exit(255)

if _uploadMIME == 'YES':
    origMailFile = attachmentDir + '/' + attachmentPrefix + '.eml'

    # Write original email to disk.
    writeFullOrigMailToDisk(msg, origMailFile)

    attachmentValues = { 'mid': mid, }
    uploadMIMEurl = mailMIMEForwardURL + '?' + urllib.urlencode(attachmentValues)
    uploadAttachment(uploadMIMEurl, origMailFile, mid)

# Get attachment list.
getAttachment(msg)

index = 0

for i in range(len(parts)):
    msg = parts[i]

    if msg.get_filename():
        #
        # If this mail was sent by an normail MUA, such as thunderbird
        # or other webmail, it will has 'get_filename()' method."""
        #
        # ---- DEBUG ----
        #print msg.get_filename()
        # ---- DEBUG ----

        filename = msg.get_filename().replace('\n', '')
        filename = filename.lower()

        if re.search(supportFormat, filename):
            try:
                # Get and define attachment filename.
                attachmentFilename = attachmentDir + '/' \
                        + attachmentPrefix + '-' \
                        + str(mid) + '-' \
                        + str(i) + '-' \
                        + str(randrange(randomLimit)) + '-' \
                        + str(randrange(randomLimit)) + '-' \
                        + filename

                # Write attachment to disk.
                writeOrigAttachmentToDisk(msg, attachmentFilename)

                attachmentValues = {'mid': mid, 'index': index,}

                mailAttachForwardURL = mailAttachForwardURL + '?' + urllib.urlencode(attachmentValues)
                result = uploadAttachment(mailAttachForwardURL, attachmentFilename, mid, index)
                index += 1
            except Exception, e:
                print "Error get attachment filename and forward attachment to URL: \n", e
        else:
            #print "Attachment file format is not support."
            pass
    else:
        #
        # This mail may be sent via cell phone.
        #

        # ---- DEBUG ----
        #print attachList
        # ---- DEBUG ----

        try:
            for attachment in attachList:
                # Define attachment filename.
                attachmentFilename = attachmentDir + '/' \
                        + attachmentPrefix + '-' \
                        + str(mid) + '-' \
                        + str(i) + '-' \
                        + str(randrange(randomLimit)) + '-' \
                        + str(randrange(randomLimit)) + '-' \
                        + attachment[-1].lower()    # Filename

                # Write attachment to disk.
                writeOrigAttachmentToDisk(msg, attachmentFilename)

                attachmentValues = {'mid': mid, 'index': index,}

                mailAttachForwardURL = mailAttachForwardURL + '?' + urllib.urlencode(attachmentValues)
                result = uploadAttachment(mailAttachForwardURL, attachmentFilename, mid, index)
                index += 1
        except Exception, e:
            print "Error get attachList filename and forward attachment to URL: \n", e
