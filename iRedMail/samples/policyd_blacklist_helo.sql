/*
    Sample iptables rules. It should be localted at:
        /etc/sysconfig/iptables

    Shipped within iRedMail project:
        http://iRedMail.googlecode.com/

    Thanks all contributer(s):
        * muniao <at> gamil.
*/

/*
    This is the real HELO:
        sohu.com    websmtp.sohu.com relay2nd.mail.sohu.com
        126.com     m15-78.126.com
        163.com     m31-189.vip.163.com m13-49.163.com
        sina.com    mail2-209.sinamail.sina.com.cn
        gmail.com   hu-out-0506.google.com

    Some are imported from policyd blacklist_helo.sql.
*/

INSERT INTO blacklist_helo (_helo) VALUES ("sina.com");
INSERT INTO blacklist_helo (_helo) VALUES ("126.com");
INSERT INTO blacklist_helo (_helo) VALUES ("163.com");
INSERT INTO blacklist_helo (_helo) VALUES ("163.net");
INSERT INTO blacklist_helo (_helo) VALUES ("sohu.com");
INSERT INTO blacklist_helo (_helo) VALUES ("yahoo.com.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("yahoo.co.jp");
INSERT INTO blacklist_helo (_helo) VALUES ("wz.com");
INSERT INTO blacklist_helo (_helo) VALUES ("taj-co.com");
INSERT INTO blacklist_helo (_helo) VALUES ("speedtouch.lan");
INSERT INTO blacklist_helo (_helo) VALUES ("dsldevice.lan");
INSERT INTO blacklist_helo (_helo) VALUES ("728154EA470B4AA.com");
INSERT INTO blacklist_helo (_helo) VALUES ("CF8D3DB045C1455.net");
INSERT INTO blacklist_helo (_helo) VALUES ("dsgsfdg.com");
INSERT INTO blacklist_helo (_helo) VALUES ("se.nit7-ngbo.com");
INSERT INTO blacklist_helo (_helo) VALUES ("mail.goo.ne.jp");
INSERT INTO blacklist_helo (_helo) VALUES ("n-ong_an.com");
INSERT INTO blacklist_helo (_helo) VALUES ("e5.il.n5tt.zj.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("meqail.teamefs-ine5tl.com");
INSERT INTO blacklist_helo (_helo) VALUES ("zzg.jhf-sp.com");
INSERT INTO blacklist_helo (_helo) VALUES ("din_glo-ng.net");
INSERT INTO blacklist_helo (_helo) VALUES ("fda-cnc.ie.com");
INSERT INTO blacklist_helo (_helo) VALUES ("yrtaj-yrco.com");
INSERT INTO blacklist_helo (_helo) VALUES ("m.am.biz.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("xr_haig.roup.com");
INSERT INTO blacklist_helo (_helo) VALUES ("hjn.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("we_blf.com.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("netvigator.com");
INSERT INTO blacklist_helo (_helo) VALUES ("mysam.biz");
INSERT INTO blacklist_helo (_helo) VALUES ("mail.teams-intl.com");
INSERT INTO blacklist_helo (_helo) VALUES ("seningbo.com");
INSERT INTO blacklist_helo (_helo) VALUES ("nblf.com.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("kdn.ktguide.com");
INSERT INTO blacklist_helo (_helo) VALUES ("zzsp.com");
INSERT INTO blacklist_helo (_helo) VALUES ("nblongan.com");
INSERT INTO blacklist_helo (_helo) VALUES ("dpu.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("mail.nbptt.zj.cn");
INSERT INTO blacklist_helo (_helo) VALUES ("nbalton.com");
INSERT INTO blacklist_helo (_helo) VALUES ("cncie.com");
INSERT INTO blacklist_helo (_helo) VALUES ("xinhaigroup.com");
INSERT INTO blacklist_helo (_helo) VALUES ("5483e996d84343f.com");
INSERT INTO blacklist_helo (_helo) VALUES ("yeah.net");
