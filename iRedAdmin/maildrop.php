<?php

require_once ('includes/config.inc.php');
require_once ('includes/login.inc.php');

$program = "src/maildrop/maildrop";

//Header: [From|To|Subject]
//Contains: the keyword that matches with
//Action: 0-deliver to mailbox, 1-redirect to other email, 2-send a copy to other email
//Target: a mailbox name or a target email address

$username=$_SESSION["email"];
$password=$_SESSION["crypt"];

$entries_from_post = parse_post_entries();
if ($entries_from_post!==false) {
	write_mailfilter($entries_from_post, $username, $password);
	$entries_from_mailfilterrc = read_mailfilter($username, $password);
	if ($entries_from_mailfilterrc!=$entries_from_post) {
		echo "Error: program error\n";
		echo "<pre>";
		echo "entries from post\n";
		print_r($entries_from_mailfilterrc);
		echo "\n\n";
		echo "entries from mailfilterrc\n";
		print_r($entries_from_mailfilterrc);
		echo "\n\n";
		echo "</pre>";
	}
	else {
		show_html($entries_from_mailfilterrc, "Success: Maildrop updated!!");
	}
}
else {
	show_html(read_mailfilter($username, $password));
}

exit;

function parse_post_entries() {
	if (!$_POST["find"] || !$_POST["contains"] || !$_POST["action"] || !$_POST["target"])
		return false;
	$cnt = count($_POST["find"]);
	if (count($_POST["contains"])!=$cnt || count($_POST["action"])!=$cnt || count($_POST["target"])!=$cnt) {
		die("Error: entries count not equal");
	}
	$entries = array();
	$j=0;
	for ($i=0;$i<$cnt;$i++) {
		if (trim($_POST["contains"][$i])!="" && trim($_POST["target"][$i])!="") {
			$entries[$j]["Find"] = $_POST["find"][$i];
			$entries[$j]["Contains"] = trim($_POST["contains"][$i]);
			$entries[$j]["Action"] = $_POST["action"][$i];
			$entries[$j++]["Target"] = trim($_POST["target"][$i]);
		}
	}
	return $entries;
}

function read_mailfilter($username, $password) {
	global $program;
    $command = "$program $username $password get";
    exec($command,$result);
    if (strpos($result[0], "Error") !== false )
    	die($result[0]);
    return mailfilterrc_to_entries($result);
}

function mailfilterrc_to_entries($input) {
    $entries = array();
    $pattern1 = '/^if \( \/\^(From|To|Subject):\\\\s\*\(\.\*\)(.*)\/ \)$/';  //if ( /^From:\s*(.*)@abc.com/ )
    $pattern2 = '/^                to \$DEFAULT\/\.(.*)\/$/';  //to $DEFAULT/.Spam/
    $pattern3 = '/^                to \\\'\|\$SENDMAIL -f "\$SENDER" -i "(.*)"\'$/';  //to '|$SENDMAIL -f "$SENDER" -i "billy@abc.com.hk"'
    $pattern4 = '/^                cc "!(.*)"/';  //cc "!test@gmail.com"

    for ($i=0;$i<count($input);$i++) {
        $buffer=$input[$i];
        if (preg_match($pattern1 , $buffer,$matches)) {
            $Find=$matches[1];
            $Contains=unescape_regex($matches[2]);
            for ($i++;$i<count($input);$i++) {
                $buffer=$input[$i];
                if (preg_match($pattern2 , $buffer,$matches)) {
                    //deliver to mailbox
                    $Action=0;
                    $Target=$matches[1];
                    $entries[] = array("Find"=>$Find, "Contains"=>$Contains, "Action"=>$Action, "Target"=>$Target);
                    break 1;
                }
                else if (preg_match($pattern3 , $buffer,$matches)) {
                    //redirect to another mail
                    $Action=1;
                    $Target=$matches[1];
                    $entries[] = array("Find"=>$Find, "Contains"=>$Contains, "Action"=>$Action, "Target"=>$Target);
                    break 1;
                }
                else if (preg_match($pattern4 , $buffer,$matches)) {
                    //cc to another mail
                    $Action=2;
                    $Target=$matches[1];
                    $entries[] = array("Find"=>$Find, "Contains"=>$Contains, "Action"=>$Action, "Target"=>$Target);
                    break 1;
                }
            }
        }
    }
    return $entries;
}

function write_mailfilter($entries, $username, $password) {
    $filename = '/tmp/'.rand(100000000,999999999).'_mf.tmp';
    while (file_exists($filename))
	    $filename = '/tmp/'.rand(100000000,999999999).'_mf.tmp';
    ($handle = fopen($filename, 'w+')) or die ("ERROR: Cannot open file $tmp_filename for writing");

	$content = entries_to_mailfilterrc($entries);

    if (fwrite($handle, $content) === FALSE) {
        echo "Cannot write to file ($tmp_filename)";
        exit;
    }
    global $program;
    $command = "$program $username $password set $filename";
    exec($command, $result);
    unlink($filename);
}

function entries_to_mailfilterrc($entries) {
    $content='logfile "/var/log/mail/maildrop.log"'."\n";
    $content.='log "------------------------------------------------------------"'."\n";
    $content.='if (/^X-Spam-Flag:.*YES/)'."\n";
    $content.='{'."\n";
    $content.='        `test -d $DEFAULT.Spam`'."\n";
    $content.='        if( $RETURNCODE == 1 )'."\n";
    $content.='        {'."\n";
    $content.='                log "creating $DEFAULT/.Spam"'."\n";
    $content.='                `/usr/bin/maildirmake -f Spam $DEFAULT`'."\n";
    $content.='                `echo Spam >> $DEFAULT/subscriptions`'."\n";
    $content.='        }'."\n";
    $content.='        log ">>> TAGGED AS [SPAM]"'."\n";
    $content.='        log ">>> Mail successfully delivered to \$DEFAULT/.Spam"'."\n";
    $content.='        exception {'."\n";
    $content.='                to $DEFAULT/.Spam/'."\n";
    $content.='        }'."\n";
    $content.='}'."\n";
    $content.="\n";
    $content.="\n";
    if (is_array($entries)) {
        foreach ($entries as $value) {
            $content.='if ( /^'.$value["Find"].':\s*(.*)'.escape_regex($value["Contains"])."/ )\n";
            $content.="{\n";
            //deliver to mailbox
            if ($value["Action"]=="0") {
                $content.="        `test -d \$DEFAULT.".$value["Target"]."`\n";
                $content.="        if( \$RETURNCODE == 1 )\n";
                $content.="        {\n";
                $content.="                log \"creating \$DEFAULT/.".$value["Target"]."\"\n";
                $content.="                `/usr/bin/maildirmake -f ".$value["Target"]." \$DEFAULT`\n";
                $content.="                `echo ".$value["Target"]." >> \$DEFAULT/subscriptions`\n";
                $content.="        }\n";
                $content.="        exception {\n";
                $content.="                to \$DEFAULT/.".$value["Target"]."/\n";
                $content.="        }\n";
            } else if ($value["Action"]=="1") {
                $content.="        exception {\n";
                $content.="                to '|\$SENDMAIL -f \"\$SENDER\" -i \"".$value["Target"]."\"'\n";
                $content.="        }\n";
            } else if ($value["Action"]=="2") {
                $content.="        exception {\n";
                $content.="                cc \"!".$value["Target"]."\"\n";
                $content.="        }\n";
            }

            $content.="}\n\n";
        }
    }
    return $content;
}


function escape_regex($string) {
    $match=array('\\', '/', '+', '*', '?', '.', '[', ']', '^', '$', '(', ')', '{', '}', '|', '&', '!', ';', '`', '\'', '-', '~', '<', '>', '"');
    $replace=array('\\\\', '\/', '\+', '\*', '\?', '\.', '\[', '\]', '\^', '\$', '\(', '\)', '\{', '\}', '\|', '\&', '\!', '\;', '\`', '\\\'', '\-', '\~', '\<', '\>', '\"');
    return str_replace($match,$replace,$string);
}

function unescape_regex($string) {
    $replace=array('\\', '/', '+', '*', '?', '.', '[', ']', '^', '$', '(', ')', '{', '}', '|', '&', '!', ';', '`', '\'', '-', '~', '<', '>', '"');
    $match=array('\\\\', '\/', '\+', '\*', '\?', '\.', '\[', '\]', '\^', '\$', '\(', '\)', '\{', '\}', '\|', '\&', '\!', '\;', '\`', '\\\'', '\-', '\~', '\<', '\>', '\"');
    return str_replace($match,$replace,$string);
}

function show_html($entries, $message="") {
	include ('includes/overall_header.tpl');
	$content .= '    <h1>Maildrop</h1>';
	$content .= "    $message\n";
	$content .= '    <form id="form1" name="form1" method="post" action="">'."\n";
	$content .= '      <table width="200" border="1">'."\n";
	$content .= '        <tr>'."\n";
	$content .= '          <th>Find</th>'."\n";
	$content .= '          <th>Contains</th>'."\n";
	$content .= '          <th>Action</th>'."\n";
	$content .= '          <th>Target</th>'."\n";
	$content .= '        </tr>'."\n";
	for ($i=0; $i<count($entries);$i++) {
		$content .= '        <tr>'."\n";
		$content .= '          <td>'."\n";
		$content .= '            <select name="find[]" id="find[]">'."\n";
		$content .= '              <option value="From"'; if ($entries[$i]["Find"]=="From")$content .= 'selected="selected"';$content .= '>From</option>'."\n";
		$content .= '              <option value="To"'; if ($entries[$i]["Find"]=="To")$content .= 'selected="selected"';$content .= '>To</option>'."\n";
		$content .= '              <option value="Subject"'; if ($entries[$i]["Find"]=="Subject")$content .= 'selected="selected"';$content .= '>Subject</option>'."\n";
		$content .= '            </select>'."\n";
		$content .= '          </td>'."\n";
		$content .= '          <td><input name="contains[]" type="text" id="contains[]" value="'.$entries[$i]["Contains"].'"/></td>'."\n";
		$content .= '          <td>'."\n";
		$content .= '            <select name="action[]" id="action[]">'."\n";
		$content .= '              <option value="0"'; if ($entries[$i]["Action"]=="0")$content .= 'selected="selected"';$content .= '>Move to mailbox</option>'."\n";
		$content .= '              <option value="1"'; if ($entries[$i]["Action"]=="1")$content .= 'selected="selected"';$content .= '>Redirect to</option>'."\n";
		$content .= '              <option value="2"'; if ($entries[$i]["Action"]=="2")$content .= 'selected="selected"';$content .= '>Send a copy to</option>'."\n";
		$content .= '            </select>'."\n";
		$content .= '          </td>'."\n";
		$content .= '          <td><input name="target[]" type="text" id="target[]" value="'.$entries[$i]["Target"].'"/></td>'."\n";
		$content .= '        </tr>'."\n";
	}
	for ($j=0; $j<5;$j++) {
		$content .= '        <tr>'."\n";
		$content .= '          <td>'."\n";
		$content .= '            <select name="find[]" id="find[]">'."\n";
		$content .= '              <option value="From">From</option>'."\n";
		$content .= '              <option value="To">To</option>'."\n";
		$content .= '              <option value="Subject">Subject</option>'."\n";
		$content .= '            </select>'."\n";
		$content .= '          </td>'."\n";
		$content .= '          <td><input name="contains[]" type="text" id="contains[]"/></td>'."\n";
		$content .= '          <td>'."\n";
		$content .= '            <select name="action[]" id="action[]">'."\n";
		$content .= '              <option value="0">Move to mailbox</option>'."\n";
		$content .= '              <option value="1">Redirect to</option>'."\n";
		$content .= '              <option value="2">Send a copy to</option>'."\n";
		$content .= '            </select>'."\n";
		$content .= '          </td>'."\n";
		$content .= '          <td><input name="target[]" type="text" id="target[]"/></td>'."\n";
		$content .= '        </tr>'."\n";
	}

	$content .= '        <tr>'."\n";
	$content .= '          <td colspan="4"><input type="submit" name="submit" value="submit"/></td>'."\n";
	$content .= '        </tr>'."\n";
	$content .= '      </table>'."\n";
	$content .= '    </form>'."\n";
	echo $content;

	echo "<br><a href=\"index.php\">Back to main</a>";
	include ('includes/overall_header.tpl');
}
?>
