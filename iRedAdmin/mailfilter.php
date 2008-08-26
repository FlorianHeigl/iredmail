<?php

require_once ('includes/config.inc.php');
require_once ('includes/login.inc.php');

$email = mysql_escape_string($_SESSION['email']);
$sql = "select id from users where email = '" .mysql_escape_string($email). "'";
$res = mysql_query($sql, $link) or die ("Unable to run query");
$row = mysql_fetch_array($res);
$id=$row['id'];

if (isset($_POST['savepref'])) {

	if ($_POST['virus_lover'] != "Y" && $_POST['virus_lover'] != "N" )
		$_POST['virus_lover'] = "N";

	if ($_POST['spam_lover'] != "Y" && $_POST['spam_lover'] != "N" )
		$_POST['spam_lover'] = "N";

	if ($_POST['banned_files_lover'] != "Y" && $_POST['banned_files_lover'] != "N")
		$_POST['banned_files_lover'] = "N";

	if ($_POST['bad_header_lover'] != "Y" && $_POST['bad_header_lover'] != "N")
		$_POST['bad_header_lover'] = "N";

	if ($_POST['bypass_virus_checks'] != "Y" && $_POST['bypass_virus_checks'] != "N")
		$_POST['bypass_virus_checks'] = "N";

	if ($_POST['bypass_spam_checks'] != "Y" && $_POST['bypass_spam_checks'] != "N")
		$_POST['bypass_spam_checks'] = "N";

	if ($_POST['bypass_banned_checks'] !="Y" && $_POST['bypass_banned_checks'] != "N")
		$_POST['bypass_banned_checks'] = "Y";

	if ($_POST['bypass_header_checks'] != "Y" && $_POST['bypass_header_checks'] != "N")
		$_POST['bypass_header_checks'] = "Y";

	if ($_POST['spam_modifies_subj'] != "Y" && $_POST['spam_modifies_subj'] != "N")
		$_POST['spam_modifies_subj'] = "Y";

	if ($_POST['spam_tag_level'] == "Y")
		$_POST['spam_tag_level'] = "-100";
	else
		$_POST['spam_tag_level'] = "9999.9";

	if (!is_numeric($_POST['spam_tag2_level']) || $_POST['spam_tag2_level'] <= 0 || $_POST['spam_tag2_level'] >=10000)
		$_POST['spam_tag2_level'] = "6.3";

	if (!is_numeric($_POST['spam_kill_level']) || $_POST['spam_kill_level'] <= 0 || $_POST['spam_kill_level'] >=10000)
		$_POST['spam_kill_level'] = "9999.9";

	$sql = "UPDATE `av_policy` SET
	`virus_lover` = '".$_POST['virus_lover']."',
	`spam_lover` = '".$_POST['spam_lover']."',
	`banned_files_lover` = '".$_POST['banned_files_lover']."',
	`bad_header_lover` = '".$_POST['bad_header_lover']."',
	`bypass_virus_checks` = '".$_POST['bypass_virus_checks']."',
	`bypass_spam_checks` = '".$_POST['bypass_spam_checks']."',
	`bypass_banned_checks` = '".$_POST['bypass_banned_checks']."',
	`bypass_header_checks` = '".$_POST['bypass_header_checks']."',
	`spam_modifies_subj` = '".$_POST['spam_modifies_subj']."',
	`spam_quarantine_to` = NULL ,
	`spam_tag_level` = '".$_POST['spam_tag_level']."',
	`spam_tag2_level` = '".$_POST['spam_tag2_level']."',
	`spam_kill_level` = '".$_POST['spam_kill_level']."'
	WHERE `id` ='$id'";

	$res = mysql_query($sql, $link) or die ("Unable to run query");

	mailfilter_html("Setting saved!!");
} else { mailfilter_html(); }

function mailfilter_html($message=null) {
global $link;
global $id;

$sql = "select * from av_policy where id = '$id'";
$res = mysql_query($sql, $link) or die ("Unable to run query");
$row = mysql_fetch_array($res);

if ($row['virus_lover'] == "Y")
$virus_lovery= "checked=\"checked\"";
else
$virus_lovern= "checked=\"checked\"";

if ($row['spam_lover'] == "Y")
$spam_lovery= "checked=\"checked\"";
else
$spam_lovern= "checked=\"checked\"";

if ($row['banned_files_lover'] == "Y")
$banned_files_lovery= "checked=\"checked\"";
else
$banned_files_lovern= "checked=\"checked\"";

if ($row['bad_header_lover'] == "Y")
$bad_header_lovery= "checked=\"checked\"";
else
$bad_header_lovern= "checked=\"checked\"";

if ($row['bypass_virus_checks'] == "Y")
$bypass_virus_checksy= "checked=\"checked\"";
else
$bypass_virus_checksn= "checked=\"checked\"";

if ($row['bypass_spam_checks'] == "Y")
$bypass_spam_checksy= "checked=\"checked\"";
else
$bypass_spam_checksn= "checked=\"checked\"";

if ($row['bypass_banned_checks'] == "Y")
$bypass_banned_checksy= "checked=\"checked\"";
else
$bypass_banned_checksn= "checked=\"checked\"";

if ($row['bypass_header_checks'] == "Y")
$bypass_header_checksy= "checked=\"checked\"";
else
$bypass_header_checksn= "checked=\"checked\"";

if ($row['spam_modifies_subj'] == "Y")
$spam_modifies_subjy= "checked=\"checked\"";
else
$spam_modifies_subjn= "checked=\"checked\"";

if ($row['spam_tag_level'] == "-100")
$spam_tag_levely= "checked=\"checked\"";
else
$spam_tag_leveln= "checked=\"checked\"";
$extraheader = "<title>Mail Filter</title>\n";
$extraheader .= "<script language=\"javascript\" type=\"text/javascript\">
function setdefault(form)
{
form.virus_lover[1].checked=true;
form.spam_lover[1].checked=true;
form.banned_files_lover[1].checked=true;
form.bad_header_lover[1].checked=true;
form.bypass_virus_checks[1].checked=true;
form.bypass_spam_checks[1].checked=true;
form.bypass_banned_checks[0].checked=true;
form.bypass_header_checks[0].checked=true;
form.spam_modifies_subj[0].checked=true;
form.spam_tag_level[0].checked=true;

form.spam_tag2_level.value=6.3;
form.spam_kill_level.value=9999.9;
}
</script>";
include ('includes/overall_header.tpl');
?>
<h1> Mail Filter Preference </h1>
<font color="green"><?=$message?></font>
<form name="form1" method="post" action="">
<table width="500" border="1">
  <thead>
  <tr>
    <th width="300">Settings</th>
    <th>Value</th>
  </tr>
  </thead>
  <tbody>
  <tr>
    <td>Always receive virus mails </td>
    <td><input name="virus_lover" type="radio" value="Y" <?=$virus_lovery?> />Yes
      &nbsp;&nbsp;
	  <input name="virus_lover" type="radio" value="N" <?=$virus_lovern?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Always receive spam mails </td>
    <td><input name="spam_lover" type="radio" value="Y" <?=$spam_lovery?> />Yes
      &nbsp;&nbsp;
      <input name="spam_lover" type="radio" value="N" <?=$spam_lovern?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Always receive banned file mails </td>
    <td><input name="banned_files_lover" type="radio" value="Y" <?=$banned_files_lovery?> />Yes
      &nbsp;&nbsp;
      <input name="banned_files_lover" type="radio" value="N" <?=$banned_files_lovern?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Always receive bad header mails</td>
    <td><input name="bad_header_lover" type="radio" value="Y" <?=$bad_header_lovery?> />Yes
      &nbsp;&nbsp;
      <input name="bad_header_lover" type="radio" value="N" <?=$bad_header_lovern?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Bypass virus checks</td>
    <td><input name="bypass_virus_checks" type="radio" value="Y" <?=$bypass_virus_checksy?> />Yes
      &nbsp;&nbsp;
      <input name="bypass_virus_checks" type="radio" value="N" <?=$bypass_virus_checksn?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Bypass spam checks</td>
    <td><input name="bypass_spam_checks" type="radio" value="Y" <?=$bypass_spam_checksy?> />Yes
      &nbsp;&nbsp;
      <input name="bypass_spam_checks" type="radio" value="N" <?=$bypass_spam_checksn?> />No&nbsp;&nbsp;(default:no)	</td>
  </tr>
  <tr>
    <td>Bypass banned checks</td>
    <td><input name="bypass_banned_checks" type="radio" value="Y" <?=$bypass_banned_checksy?> />Yes
      &nbsp;&nbsp;
      <input name="bypass_banned_checks" type="radio" value="N" <?=$bypass_banned_checksn?> />No&nbsp;&nbsp;(default:yes)	</td>
  </tr>
  <tr>
    <td>Bypass header checks</td>
    <td><input name="bypass_header_checks" type="radio" value="Y" <?=$bypass_header_checksy?> />Yes
      &nbsp;&nbsp;
      <input name="bypass_header_checks" type="radio" value="N" <?=$bypass_header_checksn?> />No&nbsp;&nbsp;(default:yes)	</td>
  </tr>
  <tr>
    <td>Modify spam subjects </td>
    <td><input name="spam_modifies_subj" type="radio" value="Y" <?=$spam_modifies_subjy?> />Yes
      &nbsp;&nbsp;
      <input name="spam_modifies_subj" type="radio" value="N" <?=$spam_modifies_subjn?> />No&nbsp;&nbsp;(default:yes)	</td>
  </tr>
  <tr>
    <td>Insert spam info headers</td>
    <td><input name="spam_tag_level" type="radio" value="Y" <?=$spam_tag_levely?> />Yes
      &nbsp;&nbsp;
      <input name="spam_tag_level" type="radio" value="N" <?=$spam_tag_leveln?> />No&nbsp;&nbsp;(default:yes)	</td>
  </tr>
  <tr>
    <td>Spam-rating score</td>
    <td><input name="spam_tag2_level" type="text" size="6" maxlength="6" value="<?=$row[spam_tag2_level]?>" />&nbsp;&nbsp;(default:6.3)</td>
  </tr>
  <tr>
    <td>Ignore when rating larger than </td>
    <td><input name="spam_kill_level" type="text" size="6" maxlength="6"  value="<?=$row[spam_kill_level]?>" />&nbsp;&nbsp;(default:9999.9)</td>
  </tr>
  <tr>
    <td align="center" colspan="2">
      <input type="submit" name="savepref" value="Submit" />
      <input type="button" name="default" value="Default" onclick="setdefault(this.form)" />
    </td>
  </tr>
  </tbody>
</table>
</form>
<br /><a href="index.php">Back to main</a>
<?php
include ('includes/overall_tail.tpl');
exit;
}
?>
