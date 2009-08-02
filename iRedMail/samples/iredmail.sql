#
# Based on original postfixadmin template.
# http://postfixadmin.sf.net
#

#
# Table structure for table admin
#
CREATE TABLE admin (
    username VARCHAR(255) NOT NULL DEFAULT '',
    password VARCHAR(255) NOT NULL DEFAULT '',
    language VARCHAR(255) NOT NULL DEFAULT 'en_US',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table alias
#
CREATE TABLE alias (
    address VARCHAR(255) NOT NULL DEFAULT '',
    goto TEXT NOT NULL,
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (address)
) TYPE=MyISAM;

#
# Table structure for table domain
#
CREATE TABLE domain (
    domain VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    disclaimer TEXT NOT NULL DEFAULT '',
    aliases INT(10) NOT NULL DEFAULT '0',
    mailboxes INT(10) NOT NULL DEFAULT '0',
    maxquota bigINT(20) NOT NULL DEFAULT '0',
    quota bigINT(20) NOT NULL DEFAULT '0',
    transport VARCHAR(255) NOT NULL DEFAULT 'dovecot',
    backupmx TINYINT(1) NOT NULL DEFAULT '0',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table domain_admins
#
CREATE TABLE domain_admins (
    username VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    KEY username (username)
) TYPE=MyISAM;

#
# Table structure for table mailbox
#
CREATE TABLE mailbox (
    username VARCHAR(255) NOT NULL DEFAULT '',
    password VARCHAR(255) NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    storagebasedirectory VARCHAR(255) NOT NULL DEFAULT '',
    maildir VARCHAR(255) NOT NULL DEFAULT '',
    quota BIGINT(20) NOT NULL DEFAULT '0',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    transport VARCHAR(255) NOT NULL DEFAULT 'dovecot',
    department VARCHAR(255) NOT NULL DEFAULT '',
    rank VARCHAR(255) NOT NULL DEFAULT 'normal',
    employeeid VARCHAR(255) DEFAULT NULL,
    enablesmtp TINYINT(1) NOT NULL DEFAULT '1',
    enablepop3 TINYINT(1) NOT NULL DEFAULT '1',
    enableimap TINYINT(1) NOT NULL DEFAULT '1',
    enabledeliver TINYINT(1) NOT NULL DEFAULT '1',
    enablemanagesieve TINYINT(1) NOT NULL DEFAULT '1',
    lastlogindate DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    lastloginipv4 INT(4) UNSIGNED NOT NULL DEFAULT '0',
    lastloginprotocol CHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_domain
#
CREATE TABLE sender_bcc_domain (
    domain VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_user
#
CREATE TABLE sender_bcc_user (
    username VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_domain
#
CREATE TABLE recipient_bcc_domain (
    domain VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_user
#
CREATE TABLE recipient_bcc_user (
    username VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table log
#
CREATE TABLE log (
    TIMESTAMP DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    username VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    action VARCHAR(255) NOT NULL DEFAULT '',
    data VARCHAR(255) NOT NULL DEFAULT '',
    KEY TIMESTAMP (TIMESTAMP)
) TYPE=MyISAM;

#
# WARNING: We do not use postfixadmin style vacation mechanism.
#

#
# Vacation stuff.
#
CREATE TABLE vacation ( 
    email VARCHAR(255) NOT NULL DEFAULT '', 
    subject VARCHAR(255) NOT NULL DEFAULT '', 
    body TEXT NOT NULL, 
    cache TEXT NOT NULL, 
    domain VARCHAR(255) NOT NULL DEFAULT '', 
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00', 
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00', 
    active TINYINT(4) NOT NULL DEFAULT '1', 
    PRIMARY KEY (email), 
    KEY email (email) 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
 
#
# vacation_notification table 
#
 
CREATE TABLE vacation_notification ( 
    on_vacation VARCHAR(255) NOT NULL, 
    notified VARCHAR(255) NOT NULL, 
    notified_at TIMESTAMP NOT NULL DEFAULT now(), 
    CONSTRAINT vacation_notification_pkey PRIMARY KEY(on_vacation, notified), 
    FOREIGN KEY (on_vacation) REFERENCES vacation(email) ON DELETE CASCADE 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
