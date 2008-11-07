{include file='header.php'}
<div id="login">
<form name="login" method="post">
<table id="login_table" cellspacing="10">
   <tr>
      <td colspan="2"><h4>{$LANG.pLogin_welcome}</h4></td>
   </tr>
   <tr>
      <td>{$LANG.pLogin_username}:</td>
      <td><input class="flat" type="text" name="fUsername" value="{$tUsername}" /></td>
   </tr>
   <tr>
      <td>{$LANG.pLogin_password}:</td>
      <td><input class="flat" type="password" name="fPassword" /></td>
   </tr>
   <tr>
      <td colspan="2">
        {php}
         echo language_selector();
        {/php}
      </td>
   </tr>
   <tr>
      <td colspan="2" class="hlp_center"><input class="button" type="submit" name="submit" value="{$LANG.pLogin_button}" /></td>
   </tr>
   <tr>
      <td colspan="2" class="standout">{$tMessage}</td>
   </tr>
   <tr>
      <td colspan="2"><a href="users/">{$LANG.pLogin_login_users}</a></td>
   </tr>
</table>
</form>

{literal}
<script type="text/javascript" language="javascript">
<!--
	document.login.fUsername.focus();
//-->
</script>
{/literal}

</div>
{include file='footer.php'}
