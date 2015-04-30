

**For any issue before or after upgrade, please go to our forum for help: [http://www.iredmail.org/forum/](http://www.iredmail.org/forum/)**

# Fixed issues #
**It's SAFE to apply below fixes.**
| **Date** | **Summary & Link** |
|:---------|:-------------------|
| 2009-08-21 | [Fixed in 0.5.0: per-user mail filter setting](http://www.iredmail.org/forum/topic182-fixed-in-050-peruser-mail-filter-setting.html) |

# Need for more testing #
**DO NOT APPLY BELOW CHANGES IN YOUR PRODUCT SERVER**
  * LDAP backend special: Add missing service control in postfix ldap lookup table. (2009.08.19)
    * Change /etc/postfix/ldap\_virtual\_mailbox\_maps.cf:
```
#query_filter    = (&(objectClass=mailUser)(mail=%s)(accountStatus=active)(enabledService=mail))
query_filter    = (&(objectClass=mailUser)(mail=%s)(accountStatus=active)(enabledService=mail)(enabledService=deliver))
```
