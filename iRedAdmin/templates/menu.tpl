{php}
function _menulink ($href, $title, $submenu = "") {
   if ($submenu != "") $submenu = "<ul><li><a target='_top' href='$href'>$title</a>$submenu</li></ul>";
   return "<li><a target='_top' href='$href'>$title</a>$submenu</li>";
} 
{/php}

<div id='menu'>
<ul>

{IRA_domainlink var="c_mbox" href="create-mailbox.php"}
{IRA_menulink href=$c_mbox text=$LANG.pMenu_create_mailbox}

{IRA_domainlink var="c_alias" href="create-alias.php"}
{IRA_menulink href=$c_alias text=$LANG.pMenu_create_alias}

{IRA_vmenulink var="submenu_admin" href="create_admin.php", text=$LANG.pAdminMenu_create_admin}
{IRA_vmenulink var="submenu_fetchmail" href="fetchmail.php?new=1" text=$LANG.pFetchmail_new_entry}

{if $is_global_admin}
    {IRA_vmenulink var="submenu_domain" href="create_domain.php" text=$LANG.pAdminMenu_create_domain}
    {IRA_vmenulink var="submenu_sendmail" href="broadcast-message.php" text=$LANG.pAdminMenu_broadcast_message}
{else}
    {assign var="submenu_domain" value=""}
    {assign var="submenu_sendmail" value=""}
{/if}

{if $is_global_admin}
    {IRA_menulink href="list-admin.php" text=$LANG.pAdminMenu_list_admin submenu=$submenu_admin}
{else}
    {IRA_menulink href="main.php" text=$LANG.pMenu_main}
{/if}

{IRA_menulink href="list-domain.php" text=$LANG.pAdminMenu_list_domain submenu=$submenu_domain}
{IRA_menulink href="list-virtual.php" text=$LANG.pAdminMenu_list_virtual submenu=$submenu_virtual}

{if $CONF.fetchmail == "YES"}
    {IRA_menulink href="fetchmail.php" text=$LANG.pMenu_fetchmail submenu=$submenu_fetchmail}
{/if}
{if $CONF.sendmail == "YES"}
    {IRA_menulink href="sendmail.php" text=$LANG.pMenu_sendmail submenu=$submenu_sendmail}
{/if}

{php}
# not really useful in the admin menu
#if ($CONF['vacation'] == 'YES') {
#   print _menulink("edit-vacation.php", $PALANG['pUsersMenu_vacation']);
#}
{/php}

{IRA_menulink href="password.php" text=$LANG.pMenu_password}

{if $is_global_admin and "pgsql" != $CONF.database_type and $CONF.backup == "YES"}
    {IRA_menulink href="backup.php" text=$LANG.pAdminMenu_backup}
{/if}

{IRA_menulink href="viewlog.php" text=$LANG.pMenu_viewlog}
{IRA_menulink href="logout.php" text=$LANG.pMenu_logout}

</ul>
</div>

<br clear='all' /><br>

{php}
/*
if (authentication_has_role('global-admin')) {
   $motd_file = "motd-admin.txt";
} else {
   $motd_file = "motd.txt";
}

if (file_exists (realpath ($motd_file)))
{
   print "<div id=\"motd\">\n";
   include ($motd_file);
   print "</div>";
}

# IE can't handle :hover dropdowns correctly. It needs some JS instead.
*/
{/php}

{literal}
<script type='text/javascript'>
sfHover = function() {
   var sfEls = document.getElementById("menu").getElementsByTagName("LI");
      for (var i=0; i<sfEls.length; i++) {
         sfEls[i].onmouseover=function() {
            this.className+=" sfhover";
         }
         sfEls[i].onmouseout=function() {
            this.className=this.className.replace(new RegExp(" sfhover\\b"), "");
         }
   }
}
if (window.attachEvent) window.attachEvent("onload", sfHover);
</script>
{/literal}
