<?php

require_once ('includes/config.inc.php');
require_once ('includes/adminlogin.inc.php');

if (isset($_POST['newdomain']) && $_POST['newdomain'] == "") {
	newdomain_html("<font color=red>Please fill in the new domain!!</font>");
}

if (isset($_POST['newdomain'])) {
	$sql = "SELECT `domain` FROM `transport` WHERE `destination` = 'virtual:'";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	while ($row = mysql_fetch_array($res)) {
		if ($_POST['newdomain'] == $row['domain'])
			newdomain_html("<font color=red>Domain exist!!</font>");
	}

	$sql = "INSERT INTO `transport` (`domain` ,`destination`) VALUES ( '" . $_POST['newdomain'] . "', 'virtual:')";
	$res = mysql_query($sql, $link) or die ("Unable to run query");

/*
	$newdomaindir = $config['vmaildir'] . "/" . $_POST['newdomain'];
	exec('mkdir '. $newdomaindir);
	exec("chmod -R 770 " . $newdomaindir);
*/
	$command = "src/mailadmin/mailadmin ".$_SESSION["email"]." ".$_SESSION["crypt"]." createdomain ".$_POST['newdomain'];
        exec($command,$result);
	if (strpos($result[0], "Error") !== false )
	    die($result[0]);

	newdomain_html("<font color=green>Domain '" .$_POST['newdomain']. "'created!!</font>");
}
newdomain_html();


function newdomain_html($message=null) {
	$extraheader="<title>Create New Domain</title>";
	include ('includes/overall_header.tpl');
?>
<h1> Create Domain </h1>
<?=$message?>
<form name="form1" method="post" action="">
  <table border="1" cellpadding="2" cellspacing="2">
    <tr>
      <td>Domain:</td>
      <td><input name="newdomain" type="text" value="<?=$_POST[newdomain]?>"/></td>
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


?>
