#
# Based on original postfixadmin template.
# http://postfixadmin.sf.net
#

#
# Table structure for table admin
#
CREATE TABLE admin (
    username varchar(255) NOT NULL DEFAULT '',
    password varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table alias
#
CREATE TABLE alias (
    address varchar(255) NOT NULL DEFAULT '',
    goto text NOT NULL,
    domain varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (address)
) TYPE=MyISAM;

#
# Table structure for table domain
#
CREATE TABLE domain (
    domain varchar(255) NOT NULL DEFAULT '',
    description varchar(255) NOT NULL DEFAULT '',
    aliases int(10) NOT NULL DEFAULT '0',
    mailboxes int(10) NOT NULL DEFAULT '0',
    maxquota bigint(20) NOT NULL DEFAULT '0',
    quota bigint(20) NOT NULL DEFAULT '0',
    transport varchar(255) NOT NULL DEFAULT 'dovecot',
    backupmx tinyint(1) NOT NULL DEFAULT '0',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table domain_admins
#
CREATE TABLE domain_admins (
    username varchar(255) NOT NULL DEFAULT '',
    domain varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    KEY username (username)
) TYPE=MyISAM;

#
# Table structure for table mailbox
#
CREATE TABLE mailbox (
    username varchar(255) NOT NULL DEFAULT '',
    password varchar(255) NOT NULL DEFAULT '',
    name varchar(255) NOT NULL DEFAULT '',
    storagebasedirectory varchar(255) NOT NULL DEFAULT '',
    maildir varchar(255) NOT NULL DEFAULT '',
    quota bigint(20) NOT NULL DEFAULT '0',
    domain varchar(255) NOT NULL DEFAULT '',
    department varchar(255) NOT NULL DEFAULT '',
    rank varchar(255) NOT NULL DEFAULT 'normal',
    employeeid varchar(255) DEFAULT NULL,
    enablesmtp tinyint(1) NOT NULL DEFAULT '1',
    enablepop3 tinyint(1) NOT NULL DEFAULT '1',
    enableimap tinyint(1) NOT NULL DEFAULT '1',
    enabledeliver tinyint(1) NOT NULL DEFAULT '1',
    enableforward tinyint(1) NOT NULL DEFAULT '1',
    enablesieve tinyint(1) NOT NULL DEFAULT '1',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_domain
#
CREATE TABLE sender_bcc_domain (
    domain varchar(255) NOT NULL DEFAULT '',
    bcc_address varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_user
#
CREATE TABLE sender_bcc_user (
    username varchar(255) NOT NULL DEFAULT '',
    bcc_address varchar(255) NOT NULL DEFAULT '',
    domain varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_domain
#
CREATE TABLE recipient_bcc_domain (
    domain varchar(255) NOT NULL DEFAULT '',
    bcc_address varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_user
#
CREATE TABLE recipient_bcc_user (
    username varchar(255) NOT NULL DEFAULT '',
    bcc_address varchar(255) NOT NULL DEFAULT '',
    domain varchar(255) NOT NULL DEFAULT '',
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired datetime NOT NULL DEFAULT '9999-12-31 00:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table log
#
CREATE TABLE log (
    timestamp datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    username varchar(255) NOT NULL DEFAULT '',
    domain varchar(255) NOT NULL DEFAULT '',
    action varchar(255) NOT NULL DEFAULT '',
    data varchar(255) NOT NULL DEFAULT '',
    KEY timestamp (timestamp)
) TYPE=MyISAM;

#
# WARNING: We do not use postfixadmin style vacation mechanism.
#

#
# Vacation stuff.
#
CREATE TABLE vacation ( 
    email varchar(255) NOT NULL DEFAULT '', 
    subject varchar(255) NOT NULL DEFAULT '', 
    body text NOT NULL, 
    cache text NOT NULL, 
    domain varchar(255) NOT NULL DEFAULT '', 
    created datetime NOT NULL DEFAULT '0000-00-00 00:00:00', 
    modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00', 
    active tinyint(4) NOT NULL DEFAULT '1', 
    PRIMARY KEY (email), 
    KEY email (email) 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
 
#
# vacation_notification table 
#
 
CREATE TABLE vacation_notification ( 
    on_vacation varchar(255) NOT NULL, 
    notified varchar(255) NOT NULL, 
    notified_at timestamp NOT NULL DEFAULT now(), 
    CONSTRAINT vacation_notification_pkey PRIMARY KEY(on_vacation, notified), 
    FOREIGN KEY (on_vacation) REFERENCES vacation(email) ON DELETE CASCADE 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
