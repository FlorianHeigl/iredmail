#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

#
# Based on original postfixadmin template.
# http://postfixadmin.sf.net
#

#
# Table structure for table admin
#
CREATE TABLE IF NOT EXISTS admin (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    password VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    language VARCHAR(5) CHARACTER SET ascii NOT NULL DEFAULT 'en_US',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) ENGINE=MyISAM;

#
# Table structure for table alias
#
CREATE TABLE IF NOT EXISTS alias (
    address VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    goto TEXT NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    moderators TEXT NOT NULL DEFAULT '',
    accesspolicy VARCHAR(30) NOT NULL DEFAULT '',
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (address)
) ENGINE=MyISAM;

#
# Table structure for table domain
#
CREATE TABLE IF NOT EXISTS domain (
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    disclaimer TEXT NOT NULL DEFAULT '',
    aliases INT(10) NOT NULL DEFAULT '0',
    mailboxes INT(10) NOT NULL DEFAULT '0',
    maxquota BIGINT(20) NOT NULL DEFAULT '0',
    quota BIGINT(20) NOT NULL DEFAULT '0',
    transport VARCHAR(255) NOT NULL DEFAULT 'dovecot',
    backupmx TINYINT(1) NOT NULL DEFAULT '0',
    defaultuserquota BIGINT(20) NOT NULL DEFAULT '1024',
    defaultuseraliases TEXT NOT NULL DEFAULT '',
    defaultpasswordscheme VARCHAR(10) NOT NULL DEFAULT '',
    minpasswordlength INT(10) NOT NULL DEFAULT '0',
    maxpasswordlength INT(10) NOT NULL DEFAULT '0',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) ENGINE=MyISAM;

CREATE TABLE IF NOT EXISTS `alias_domain` (
    alias_domain VARCHAR(255) CHARACTER SET ascii NOT NULL,
    target_domain VARCHAR(255) CHARACTER SET ascii NOT NULL,
    created datetime NOT NULL default '0000-00-00 00:00:00',
    modified datetime NOT NULL default '0000-00-00 00:00:00',
    active tinyint(1) NOT NULL default '1',
    PRIMARY KEY (alias_domain),
    KEY (target_domain),
    KEY (active)
) ENGINE=MyISAM;

#
# Table structure for table domain_admins
#
CREATE TABLE IF NOT EXISTS domain_admins (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username,domain),
    KEY (username),
    KEY (domain)
) ENGINE=MyISAM;

#
# Table structure for table mailbox
#
CREATE TABLE IF NOT EXISTS mailbox (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL,
    password VARCHAR(255) NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    storagebasedirectory VARCHAR(255) NOT NULL DEFAULT '',
    storagenode VARCHAR(255) NOT NULL DEFAULT '',
    maildir VARCHAR(255) NOT NULL DEFAULT '',
    quota BIGINT(20) NOT NULL DEFAULT 0, -- Total mail quota size
    bytes BIGINT(20) NOT NULL DEFAULT 0, -- Number of used quota size
    messages BIGINT(20) NOT NULL DEFAULT 0, -- Number of current messages
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    transport VARCHAR(255) NOT NULL DEFAULT 'dovecot',
    department VARCHAR(255) NOT NULL DEFAULT '',
    rank VARCHAR(255) NOT NULL DEFAULT 'normal',
    employeeid VARCHAR(255) DEFAULT '',
    enablesmtp TINYINT(1) NOT NULL DEFAULT '1',
    enablesmtpsecured TINYINT(1) NOT NULL DEFAULT '1',
    enablepop3 TINYINT(1) NOT NULL DEFAULT '1',
    enablepop3secured TINYINT(1) NOT NULL DEFAULT '1',
    enableimap TINYINT(1) NOT NULL DEFAULT '1',
    enableimapsecured TINYINT(1) NOT NULL DEFAULT '1',
    enabledeliver TINYINT(1) NOT NULL DEFAULT '1',
    enablemanagesieve TINYINT(1) NOT NULL DEFAULT '1',
    enablemanagesievesecured TINYINT(1) NOT NULL DEFAULT '1',
    enablesieve TINYINT(1) NOT NULL DEFAULT '1',
    enablesievesecured TINYINT(1) NOT NULL DEFAULT '1',
    enableinternal TINYINT(1) NOT NULL DEFAULT '1',
    lastlogindate DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    lastloginipv4 INT(4) UNSIGNED NOT NULL DEFAULT '0',
    lastloginprotocol CHAR(255) NOT NULL DEFAULT '',
    disclaimer TEXT NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    local_part VARCHAR(255) NOT NULL DEFAULT '', -- Required by PostfixAdmin
    PRIMARY KEY (username)
) ENGINE=MyISAM;

#
# IMAP shared folders. User 'from_user' shares folders to user 'to_user'.
# WARNING: Works only with Dovecot 1.2+.
#
CREATE TABLE IF NOT EXISTS share_folder (
  from_user VARCHAR(255) CHARACTER SET ascii NOT NULL,
  to_user VARCHAR(255) CHARACTER SET ascii NOT NULL,
  dummy CHAR(1),
  PRIMARY KEY (from_user, to_user)
);

#
# Table structure for table sender_bcc_domain
#
CREATE TABLE IF NOT EXISTS sender_bcc_domain (
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) ENGINE=MyISAM;

#
# Table structure for table sender_bcc_user
#
CREATE TABLE IF NOT EXISTS sender_bcc_user (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) ENGINE=MyISAM;

#
# Table structure for table recipient_bcc_domain
#
CREATE TABLE IF NOT EXISTS recipient_bcc_domain (
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (domain)
) ENGINE=MyISAM;

#
# Table structure for table recipient_bcc_user
#
CREATE TABLE IF NOT EXISTS recipient_bcc_user (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (username)
) ENGINE=MyISAM;

#
# Table structure for table log. Used in PostfixAdmin.
#
CREATE TABLE IF NOT EXISTS log (
    TIMESTAMP DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    username VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    action VARCHAR(255) NOT NULL DEFAULT '',
    data VARCHAR(255) NOT NULL DEFAULT '',
    KEY TIMESTAMP (TIMESTAMP)
) ENGINE=MyISAM;

#
# WARNING:
# We do not use postfixadmin style vacation mechanism, so below two tables
# are deprecated.
#

#
# Vacation stuff.
#
CREATE TABLE IF NOT EXISTS vacation (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
 
#
# vacation_notification table
#
 
CREATE TABLE IF NOT EXISTS vacation_notification (
    on_vacation VARCHAR(255) NOT NULL,
    notified VARCHAR(255) NOT NULL,
    notified_at TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT vacation_notification_pkey PRIMARY KEY(on_vacation, notified),
    FOREIGN KEY (on_vacation) REFERENCES vacation(email) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
