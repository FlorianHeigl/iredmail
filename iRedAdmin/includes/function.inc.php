<?php

session_start();

if (get_magic_quotes_gpc()==1) {
	array_stripslashes($_POST);
	array_stripslashes($_GET);
	array_stripslashes($_COOKIE);
	array_stripslashes($_REQUEST);
}

function array_stripslashes(&$input) {
	if (is_array($input)) {
		foreach($input as $name=>$value) {
			array_stripslashes($input[$name]);
		}
	}
	else
		$input=stripslashes($input);
}

function get_domain() {
	global $link;
	$sql = "SELECT `domain` FROM `transport` WHERE `destination` = 'virtual:'";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
 	while ($row = mysql_fetch_array($res)) {
		$domain[] = $row['domain'];
	}
	return $domain;
}

?>