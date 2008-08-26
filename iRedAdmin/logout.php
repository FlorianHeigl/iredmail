<?php
session_start();
unset($_SESSION['email']);
unset($_SESSION['crypt']);
$extraheader="<title>Logout</title>";
include ('includes/overall_header.tpl');
?>
Logout Seccessful!!<br>
<a href="index.php">back to main</a>
<?php
include ('includes/overall_tail.tpl');
?>
