#summary iRedOS Installation Guide

```
***************************** WARNING ********************************
* We don't provide ISO image of iRedOS anymore, please use kickstart *
* file instead. It's the easiest and fastest way to install the      *
* latest iRedMail on Red Hat Enterprise Linux and CentOS.            *
* Read more: http://www.iredmail.org/forum/topic1890.html            *
***************************** WARNING ********************************
```



# Get Installation Media #

  * Download lastest version of iRedOS iso image from [Mirror site](Mirrors.md), file size is about 420M：
```
http://www.iredmail.org/iRedOS/
```

  * Check md5 before you go further.
    * You can use [WinMD5](http://www.blisstonia.com/software/WinMD5/) (free software) on Windows to validate MD5 value.
    * You can use 'md5sum' command on Linux:
```
# md5sum iRedOS-0.1.2-i386.iso
```
    * You can use 'md5' command on BSD:
```
# md5 iRedOS-0.1.2-i386.iso
```

  * If md5 check is pass, use Nero/K3B/cdrecord or other tools to burn the ISO image for operating system installation.

# iRedOS Installation Details #

```
Note: Please refer to */root/iRedMail.tips* for all related configure files after you complete installation.
```

  * Use the CD you burned to boot your server, and start it from CDROM. It will show the welcome screen:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_boot.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_boot.png)

  * Type 'Enter', it will prompt for hard disk partition:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_partition.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_partition.png)

  * After you disk partition, you should configure network setting and hostname.
> > Note: Hostname must be Fully qualified domain name, e.g. mail.iredmail.org, www.example.com, etc.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_network.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_network.png)

  * Time Zone:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_timezone.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_timezone.png)

  * root password.
> > Warning: It will start to format hard disk and install packages after you click 'Next'.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_rootpasswd.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_rootpasswd.png)

  * Installing packages:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_installing.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_installing.png)

  * It will start iRedMail installation wizard after system installation complete:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_post.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_post.png)

  * Welcome page of iRedMail installation wizard:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_welcome.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_welcome.png)

  * Choose the directory which used to store users' mailbox.
> > Warning: It will take many disk space if users store their mail on mail server, e.g. users use webmail only or use IMAP protocol in their mail user agent only.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_home_vmail.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_home_vmail.png)

  * Choose backend to store virtual domains and virtual users.
> > Note: Please choose the one you are familiar. Here we use MySQL for example.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_backend.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_backend.png)

  * Set MySQL root password:

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_mysql_rootpw.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_mysql_rootpw.png)

  * Set MySQL account 'vmailadmin' password.
> > Note: vmailadmin is used for manage all virtual domains & users, so that you don't need MySQL root privileges.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_vmailadmin_pw.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_vmailadmin_pw.png)

  * Set first virtual domain. e.g. iredmail.org, example.com, etc.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_first_domain.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_first_domain.png)

  * Set admin user for first virtual domain you set above. e.g. **postmaster**.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_admin_name.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_admin_name.png)

  * Set password for admin user you set above.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_admin_pw.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_admin_pw.png)

  * Set first normal user. e.g. **www**.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_normal_user_name.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_normal_user_name.png)

  * Set password for normal user you set above.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_normal_user_pw.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_normal_user_pw.png)

  * Enable SPF Validation, DKIM signing/verification or not.
> > Note:
    * We recommended you set SPF dns record for your domain not matter you choose SPF valication feature or not.
    * If you enable DKIM signing and verification feature, you must set DKIM dns record for your domain.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_spf_dkim.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_spf_dkim.png)

  * Enable managesieve service or not. It's used for your mail user to customize mail filter rules, vacation, mail forwarding. It's recommended.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_managesieve.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_managesieve.png)

  * Enable POP3, POP3S, IMAP, IMAPS services or not.
> > Note: If you don't enable one of these features, it will install 'procmail' program for local mail deliver.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_pop3_imap.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_pop3_imap.png)

  * Choose your prefer webmail programs.
> > Tip: If you use OpenLDAP as backend above, Roundcube, Horde webmail will use OpenLDAP as global LDAP address book by default.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_webmail.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_webmail.png)

  * Choose optional components. It's recommended you choose all.
    * phpMyAdmin: web-based MySQL database management.
    * Awstats: apache and postfix log file analyzer.
    * Mailgraph: simple mail statistics RRDtool frontend for Postfix and Sendmail that produces daily, weekly, monthly and yearly graphs of received/sent and bounced/rejected mail.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_optional_components.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_optional_components.png)

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_postfixadmin_user.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_postfixadmin_user.png)

  * If you choose Awstats as log analyzer, you will be prompted to set a username and password.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_awstats_pw.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_awstats_pw.png)

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_awstats_user.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_awstats_user.png)

  * Set mail alias address for root user in operation system.
> > Warning: It must be a validate email addres, and it's not recommended you use the address which hosted in your mail server.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_root_alias.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_root_alias.png)

  * After above settings, it will install and configure packages automaticlly.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_install_pkgs.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_install_pkgs.png)

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_config_setting.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/iredmail_config_setting.png)

  * It will return to system installation wizard page when it complete configuration.

![http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_reboot.png](http://screenshots.iredmail.googlecode.com/hg/iredmail/iredos/os_reboot.png)

  * Reboot your system and enjoy.