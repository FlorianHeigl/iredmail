<?php
$config['dbname'] = "mailsql";
$config['dbuser'] = "mailsql";
$config['dbpass'] = "";

$config['vmaildir'] = "/home/vmail";

$config['uid'] = "1000";
$config['gid'] = "1000";

$config['admin'] = array('test@abc.com');

require_once('includes/db_conn.inc.php');
require_once('includes/function.inc.php');


?>