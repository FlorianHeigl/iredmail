<?php

if ($_SESSION['email']!="" && $_SESSION['crypt']!="") {
	$email = $_SESSION['email'];
	$crypt = $_SESSION['crypt'];
}
else if (isset($_POST['username']) && $_POST['username']=="")
	login_html("Please fill in user name!!");
else if (isset($_POST['passwd']) && $_POST['passwd']=="")
	login_html("Please fill in password");
else if ($_POST['username']!="" && $_POST['passwd']!="") {
	$email = $_POST['username']."@".$_POST['domain'];
	$crypt = $_POST['passwd'];
	unset($_POST['username']);
	unset($_POST['domain']);
	unset($_POST['passwd']);
}

if (isset($email) && isset($crypt)) {
	$sql = "select crypt from users where email = '" .mysql_escape_string($email). "'";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	$row = mysql_fetch_array($res);
	if (mysql_num_rows($res)==0 || (crypt($crypt, $row['crypt']) != $row['crypt'])) {
		unset($_SESSION['email']);
		unset($_SESSION['crypt']);
		sleep(2);
		login_html("Username or password do not match!!");
	}
	else if ($_SESSION['email']=="" || $_SESSION['crypt']==""){
		$_SESSION['email']=$email;
		$_SESSION['crypt']=$crypt;
	}
}
else { login_html(); }

function login_html($message=null) {
	global $config;
	$extraheader="<title>Login</title>";
	include ('includes/overall_header.tpl');
?>
<h1> Login Page </h1>
<font color="red"><?=$message?></font>
<form name="form1" method="post" action="">
  <table width="200" border="0" cellpadding="2" cellspacing="2">
    <tr>
      <td><div align="center">Username:</div></td>
      <td><div align="center"><input name="username" type="text" value="<?=$_POST[username]?>" /></div></td>
    </tr>
    <tr>
      <td><div align="center">Password:</div></td>
      <td><div align="center"><input name="passwd" type="password" /></div></td>
    </tr>
    <tr>
      <td><div align="center">Domain:</div></td>
      <td><div align="center">
          <select name="domain">
<?php
$domain = get_domain();
for ($i=0;$i<count($domain);$i++) {
            echo "            <option value=\"" .$domain[$i]. "\" ";
            if($i==0 && $_POST['domain']=="") echo "selected=\"selected\"";
            if($_POST['domain']==$domain[$i]) echo "selected=\"selected\"";
            echo ">" .$domain[$i]. "</option>\n";
}
?>
          </select>
          </div>
      </td>
    </tr>
    <tr>
      <td colspan="2"><div align="center"><input type="submit" name="Submit" value="Submit" /></div></td>
    </tr>
  </table>
</form>
    <?php
	include ('includes/overall_tail.tpl');
    exit;
} //end function

?>
