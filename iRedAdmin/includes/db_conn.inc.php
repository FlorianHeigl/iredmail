<?php

$link = mysql_connect('localhost',$config['dbuser'] , $config['dbpass']) or die('Could not connect: ' . mysql_error());
mysql_select_db($config['dbname']) or die('Could not select database');

?>