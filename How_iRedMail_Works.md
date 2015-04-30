#summary How iRedMail works.



# How iRedMail Works #

  1. Download all necessary packages, so that we can avoid network issues during installation.
  1. Verify packages by MD5 Checksum, make sure packages are fetched correct.
  1. Create custom yum repository via ISO images, or use RHEL/CentOS official repositories for packages dependence.
  1. Configure mail server setting via 'dialog' user interface, including:
    * Selecting packages/features
    * Set first virtual domain, including:
      * domain name
      * global domain admin
      * first normal virtual user
  1. Install and configure packages according to above server setting.

Note: Each step is easy to port to other linux/BSD distrobutions, feel free to port it and contribute your patches. :)