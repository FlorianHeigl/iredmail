#
# Based on original postfixadmin template.
# http://postfixadmin.sf.net
#

#
# Table structure for table admin
#
CREATE TABLE admin (
    username varchar(255) NOT NULL default '',
    password varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table alias
#
CREATE TABLE alias (
    address varchar(255) NOT NULL default '',
    goto text NOT NULL,
    domain varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (address)
) TYPE=MyISAM;

#
# Table structure for table domain
#
CREATE TABLE domain (
    domain varchar(255) NOT NULL default '',
    description varchar(255) NOT NULL default '',
    aliases int(10) NOT NULL default '0',
    mailboxes int(10) NOT NULL default '0',
    maxquota bigint(20) NOT NULL default '0',
    quota bigint(20) NOT NULL default '0',
    transport varchar(255) NOT NULL default 'dovecot',
    backupmx tinyint(1) NOT NULL default '0',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table domain_admins
#
CREATE TABLE domain_admins (
    username varchar(255) NOT NULL default '',
    domain varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    KEY username (username)
) TYPE=MyISAM;

#
# Table structure for table mailbox
#
CREATE TABLE mailbox (
    username varchar(255) NOT NULL default '',
    password varchar(255) NOT NULL default '',
    name varchar(255) NOT NULL default '',
    maildir varchar(255) NOT NULL default '',
    quota bigint(20) NOT NULL default '0',
    domain varchar(255) NOT NULL default '',
    active tinyint(1) NOT NULL default '1',
    department varchar(255) NOT NULL default '',
    rank varchar(255) NOT NULL default 'normal',
    enablesmtp tinyint(1) NOT NULL default '1',
    enablepop3 tinyint(1) NOT NULL default '1',
    enableimap tinyint(1) NOT NULL default '1',
    enabledeliver tinyint(1) NOT NULL default '1',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_domain
#
CREATE TABLE sender_bcc_domain (
    domain varchar(255) NOT NULL default '',
    bcc_address varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table sender_bcc_user
#
CREATE TABLE sender_bcc_user (
    username varchar(255) NOT NULL default '',
    bcc_address varchar(255) NOT NULL default '',
    domain varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_domain
#
CREATE TABLE recipient_bcc_domain (
    domain varchar(255) NOT NULL default '',
    bcc_address varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (domain)
) TYPE=MyISAM;

#
# Table structure for table recipient_bcc_user
#
CREATE TABLE recipient_bcc_user (
    username varchar(255) NOT NULL default '',
    bcc_address varchar(255) NOT NULL default '',
    domain varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (username)
) TYPE=MyISAM;

#
# Table structure for table log
#
CREATE TABLE log (
    timestamp datetime NOT NULL default '0000-00-00 00:00:00',
    username varchar(255) NOT NULL default '',
    domain varchar(255) NOT NULL default '',
    action varchar(255) NOT NULL default '',
    data varchar(255) NOT NULL default '',
    KEY timestamp (timestamp)
) TYPE=MyISAM;

#
# Table structure for table restriction
#
# Warning: Do *NOT* use primary key here.
#
CREATE TABLE restrictions (
    username varchar(255) NOT NULL default '',
    restriction_class varchar(255) NOT NULL default '',
    restricteddomain varchar(255) NOT NULL default '',
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00'
) TYPE=MyISAM;

#
# WARNING: We do not use postfixadmin style vacation mechanism.
#

#
# Vacation stuff.
#
CREATE TABLE vacation ( 
    email varchar(255) NOT NULL default '', 
    subject varchar(255) NOT NULL default '', 
    body text NOT NULL, 
    cache text NOT NULL, 
    domain varchar(255) NOT NULL default '', 
    created datetime NOT NULL default '0000-00-00 00:00:00', 
    modified datetime NOT NULL default '0000-00-00 00:00:00', 
    active tinyint(4) NOT NULL default '1', 
    PRIMARY KEY (email), 
    KEY email (email) 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
 
#
# vacation_notification table 
#
 
CREATE TABLE vacation_notification ( 
    on_vacation varchar(255) NOT NULL, 
    notified varchar(255) NOT NULL, 
    notified_at timestamp NOT NULL default now(), 
    CONSTRAINT vacation_notification_pkey PRIMARY KEY(on_vacation, notified), 
    FOREIGN KEY (on_vacation) REFERENCES vacation(email) ON DELETE CASCADE 
) TYPE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
