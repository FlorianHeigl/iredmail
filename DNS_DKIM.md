#summary How to Setup DNS record for DKIM
#labels DNS,DKIM

## How to Setup DNS record for DKIM ##

After installation, please reboot your system, then use amavisd to help you setup DNS record.

  * Run command in terminal to show your DKIM keys:
```
# amavisd showkeys
dkim._domainkey.iredmail.org.   3600 TXT (
  "v=DKIM1; p="
  "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDYArsr2BKbdhv9efugByf7LhaK"
  "txFUt0ec5+1dWmcDv0WH0qZLFK711sibNN5LutvnaiuH+w3Kr8Ylbw8gq2j0UBok"
  "FcMycUvOBd7nsYn/TUrOua3Nns+qKSJBy88IWSh2zHaGbjRYujyWSTjlPELJ0H+5"
  "EV711qseo/omquskkwIDAQAB")
```
> Note: On some Linux/BSD distribution, you should use command 'amavisd-new' instead of 'amavisd'.

> if it complains "/etc/amavisd.conf not found", you should tell amavisd the correct path of its config file. For example:
```
# amavisd -c /etc/amavisd/amavisd.conf showkeys
```
> Note: Bind can handle this kind of multi-line format, so you can paste it in your domain zone file directly.

  * Copy output of above command into one line, like below. It will be the value of DNS record.
```
v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDYArsr2BKbdhv9efugByf7LhaKtxFUt0ec5+1dWmcDv0WH0qZLFK711sibNN5LutvnaiuH+w3Kr8Ylbw8gq2j0UBokFcMycUvOBd7nsYn/TUrOua3Nns+qKSJBy88IWSh2zHaGbjRYujyWSTjlPELJ0H+5EV711qseo/omquskkwIDAQAB
```

  * Add a 'TXT' type DNS record, set value to the line you copied above.

  * After you added this in DNS, type below command to verify it:
```
# amavisd testkeys
TESTING: dkim._domainkey.iredmail.org      => pass
```

If it shows 'pass', it works.

Note: If you use DNS service provided by ISP, new DNS record might take some hours to be available.

## References ##
  * http://www.dkim.org/