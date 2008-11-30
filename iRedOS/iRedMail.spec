Name:       iRedMail
Version:    0.3.1
Release:    1%{?dist}
Summary:    Open Source Mail Server Solution for Red Hat Enterprise Linux and CentOS 5.x

Group:      System Environment/Base
License:    GPLv2
URL:        http://code.google.com/p/iredmail/
Source0:    http://iredmail.googlecode.com/files/iRedMail-0.3.1.tar.bz2
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
#BuildArchitectures: noarch

#BuildRequires: 
#Requires:  

%description
iRedMail is:

* mail server solution for Red Hat(R) Enterprise Linux and
  CentOS 5.x, support both i386 and x86_64.
* a shell script set, used to install and configure all
  mail server related software automatically. 
* open source project, public under GPLv2.

%prep
%setup -q

%build
cd pkgs && createrepo .
#configure
#make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
#make install DESTDIR=$RPM_BUILD_ROOT
#install -m 0750 -d $RPM_BUILD_ROOT/root
install -m 0750 -d $RPM_BUILD_ROOT/root/iRedMail/
cp -arf {AUTHORS,ChangeLog,INSTALL,TODO,*.sh,conf,functions,patches,pkgs,samples,tools} $RPM_BUILD_ROOT/root/iRedMail/

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
#%doc AUTHORS ChangeLog INSTALL TODO
/root/iRedMail/*

%changelog
* Sat Nov 01 2008 bbbush <bbbush.yuan@gmail.com> - 0.3.1-1
- initial import

