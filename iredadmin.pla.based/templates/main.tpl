{include file="header.tpl"}
{include file="menu.tpl"}
<div id="main_menu">
<table>
   <tr>
      <td nowrap><a target="_top" href="list-domain.php">{$LANG.pMenu_overview}</a></td>
      <td>{$LANG.pMain_overview}</td>
   </tr>
   <tr>
      <td nowrap><a target="_top" href="create-alias.php">{$LANG.pMenu_create_alias}</a></td>
      <td>{$LANG.pMain_create_alias}</td>
   </tr>
   <tr>
      <td nowrap><a target="_top" href="create-mailbox.php">{$LANG.pMenu_create_mailbox}</a></td>
      <td>{$LANG.pMain_create_mailbox}</td>
   </tr>
{if $CONF.sendmail == "YES"}
   <tr>
      <td nowrap><a target="_top" href="sendmail.php">{$LANG.pMenu_sendmail}</a></td>
      <td>{$LANG.pMain_sendmail}</td>
   </tr>
{/if}
   <tr>
      <td nowrap><a target="_top" href="password.php">{$LANG.pMenu_password}</a></td>
      <td>{$LANG.pMain_password}</td>
   </tr>
   <tr>
      <td nowrap><a target="_top" href="viewlog.php">{$LANG.pMenu_viewlog}</a></td>
      <td>{$LANG.pMain_viewlog}</td>
   </tr>
   <tr>
      <td nowrap><a target="_top" href="logout.php">{$LANG.pMenu_logout}</a></td>
      <td>{$LANG.pMain_logout}</td>
   </tr>
</table>
</div>
{include file="footer.tpl"}
