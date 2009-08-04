# CREATE DATABASE iredadmin DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
# GRANT INSERT,UPDATE,DELETE,SELECT on iredadmin.* to iredadmin@localhost identified by 'secret_passwd';
#USE iredadmin;

CREATE TABLE sessions (
    session_id CHAR(128) UNIQUE NOT NULL,
    atime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data TEXT);

CREATE TABLE log (
    timestamp DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    username VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    action VARCHAR(255) NOT NULL DEFAULT '',
    data VARCHAR(255) NOT NULL DEFAULT '',
    KEY TIMESTAMP (TIMESTAMP)
) TYPE=MyISAM;

