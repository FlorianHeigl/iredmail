#summary How to create a yum repository on RHEL/CentOS 5.x with CD/DVD or ISO images.



# How to create a yum repository on RHEL/CentOS 5.x with CD/DVD or ISO images #
## Mount your CD/DVD or ISO images ##
### DVD Disk or DVD ISO image ###

  * If you have DVD disk, please mount dvd-rom first, and then create yum repository:
```
# mkdir /mnt/dvd/
# mount /dev/cdrom /mnt/dvd/
```

  * If you use DVD iso, please copy it to the system, and then create yum repository:
```
# mkdir /mnt/dvd/
# mount -o loop /root/rhel5.1-dvd.iso /mnt/dvd
```

### CD images ###

If you have multiple CD image files, you should mount all iso images and then create yum repository.

  * Mount all iso images:
```
# mkdir -p /mnt/{1,2,3,4,5}
# mount -o loop rhel5.1-disc1.iso /mnt/1
# mount -o loop rhel5.1-disc2.iso /mnt/2
# mount -o loop rhel5.1-disc3.iso /mnt/3
# mount -o loop rhel5.1-disc4.iso /mnt/4
# mount -o loop rhel5.1-disc5.iso /mnt/5
```

## Install necessary package ##

  * Find and install 'createrepo' package in /mnt directory:
```
# find /mnt -iname 'createrepo*'
/mnt/dvd/Server/createrepo-0.4.11-3.el5.noarch.rpm

# rpm -ivh /mnt/dvd/Server/createrepo-0.4.11-3.el5.noarch.rpm
```

## Create yum repository ##

### Create metadata ###
  * Create yum repository:
```
# cd /mnt/
# createrepo .
```

### Define yum repository ###

Create yum repository define file /etc/yum.repos.d/dvdiso.repo:

```
[MailRepo]
name=MailRepo
baseurl=file:///mnt/
enabled=1
gpgcheck=0
```

### Test it ###

```
# yum clean all
# yum list
```

If 'yum list' list all packages in DVD/CD disks or ISO images, it works. :)