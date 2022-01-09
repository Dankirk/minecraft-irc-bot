<?php
require_once("mysql.php");

// Displays the server
function displayServer($servid,$DB,$msg,$checkpass = 1,$option = 1) {

	# If password isn't set, direct user to password change
	if ($checkpass >= 1) {
		if ($checkpass == 1) {
			$query = sprintf("select pass from servers where id = %d", $servid);
			$pass = getSingleValue($query, $DB);
			if (empty($pass)) {
				include("changepw.html");
				return;
			}
		}
		else {
			include("changepw.html");
			return;
		}
	}

	##########
	# MENU BUTTONS
	##############
	?>

	<div id=nav-menu><ul>
	<li>
	<form action="index.php" method="POST">
	<input type="hidden" name="settings" value="1">
	<input type="submit" value="Settings">
	</form> </li><li>
	<form action="index.php" method="POST">
	<input type="hidden" name="ranksset" value="1">
	<input type="submit" value="Ranks">
	</form> </li><li>
	<form action="index.php" method="POST">
	<input type="hidden" name="customrules" value="1">
	<input type="submit" value="Custom Rules">
	</form> </li><li>
	<form action="index.php" method="POST">
	<input type="hidden" name="stats" value="1">
	<input type="submit" value="Stats">
	</form> </li><li>
	<form action="index.php" method="POST">
	<input type="hidden" name="ch_pw" value="1">
	<input type="submit" value="Change Password">
	</form> </li><li>
	<form action="index.php" method="POST">
	<input type="hidden" name="logout" value="1">
	<input type="submit" value="Logout">
	</form>	</li>
	</ul></div>

	<?php /*
	<div id=nav-menu><ul>
	<li><a href="index.php?page=settings">Settings</a></li>
	<li><a href="index.php?page=ranksset">Ranks</a></li>
	<li><a href="index.php?page=customrules">Custom Rules</a></li>
	<li><a href="index.php?page=stats">Stats</a></li>
	<li><a href="index.php?page=ch_pw">Change Password</a></li>
	<li><a href="index.php?page=logout">Logout</a></li>
	</ul></div>*/ ?>
	
	<div id="pagedata">
	
	
	<?php
	
	###############
	# SERVER SETTINGS PAGE
	######################
	if ($option == 1) {		
		
		$ranks = true;
		$impersonation = true;
		$funfacts = true;
		$jokes = true;
		$pony = true;	
		$botname = "";
		$bothauth = "";
		$website = "";
		$servname = "";
		$howtofly = "";
		$muted = false;
		$multilang = false;
		$disableplayers = false;
		
		$query = sprintf("select Name, Ranks, Impersonation, FunFacts, Jokes, Pony, Botname, BotAuth, Website, DispName, HowToFly, Muted, Multilang, PublicStats, disableplayers from Servers where id = %d",$servid);
		$res = mysql_query($query, $DB);
		if ($res) {
			if ($row = mysql_fetch_assoc($res)) {	
				$channame = htmlentities($row['Name']);
				$ranks = $row['Ranks'];
				$impersonation = $row['Impersonation'];
				$funfacts = $row['FunFacts'];
				$jokes = $row['Jokes'];
				$pony = $row['Pony'];
				$botname = htmlentities($row['Botname']);
				$botauth = htmlentities($row['BotAuth']);
				$website = htmlentities($row['Website']);
				$servname = htmlentities($row['DispName']);
				$howtofly = htmlentities($row['HowToFly']);
				$publicstats = $row['PublicStats'];
				$multilang = $row['Multilang'];
				$muted = $row['Muted'];
				$disableplayers = $row['disableplayers'];
			}
			mysql_free_result($res);
		}
		?>
		
		<h2> Server Settings - <?php echo $channame; ?></h2>
		
		<form action="index.php" method="POST">
		<div style="float: left">
		<table>
		<tr><td align=right>Server Name </td><td><input type="editbox" name="servname" maxlength=32  size=60 value="<?php echo $servname; ?>" /></td></tr>
		<tr><td align=right>Bot Name Regex </td><td><input type="editbox" name="botname" maxlength=64 size=60 value="<?php echo $botname; ?>" /></td></tr>
		<tr><td align=right>Bot Auth Name </td><td><input type="editbox" name="botauth" maxlength=32 size=60 value="<?php echo $botauth; ?>" /></td></tr>
		<tr><td align=right>Website </td><td><input type="editbox" name="website" maxlength=128  size=60 value="<?php echo $website; ?>" /></td></tr>
		<tr><td align=right>How to Fly </td><td><input type="editbox" name="howtofly" maxlength=128  size=60 value="<?php echo $howtofly; ?>" /></td></tr>
		</table>
		</div><div style="float: left">
		<table >
<tr><td> <input type="checkbox" name="muted" <?php echo retCheck($muted); ?> value=true />Bot Muted/Disabled</td></tr>
<tr><td></td></tr>		
		<tr><td> <input type="checkbox" name="publicstats" <?php echo retCheck($publicstats); ?> value=true />Listed in Frontpage Stats</td></tr>
		<tr><td> <input type="checkbox" name="ranks" <?php echo retCheck($ranks); ?> value=true />Rank Detection</td></tr>
		<tr><td> <input type="checkbox" name="impersonation" <?php echo retCheck($impersonation); ?> value=true />Impersonation Check</td></tr>
		<tr><td> <input type="checkbox" name="funfacts" <?php echo retCheck($funfacts); ?> value=true />Fun Facts</td></tr>
		<tr><td> <input type="checkbox" name="jokes" <?php echo retCheck($jokes); ?> value=true />Jokes</td></tr>
		<tr><td> <input type="checkbox" name="pony" <?php echo retCheck($pony); ?> value=true />Sing-along Themes (My Little Pony, Pokemon)</td></tr>
		<tr><td> <input type="checkbox" name="disableplayers" <?php echo retCheck($disableplayers); ?> value=true />Disable !players (server may already provide this)</td></tr>
		<tr><td> <input type="checkbox" name="multilang" <?php echo retCheck($multilang); ?> value=true />Disable !english (multilanguage / Non-English server)</td></tr>
		</table>
		
		</div><div style="clear: both; float: right">
		<input type="hidden" name="set_save" value="1" />
		<input type="submit" value="Save" style="height: 30px; width: 140px" />
		</div>
		<div style="clear: both"></div>
		</form>
		
		<?php

	}
	###########
	# STATS PAGE
	#################
	else if ($option == 2) {
		$query = sprintf("select Name from servers where id = %d", $servid);
		$channame = htmlentities(getSingleValue($query, $DB));
		?>
		
		<h2> Server and OP Stats - <?php echo $channame; ?></h2>
		<table><tr><td valign=top>
		
		<!-- Server -->
		<table  border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>Visitors</b></td><td><b>Kicks</b></td><td><b>Bans</b></td><td><b>Promotes</b></td><td><b>Demotes</b></td><td><b>Replies</b></td><td><b>Thanks</b></td></tr><tr bgcolor="beige">
		<?php
		$query = sprintf("select Visitors, Kicks, Bans, Promotes, Demotes, Replies, Thanks from Servers where id = %d", $servid);	
		print_tablerows($query,$DB);
		?>
		
		<!-- Ops -->
		<table  border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>OP Name</b></td><td><b>Kicks</b></td><td><b>Bans</b></td><td><b>Promotes</b></td><td><b>Demotes</b></td><td><b>Promotees Demoted</b></td></tr>
		<?php
		$query = sprintf("select Name, Kicks, Bans, Promotes, Demotes, Promobfires from Ops where Server = %d", $servid);						
		print_tablerows($query,$DB);
		?>
		
		</td><td valign=top>
		
		<!-- RankedVisitors	-->
		<table valign=top  border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>Rank</b></td><td><b>Visitors</b></td></tr>
		<?php 
		$query = sprintf("select Title, num from RankedVisitors where Server = %d order by Rank", $servid);					
		print_tablerows($query,$DB);
		?>
		
		<!-- Stats -->
		<table valign=top  border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>Date</b></td><td><b>Visitors</b></td><td><b>Kicks</b></td><td><b>Bans</b></td><td><b>Promotes</b></td><td><b>Demotes</b></td><td><b>Replies</b></td></tr>
		<?php
		$query = sprintf("select Date, Visitors, Kicks, Bans, Promotes, Demotes, Replies from Stats where Server = %d", $servid);
		print_tablerows($query,$DB);
		?>
		
		</td></tr></table>
		<?php
	}
	#############
	# RANKS PAGE
	#################
	else if ($option == 3) {
		$query = sprintf("select Name from servers where id = %d", $servid);
		$channame = htmlentities(getSingleValue($query, $DB));
		?>
		<h2> Rank Settings - <?php echo $channame; ?></h2>
		<font color="red"><?php echo $msg; ?></font>
		<form accept-charset="utf-8" enctype="multipart/form-data" name="rank_form" id="rank_form" action="index.php" method="POST">
		
		
		<script src="ranks.js"></script>
		<div style="float: left">
		<table id="RankTable" cellspacing="0" cellpadding="1" ><tr>
		<td>Title</td>
		<td>Tier</td>
		<td>Prefix</td>
		<td>Color</td>
		<td>To get promoted to</td>
		<td>Preview</td>
		</tr>
		
		<?php
		$i = 1;
		$query = sprintf("select Title, Rank, Color, Prefix, PromoTo from RankedVisitors where Server = %d order by Rank",$servid);
		$res = mysql_query($query, $DB);
		if ($res) {	
			while ($row = mysql_fetch_assoc($res)) {
				?><tr>
				<td><input type="text" size=16 maxlength=16 name="rank_title[]" value="<?php echo htmlentities($row['Title']); ?>" /></td> 
				<td><input type="text" size=2 maxlength=2 name="rank_val[]"  value="<?php echo $row['Rank']; ?>" /></td>
				<td><input type="text" size=2 maxlength=1 name="rank_prefix[]" onkeyup="setExample()" value="<?php echo htmlentities($row['Prefix']); ?>" /></td>
				<td><select name="rank_color[]" onchange="setExample()">
				<option value=0 <?php echo retSelect(0,$row['Color']); ?>>white</option>
				<option value=1 <?php echo retSelect(1,$row['Color']); ?>>black</option>
				<option value=2 <?php echo retSelect(2,$row['Color']); ?>>navy (blue)</option>
				<option value=3 <?php echo retSelect(3,$row['Color']); ?>>green</option>
				<option value=4 <?php echo retSelect(4,$row['Color']); ?>>red</option>
				<option value=5 <?php echo retSelect(5,$row['Color']); ?>>maroon (red)</option>
				<option value=6 <?php echo retSelect(6,$row['Color']); ?>>purple</option>
				<option value=7 <?php echo retSelect(7,$row['Color']); ?>>olive</option>
				<option value=8 <?php echo retSelect(8,$row['Color']); ?>>yellow</option>
				<option value=9 <?php echo retSelect(9,$row['Color']); ?>>lime</option>
				<option value=10 <?php echo retSelect(10,$row['Color']); ?>>teal</option>
				<option value=11 <?php echo retSelect(11,$row['Color']); ?>>aqua</option>
				<option value=12 <?php echo retSelect(12,$row['Color']); ?>>blue</option>
				<option value=13 <?php echo retSelect(13,$row['Color']); ?>>magenta (pink)</option>
				<option value=14 <?php echo retSelect(14,$row['Color']); ?>>grey</option>
				<option value=15 <?php echo retSelect(15,$row['Color']); ?>>silver</option>	
				</select></td>
				<td><select name="rank_promoto[]">
				<option value=0 <?php echo retSelect(0,$row['PromoTo']); ?>>None</option>
				<option value=1 <?php echo retSelect(1,$row['PromoTo']); ?>>Build good</option>
				<option value=2 <?php echo retSelect(2,$row['PromoTo']); ?>>Apply at website</option>
				<option value=3 <?php echo retSelect(3,$row['PromoTo']); ?>>Automatic/Stats</option>
				<option value=4 <?php echo retSelect(4,$row['PromoTo']); ?>>Manual/Stats</option>
				<option value=5 <?php echo retSelect(5,$row['PromoTo']); ?>>Donate</option>
				</select></td>
				<td><input type="text" size=8 maxlength=18 id="rank_example[]" readonly="readonly" value="" /></td>
				<td><img src="del.png" onclick="delRow('RankTable', <?php echo $i; ?>)" /></td>
				</tr>
				<?php
				$i = $i + 1;
			}
			mysql_free_result($res);
		}
		while ($i < 4) {
				?>
				<script type="text/javascript">addRow('RankTable');</script>
				<?php
				$i = $i + 1;
		}
		?>	
		</table>
		<input type="button" value="Add Rank" onclick="addRow('RankTable')" />
		
		<?php
		$query = sprintf("SELECT Prefix, Color, Nickname from RankErrors where Server = %d",$servid);
		$res = mysql_query($query, $DB);
		if ($res) {
			$i = 1;
			while ($row = mysql_fetch_assoc($res)) { 
				if ($i == 1) {
					echo "<br><br><font color=\"red\">Errors since last save: <br>";
					$i = 2;
				}
				$pref = null;
				if (strlen($row['Prefix']) > 0) {
					$pref = " Prefix: " . htmlentities($row['Prefix']);
				}
				echo "Couldn't find rank for: " . htmlentities($row['Nickname']) . $pref . " Color: " . htmlentities($row['Color']) . "<br>";
			}
			if ($i == 2) {
				echo "</font>";
			}
			mysql_free_result($res);
		}	
		?>
				
		</div><div style="float: left;">
		<font color=darkblue>		
		Notes:<br>
		- The rank with tier 0 is the lowest rank.<br>
		- Ranks must have unique color+prefix combinations.<br>
		- Changing settings will reset rank specific stats.<br>
		</font><br><br>	
		<?php
			
			$multic = 0;
			$modrank = 0;
			$spleefrank = 0;
			$muterank = 0;
			$waterrank = 0;
			$hidesilent = 0;
		
			$query = sprintf("select MultiColorValue, PromoRank, SpleefRank, MuteRank, WaterRank, HideSilent from Servers where id = %d",$servid);
			$res = mysql_query($query, $DB);
			if ($res) {
				if ($row = mysql_fetch_assoc($res)) {
					$multic = $row['MultiColorValue'];
					$modrank = $row['PromoRank'];
					$spleefrank = $row['SpleefRank'];
					$muterank = $row['MuteRank'];
					$waterrank = $row['WaterRank'];
					$hidesilent = $row['HideSilent'];
				}
			}
		?>
		<table cellspacing="0" cellpadding="1">		
		<tr><td align=right>Multicolor/edited names treated as tier </td><td><input type="text" size=3 maxlength=2 name="ranks_multic" value=<?php echo $multic;?>></td></tr>
		<tr><td align=right>Lowest tier able to promote </td><td><input type="text" size=3 maxlength=2 name="ranks_mod" value=<?php echo $modrank;?>></td></tr>
		<tr><td align=right>Lowest tier able to !spleef </td><td><input type="text" size=3 maxlength=2 name="ranks_spleef" value=<?php echo $spleefrank;?>></td></tr>
		<tr><td align=right>Lowest tier able to !mute </td><td><input type="text" size=3 maxlength=2 name="ranks_mute" value=<?php echo $muterank;?>></td></tr>
		<tr><td align=right>Lowest tier able to do /water </td><td><input type="text" size=3 maxlength=2 name="ranks_water" value=<?php echo $waterrank;?>></td></tr>
		<tr><td align=right>Lowest tier able to /hide silently </td><td><input type="text" size=3 maxlength=2 name="ranks_hidesilent" value=<?php echo $hidesilent;?>></td></tr>
		</table>
		<br><p align=right><INPUT TYPE="submit" VALUE="Save" style="height: 30px; width: 140px" /></p>
		</div>
		<div style="clear: both"></div>
		<input type="hidden" name="ranks_save" value="1">
		</form>
		
		<script type="text/javascript">
		window.onload=setExample;
		</script>
		<?php
	}
	
	###################
	# CUSTOM RULES PAGE
	####################
	else if ($option == 4) {
		
		$query = sprintf("select Name from servers where id = %d", $servid);
		$channame = htmlentities(getSingleValue($query, $DB));
		?>
		<h2> Custom Rules - <?php echo $channame; ?></h2>
		<font color="red"><?php echo $msg; ?></font>
		<form accept-charset="utf-8" enctype="multipart/form-data" name="rule_form" id="rule_form" action="index.php" method="POST">
		
		
		<script src="customrules.js"></script>
		
		<font color=darkblue>
		Here you can make Dankirk reply to something new by defining a "<a href="http://www.regular-expressions.info/reference.html">regular expression</a>".<br>
		<br>
		The site will attempt to autocorrect invalid regexes and make them case insensitive.<br>
		However, remember to use \ infront of the following special characters: []/^$.|?*+-()<br>
		<br>
		For example: <font color="red">"Is this working?"</font> should be written as <font color="red">"Is this working\?"</font><br>
		<br>
		You may use following variables in your replies: $nick $rank $nextrank $ircnames $players<br>
		<br>
		A performance and accuracy test will be performed on the expressions to determine that they can be used efficiently.<br>
		Should the tests fail the corresponding expressions will be disabled.<br>
		</font>
		<br>
		
		<table id="RuleTable" cellspacing="0" cellpadding="1"><tr>
		
		<td></td>
		<td>Regex Match</td>
		<td>Reply</td>
		<td></td>
		</tr>
		
			
		<?php
		$i = 1;
		$query = sprintf("select enabled, regmatch, reply from CustomRules where Server = %d",$servid);
		$res = mysql_query($query, $DB);
		if ($res) {
			while ($row = mysql_fetch_assoc($res)) {
				?><tr>	
				<td><input type="checkbox" name="rule_enabled[<?php echo ($i-1); ?>]" <?php echo ($row['enabled']) ? "checked=checked value='1'" : "value='0' height='10'"; ?> /></td> 
				<td><input type="text" size=64 maxlength=256 name="rule_match[<?php echo ($i-1); ?>]"  value="<?php echo htmlentities($row['regmatch']); ?>" /></td>
				<td><input type="text" size=64 maxlength=128 name="rule_reply[<?php echo ($i-1); ?>]" value="<?php echo htmlentities($row['reply']); ?>" /></td>
				<td><img src="del.png" onclick="delRow('RuleTable', <?php echo $i; ?>)" ></td>
				</tr>
				<?php
				$i = $i + 1;
			}
			mysql_free_result($res);
	
		}
		?>
		</table>
		<?php
		if ($i < 4) {
			?>
			<script type="text/javascript">
			<?php
			while ($i < 4) {
					?>
					addRow('RuleTable');
					<?php
					$i = $i + 1;
			}
			?></script><?php
		}
		?>	
		<div style="float: left">
		<input type="button" value="Add Rule" style="height: 25px; width: 100px" onclick="addRow('RuleTable')" />
		</div><div style="float: right; padding-right: 100px;">
		<input type="submit" value="Save" style="height: 30px; width: 140px" />
		</div>
		<div style="clear: both"></div>
		<input type="hidden" name="rules_save" value="1">	
		</form>
		<?php
	}
	#####
	
	?>
	</div>
	<?php
}
function retSelect($v1, $v2) {
	if ($v1 == $v2)
		return "selected=\"selected\"";
	else
		return "";
}
function retCheck($value) {
	if ($value == true)
		return "checked=checked";
	else
		return "";
}
function print_tablerows($query, $DB, $type = 0) {					
	$res = mysql_query($query, $DB);
	if ($res) {
		
		$color = "aquamarine";
		$colori = 1;
		
		while ($row = mysql_fetch_row($res)) {
			
			echo "<tr bgcolor=\"" . $color . "\">";
			$i = 0;
			while ($i < count($row)) {
				echo "<td>" . htmlentities($row[$i]) . "</td>";	
				$i = $i + 1;
			}	
			echo "</tr>";
			
			if ($colori == 1) {
				$colori = 2;
				$color = "beige";
			}
			else {
				$colori = 1;
				$color = "aquamarine";
			}
		}
		echo "</table>";
		
		mysql_free_result($res);
	}
}
function OpWithMostQuery($column) {
	return "select servers.Dispname, op.name, op.col from
	(select server, name, ". $column ." as col from ops where (NOW() - lastaction) < (21*86400) and ". $column ." >= 5 and server in
	(select id from servers where publicstats = 1) order by ". $column ." DESC) as op 
	inner join servers on server=servers.id
	group by server";
}
function testRegex($reg) {

	$testPhrases = array(
		"Hello World!",
		"aaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbcccccccccccdddddddddddd",
		"1234567890987654321234567890987654321",
		"[][][][][]]]][[[()()()()/{]}}}{{&¤&%¤%&/%¤====?++--@@@¤¤¤%",
		"asdcdefg1323456{{{]][[[[((",
		"you can not see how this does work at all can you now?",
		"This shouldn't be triggering so often."
	);
	$matches = 0;
	$timeout = 0.05;

	for ($i = 0; $i < count($testPhrases); $i++) {
		$start = microtime(true);
		if (preg_match($reg, $testPhrases[$i])) {
			$matches++;
			if ($matches > 1) 
				return false;
		}
		#$diff = (microtime(true) - $start);
		#echo "test " . ($i+1) . "/" . count($testPhrases) . " took " . $diff . " seconds.<br>";
		if ((microtime(true) - $start) > $timeout) 
			return false;
	}	
	
	return true;
}
?>