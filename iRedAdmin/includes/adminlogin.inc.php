<?php

require_once('includes/config.inc.php');

if (!isset($_SESSION['email']))
	require('includes/login.inc.php');

if (in_array($_SESSION['email'], $config['admin']))
	$admin = true;
else
	$admin = false;

if (!$admin) {
	$extraheader="<title>Permission Denied</title>";
	include ('includes/overall_header.tpl');
	echo "You don't have permission to access this page!!<br />";
	echo "<br /><a href=\"index.php\">Back to main</a>\n";
	include ('includes/overall_tail.tpl');
	exit;
}

?>