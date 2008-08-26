<?php
require_once ('includes/config.inc.php');
require_once ('includes/login.inc.php');

$extraheader="<title>Change Password</title>";
if(isset($_POST['newpasswd1']) && (($_POST['newpasswd1']!=$_POST['newpasswd2']) || $_POST['newpasswd1']==""))
	chpasswd_html( "New password empty or do not match!!");
if ($_POST['newpasswd1'] == $_POST['newpasswd2'] && isset($_POST['newpasswd2'])) {
	sleep(2);
	if ($_POST['oldpasswd'] != $_SESSION['crypt'])
		chpasswd_html( "Old password do not match!!");
	$email = mysql_escape_string($_SESSION['email']);
	$newcrypt = mysql_escape_string(crypt($_POST['newpasswd1']));
	$sql = "update users set crypt = '$newcrypt' where email = '$email' ";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_affected_rows()!=1)
		die( "Internal Error, Password update failed!!<br />");
	$_SESSION['crypt']=$_POST['newpasswd1'];
	unset ($_POST);
	include ('includes/overall_header.tpl');
	echo "Password update sucessful!!";
	include ('includes/overall_tail.tpl');
	exit;
} else { chpasswd_html() ;}

function chpasswd_html($message=null) {
global $extraheader;
include ('includes/overall_header.tpl');
?>
<h1> Change Password </h1>
<font color="red"><?=$message?></font>
<form name="form1" method="post" action="">
  <table border="1" cellpadding="2" cellspacing="2">
    <tr>
      <td>Username: </td>
      <td><?=$_SESSION[email]?></td>
    </tr>
    <tr>
      <td>Old Password: </td>
      <td><input name="oldpasswd" type="password" /></td>
    </tr>
    <tr>
      <td>New Password: </td>
      <td><input name="newpasswd1" type="password" /></td>
    </tr>
    <tr>
      <td>Confirm Password: </td>
      <td><input name="newpasswd2" type="password" /></td>
    </tr>
    <tr>
      <td colspan="2" align="center"><input type="submit" name="Submit" value="Submit" /></td>
    </tr>
  </table>
</form>
<br /><a href="index.php">Back to main</a>
<?php
include ('includes/overall_tail.tpl');
exit;
}
?>
