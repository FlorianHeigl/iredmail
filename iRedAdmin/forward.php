<?php
require_once ('includes/config.inc.php');
require_once ('includes/login.inc.php');

$email = mysql_escape_string($_SESSION['email']);

$sql = "select destination from virtual where email = '$email'";
$res = mysql_query($sql, $link) or die ("Unable to run query");
$destination = mysql_escape_string($_POST['destination']);
$extraheader="<title>Mail Forward</title>";

if (mysql_affected_rows()==0) {
	if (!isset($_POST['destination']))
 		newforward_html();
	if ($_POST['destination']=="")
		newforward_html("<font color=\"red\">Please fill in the destination mail address</font>");
	$sql = "insert into virtual (email, destination) values ( '$email' , '$destination') ";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_affected_rows()!=1)
		die( "Internal Error, Mail forward failed!!");
	include ('includes/overall_header.tpl');
	echo "Your email has been forwarded to " . stripslashes($destination) . "<br />";
		echo "<a href=\"index.php\">Back to main</a>";
	include ('includes/overall_tail.tpl');
	unset ($_POST);
	exit;
}
else {
	$row = mysql_fetch_array($res);
	if (!isset($_POST['destination']) && !isset($_POST['noforward']))
 		editforward_html();
	if ($_POST['destination']=="" && $_POST['noforward']=="")
		editforward_html("<font color=red>Please fill in the destination mail address</font>");
	if ($_POST['noforward']=="noforward") {
		unset ($_POST);
		$sql = "delete from virtual where email = '$email'";
		$res = mysql_query($sql, $link) or die ("Unable to run query");

		include ('includes/overall_header.tpl');
		echo "Forward has been canceled<br />";
		echo "<a href=\"index.php\">Back to main</a>";
		include ('includes/overall_tail.tpl');
		exit;
	}
	else {
		$sql = "update virtual set destination = '$destination' where email = '$email'";
		$res = mysql_query($sql, $link) or die ("Unable to run query");
		unset ($_POST);
		include ('includes/overall_header.tpl');
		echo "Your email has been forwarded to " . stripslashes($destination) . "<br />";
		echo "<a href=\"index.php\">Back to main</a>";
		include ('includes/overall_tail.tpl');
		unset ($_POST);
		exit;
	}
}

function newforward_html($message=null) {
global $extraheader;
include ('includes/overall_header.tpl');
?>
<h1> Mail Forward </h1>
<?=$message?>
<form name="form1" method="post" action="">
Destination Email Address:<br />
<input name="destination" type="text" size="40" maxlength="255"/><br />
<p><input type="submit" name="Submit" value="Submit" /></p>
</form>
<br /><a href="index.php">Back to main</a>
<?php
include ('includes/overall_tail.tpl');
exit;
}

function editforward_html($message=null) {
global $row;
global $extraheader;
include ('includes/overall_header.tpl');
?>
<h1> Mail Forward </h1>
<?=$message?>
<form name="form1" method="post" action="">
Your email already forwarded to <?=$row['destination']?><br />
Forward to another email address:<br />
<input name="destination" type="text" size="40" maxlength="255" /><br />
Cancel forward? <input type="checkbox" name="noforward" value="noforward" /><br />
<input type="submit" name="Submit" value="Submit" />
</form>
<br /><a href="index.php">Back to main</a>
<?php
include ('includes/overall_tail.tpl');
exit;
}
?>
