<?php
require_once ('includes/config.inc.php');
require_once ('includes/adminlogin.inc.php');

if (isset($_POST['username']) && $_POST['username']=="")
	newacc_html("Please fill in user name!!");
else if(isset($_POST['passwd']) && (($_POST['passwd']!=$_POST['passwd2']) || $_POST['passwd']==""))
	newacc_html("Password do not match or empty!!");
else if (isset($_POST['username'])) {
	$email = mysql_escape_string($_POST['username']."@".$_POST['domain']);

	$sql = "select * from users where email = '$email' ";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_num_rows($res)!=0)
		newacc_html("User exist,please choose another login name!!");
	$sql = "select * from transport where domain = '". mysql_escape_string($_POST['domain']) ."' and destination = 'virtual:'";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_num_rows($res)==0)
		newacc_html("Domain do not exist!!");
	$maildir = mysql_escape_string($config['vmaildir'] . "/" . $_POST['domain'] . "/" . $_POST['username'] . "/.maildir");
	$passwd = mysql_escape_string(crypt($_POST['passwd']));

	$sql = "insert into users ( email, crypt, uid, gid, maildir, active ) values ('$email' , '$passwd', '".$config['uid']."', '".$config['gid']."', '$maildir', 'y' ) ";
	$res = mysql_query($sql, $link) or die ("Unable to run query");

	$lid = mysql_insert_id();
	$sql = "
	INSERT INTO `av_policy` ( `id` , `virus_lover` , `spam_lover` , `banned_files_lover` , `bad_header_lover` , `bypass_virus_checks` , `bypass_spam_checks` , `bypass_banned_checks` , `bypass_header_checks` , `spam_modifies_subj` , `spam_quarantine_to` , `spam_tag_level` , `spam_tag2_level` , `spam_kill_level` )
	VALUES ('$lid', 'N', 'N', 'N', 'N', 'N', 'N', 'Y', 'Y', 'Y ', NULL , '-100', '6.3', '9999.9') ";

	if ($res = mysql_query($sql, $link) ==false ) {
		$sql = "delete from users where id = '$lid'";
		$res = mysql_query($sql, $link) or die ("Internal Error: 101");
		die ("Error : Unable to insert av policy!!");
	}

/*
	//create folder
	$userdir = $config['vmaildir'] . "/" . $_POST['domain'] . "/" . $_POST['username'];
	exec('mkdir '.$userdir );
	exec('maildirmake ' . stripslashes($maildir));
	exec('maildirmake -f Spam ' . stripslashes($maildir));
	exec('echo "Spam" >> ' . stripslashes($maildir) . '/subscriptions');
	exec("chmod -R 700 " . $userdir);

	exec("sudo /bin/chown -R vmail " . $config['vmaildir'] . "/*");
*/

	$command = "src/mailadmin/mailadmin ".$_SESSION["email"]." ".$_SESSION["crypt"]." createuser ".$_POST['username']."@".$_POST['domain'];
	exec($command,$result);
	if (strpos($result[0], "Error") !== false )
	    die($result[0]);

    sleep(2);
	unset ($_POST);
	echo "Account created";
	die("<br /><a href=index.php>Back to main</a>");

} else { newacc_html(); }

function newacc_html($message=null) {
	global $config;
	$extraheader="<title>Create New Account</title>";
	include ('includes/overall_header.tpl');
?>
<h1> Create Account </h1>
<font color="red"><?=$message?></font>
<form name="form1" method="post" action="">
  <table border="1" cellpadding="2" cellspacing="2">
    <tr>
      <td>Username:</td>
      <td><input name="username" type="text" value="<?=$_POST[username]?>"/></td>
    </tr>
    <tr>
      <td>Password:</td>
      <td><input name="passwd" type="password" /></td>
    </tr>
    <tr>
      <td>Confirnm Password: </td>
      <td><input name="passwd2" type="password" /></td>
    </tr>
    <tr>
      <td>Domain:</td>
      <td>
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
      </td>
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
