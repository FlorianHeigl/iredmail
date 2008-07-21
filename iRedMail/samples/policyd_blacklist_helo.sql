/*
This is the real HELO:
    sohu.com    websmtp.sohu.com relay2nd.mail.sohu.com
    126.com     m15-78.126.com
    163.com     m31-189.vip.163.com m13-49.163.com
    sina.com    mail2-209.sinamail.sina.com.cn
    gmail.com   hu-out-0506.google.com
*/

USE policyd;

INSERT INTO blacklist_helo (_helo) VALUES ("sina.com");
INSERT INTO blacklist_helo (_helo) VALUES ("126.com");
INSERT INTO blacklist_helo (_helo) VALUES ("163.com");
INSERT INTO blacklist_helo (_helo) VALUES ("sohu.com");
