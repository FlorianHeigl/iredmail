<?php

require_once ('includes/config.inc.php');
if (isset($_GET['login'])) {
	require_once ('includes/login.inc.php');
	echo '<html><script>location = "index.php";</script></html>';
}
else
	main();
exit;

function main(){
$extraheader="<title>Main</title>";
include ('includes/overall_header.tpl');
?>
<h1>Mail Preference</h1>
<?php
	if (isset($_SESSION['email']) && isset($_SESSION['crypt']))
		echo"<p>Welcome, $_SESSION[email]</p>";
?>
<a href="newacc.php">Create e-mail account</a><br />
<a href="newdomain.php">Create new domain</a><br />
<a href="chpasswd.php">Change e-mail account password</a><br />
<a href="forward.php">Mail forward</a><br />
<a href="wblist.php">White/Black list</a><br />
<a href="quota.php">Quota</a><br />
<a href="mailfilter.php">Mail filter</a><br />
<a href="maildrop.php">Mail drop</a><br />

<?php
if (isset($_SESSION['email']) && isset($_SESSION['crypt']))
	echo "<a href=\"logout.php\">Logout</a><br />";
else
	echo "<a href=\"?login\">Login</a><br />";
echo "<br /><img src=\"includes/valid-xhtml10.png\" alt=\"\" />";
include ('includes/overall_tail.tpl');
}

?>
