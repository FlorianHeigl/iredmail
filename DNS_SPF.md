#labels DNS,SPF
#summary How to Setup DNS record for SPF

## How to Setup DNS record for SPF ##

Please refer http://www.openspf.org/ to setup SPF record.

This is a simply example:
```
iredmail.org.           3600    IN      TXT     "v=spf1 mx mx:mail.iredmail.org -all"
```
or:
```
iredmail.org.           3600    IN      TXT     "v=spf1 ip4:202.96.134.133 -all"
```

Another tip from maxie\_ro: http://www.iredmail.org/forum/post5456.html#p5456