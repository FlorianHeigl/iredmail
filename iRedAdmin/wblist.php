<?php

require_once ('includes/config.inc.php');
require_once ('includes/login.inc.php');

$email = mysql_escape_string($_SESSION['email']);
$sql = "select id from users where email = '" .mysql_escape_string($email). "'";
$res = mysql_query($sql, $link) or die ("Unable to run query");
$row = mysql_fetch_array($res);
$id=$row['id'];

if ($_POST['target']!="") {
	if (!is_numeric($_POST['priority']))
		$_POST['priority'] = 5;
	else
		$_POST['priority'] = (int)$_POST['priority'];
	if ($_POST['wblist'] != "W" && $_POST['wblist'] !="B" )
		$_POST['wblist'] = "W";

	$sql = "select * from av_wblist where id = '$id' and target = '" . mysql_escape_string($_POST['target']) . "'";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_num_rows($res)!=0)
		wblist_html( "<font color=red>Address already exist!!</font>");
	$sql = "insert into av_wblist (`id`, `target`, `wb`, `priority`) values ('$id', '" . mysql_escape_string($_POST['target']) . "', '$_POST[wblist]', '$_POST[priority]')";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_affected_rows()==1) {
		$msg = ($_POST['wblist'] == "W")? "<font color=green>Address added into white list</font>" : "<font color=green>Address added into black list</font>";
		wblist_html($msg);
	}
} else {
	if ( @is_array($_POST['chkbox'] )) {
		foreach($_POST['chkbox'] as $v) {
			if (isset($v)) {
				$del_sql = "DELETE FROM av_wblist WHERE id='$id' and target = '" . mysql_escape_string($v) . "'";
				$res = mysql_query($del_sql, $link) or die ("Unable to run query");
				$del=true;
			}
		}
	}
	if ($del)
		wblist_html("<font color=green>Record successful deleted!!</font>");
	wblist_html();
}

function wblist_html($message=null) {
	global $link;
	global $id;
	$extraheader="<title>White/Black List</title>";
	include ('includes/overall_header.tpl');
?>
<h1> White / Black List Control </h1>
<?=$message?>
<form id="form1" name="form1" method="post" action="">
  Address: <input type="text" name="target" size="30" maxlength="255" />&nbsp;&nbsp;
  Priority: <input type="text" name="priority" size="5" maxlength="5" />&nbsp;&nbsp;
  <select name="wblist">
    <option value="W" selected="selected">white list</option>
    <option value="B">black list</option>
  </select>&nbsp;&nbsp;
  <input type="submit" name="Add" value="Add" />
</form>
<hr width="500" align="left" />
<?php
	$sql = "select * from av_wblist where id = '$id' order by priority desc";
	$res = mysql_query($sql, $link) or die ("Unable to run query");
	if (mysql_num_rows($res)!=0) {
		?>
<form id="form2" name="form2" method="post" action="">
  <table width="500" border="1">
    <tr>
      <th width="360" align="center">Address</th>
      <th width="60" align="center">White/Black</th>
      <th width="60" align="center">Priority</th>
      <th width="20" align="center">X</th>
    </tr>
<?php
 		while ($row = mysql_fetch_assoc($res))    {
?>    <tr>
      <td><?=$row[target]?></td>
      <td><?=$row[wb]?></td>
      <td><?=$row[priority]?></td>
      <td><input name="chkbox[]" type="checkbox" value="<?=$row[target]?>" /></td>
    </tr>
<?php
		}//end while
		?>
    <tr>
      <td align="right" colspan="4"><input name="Delete" type="submit" id="Delete" value="Delete" /></td>
    </tr>
  </table>
</form>
<?php
	} //end if
	echo "<br /><a href=\"index.php\">Back to main</a>\n";
	include ('includes/overall_tail.tpl');
	exit;
} //end function

?>
