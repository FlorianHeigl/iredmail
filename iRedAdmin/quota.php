<?php
require_once ('includes/config.inc.php');
require_once ('includes/adminlogin.inc.php');

$message="";
$user_updated=false;

if(isset($_POST['quota'])) {
	foreach($_POST['quota'] as $key=>$value) {
		if ($value=="")
			continue;
		if (validateint($value)===false) {
			add_msg("User quota of '$key' must be integer");
			continue;
		}
		if (!($value>=0 && $value <=999999)) {
			add_msg("User quota of '$key' must between 0 & 999999");
			continue;
		}
		$quota_in_mb = $value;
		$email = mysql_escape_string($key);
		if ($quota_in_mb>=0) {
			$sql = "update users set quota_in_mb = '$value' where email = '$email'";
			mysql_query($sql, $link) or die ("Unable to run query");
			update_maildirsize($email, $quota_in_mb*1024*1024,"0");
			add_msg("User quota of '$key' updated");
			$user_updated=true;
		}
	}
	if (!$user_updated)
		add_msg("No user quota updated!!");
	updatequota_html($message);
} else { updatequota_html() ;}

updatequota_html() ;

function human_readable_size($bytes) {
	if ($bytes>=1024*1024*1024)
		return number_format($bytes/1024/1024/1024, 2) . " G";
	if ($bytes>=1024*1024)
		return number_format($bytes/1024/1024,2) . " M";
	if ($bytes>=1024)
		return number_format($bytes/1024,2) . " K";
	return number_format($bytes,2) . " B";
}

function add_msg($string) {
	global $message;
	if ($message!="")
		$message .= ", $string";
	else
		$message = $string;
}

function validateint($inData) {
  $intRetVal = false;
  $IntValue = intval($inData);
  $StrValue = strval($IntValue);
  if($StrValue == $inData) {
    $intRetVal = $IntValue;
  }
  return $intRetVal;
}

function getmailboxinfo($email, &$size_limit, &$message_limit, &$message_count, &$message_size) {
	$size_limit=0;
	$message_limit=0;
	$message_count=0;
	$message_size=0;

	$username=$_SESSION["email"];
	$password=$_SESSION["crypt"];

	#visudo and add this into it
	#apache ALL=NOPASSWD: /usr/bin/cat /home/vmail/*/*/.maildir/maildirsize
    $command = "src/mailadmin/mailadmin $username $password getmaildirsize $email";

	exec($command,$result);
	for ($i=0;$i<count($result);$i++)
	{
		$buffer=$result[$i];
		if (preg_match('/(\d+)S/', $buffer, $regs))
			$size_limit=$regs[1];
		if (preg_match('/(\d+)C/', $buffer, $regs))
			$message_limit=$regs[1];
		if (preg_match('/^\s*([-]{0,1}\d+)\s+([-]{0,1}\d+)\s*$/', $buffer, $regs))
		{
			$message_size+=$regs[1];
			$message_count+=$regs[2];
		}
	}
	return true;
}

function update_maildirsize($email,$size_limit,$message_limit) {
	$username=$_SESSION["email"];
	$password=$_SESSION["crypt"];
    $command = "src/mailadmin/mailadmin $username $password updatequota $email $size_limit $message_limit";
    exec($command,$result);
    if (strpos($result[0], "Error") !== false )
    	die($result[0]);
	return true;
}

function usage_html($percent) {
	$quota_warning_percent="70";
	$usage_color="green";
	if ($percent>=$quota_warning_percent)
		$usage_color="orange";
	if ($percent>=100) {
		$usage_color="red";
		$percent="100";
	}
		return '
      <table width="100%" border="0" cellpadding="0" cellspacing="0">
        <tr>
          <td  width="60">
            <table border="0" cellpadding="0" cellspacing="0" width="100%">
              <tr bgcolor="#cccccc">
                <td align="left">
                  <table border="0" cellpadding="0" width="'.$percent.'%">
                    <tr bgcolor="#cccccc">
                      <td bgcolor="'.$usage_color.'">&nbsp;</td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </td>
          <td align="center"> '.$percent.'% </td>
        </tr>
      </table>
      ';
}

function updatequota_html($message=null) {
	$extraheader="<title>Quota</title>";
	include ('includes/overall_header.tpl');
	global $link;
?>
<h1> MailBox Quota </h1>
<font color="red"><?=$message?></font>
<form id="form1" name="form1" method="post" action="">
  <table border="1">
    <tr>
      <th>E-mail</th>
      <th>Size Limit </th>
      <th>Mailbox Usage</th>
      <th>Usage percent</th>
      <th>Message Limit </th>
      <th>Message Count </th>
      <th>Sync</th>
      <th>New Quota in MB </th>
    </tr>
<?php
	$sql = "select email, quota_in_mb from users";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	while ($row = mysql_fetch_array($res)) {
		$email=$row[0];
		getmailboxinfo($email, $size_limit, $message_limit, $message_count, $message_size);

		#use quota data from mysql instead of maildirsize
		$size_limit_in_db = $row[1]*1024*1024;
		if ($size_limit_in_db==0)
			$usage_percentage=0;
		else
			$usage_percentage = $message_size / $size_limit_in_db * 100;
		if ($size_limit_in_db==0)
			$size_limit_string = "Unlimited";
		else
			$size_limit_string = human_readable_size($size_limit_in_db);
		if ($message_limit==0)
			$message_limit="Unlimited";
		echo "    <tr>\n";
		echo "      <td>$email</td>\n";
		echo "      <td>$size_limit_string</td>\n";
		echo "      <td>".human_readable_size($message_size)."</td>\n";
		echo "      <td>".usage_html((int)$usage_percentage)."</td>\n";
		echo "      <td>$message_limit</td>\n";
		echo "      <td>$message_count</td>\n";
		echo "      <td>";
		echo ($size_limit_in_db==$size_limit)? '<font color="green">yes</font>' : '<font color="red">no</font>';
		echo "</td>\n";
		echo "      <td align=\"center\"><input type=\"text\" name=\"quota[$email]\" size=\"13\" maxlength=\"6\"/></td>\n";
		echo "    </tr>\n";
	}
?>
  </table>
  <input type="submit" value="Submit" />
  <input type="button" value="Refresh" onclick="javascript:location.href='<?=$_SERVER['PHP_SELF']?>';" />
</form>

<br /><a href="index.php">Back to main</a>
<?php
include ('includes/overall_tail.tpl');
exit;
}
?>
