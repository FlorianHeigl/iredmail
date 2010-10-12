#
# realtime_quota. Used for Dovecot to store realtime quota.
#
CREATE TABLE IF NOT EXISTS realtime_quota (
    `username` VARCHAR(128) NOT NULL,
    `path` VARCHAR(100) NOT NULL,
    `current` BIGINT(20) DEFAULT '0',
    PRIMARY KEY  (`username`, `path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
