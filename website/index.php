<?php
date_default_timezone_set("Europe/Helsinki");

// Communication scripts
require_once("mirc.php");
require_once("mysql.php");

//Website scripts
require_once("login.php");
require_once("display.php");
?>
<!DOCTYPE html>
<html>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link href="style.css" rel="stylesheet" type="text/css" />
<title>Dankirk - MC AutoReply</title>
</head>

<body class="style">
<div id="header">
	<h1>Dankirk - MC AutoReply</h1>
</div>

<div id="main">
	<div id="leftside"><img src="dankirk.png"></div>
	<div id="content">
<?php 

	$login = 0;
	$msg = "";
	$DB = MA_ConDB(); 

	list($servid,$askpw) = GetLoginInfo($DB);
	
	if ($servid > 0) {
		$login = 1;
		
		if (isset($_POST["logout"])) {
			$login = -1;
			Logout($servid,$DB);
		}
		else if (isset($_POST['ch_pw'])) {
			include("changepw.html");
		}
		else {				

			$option = 1;		
			
			if (isset($_POST['ch_pass1']) && isset($_POST['ch_pass2'])) {
				$pass1 = $_POST['ch_pass1'];
				$pass2 = $_POST['ch_pass2']; 
		
				if ($pass1 === $pass2) {
					if (strlen($pass1) > 16 || strlen($pass1) < 6) {
						$askpw = 2;
						echo "<font color=\"blue\">Password must be between 6-16 characters long.</font><br>";
					}
					else {
						echo "<font color=\"blue\">Password changed.</font><br>";
						$query = sprintf("update Servers set pass = '%s', token = null where id = %d", 
						md5($pass1), $servid);
						mysql_query($query,$DB);
					}
				}
				else {
					$askpw = 2;
					echo "<font color=\"blue\">Passwords didn't match.</font><br>";
				}
				
			}
			else if (isset($_POST['stats'])) {
				$option = 2;
			}
			else if (isset($_POST['ranksset'])) {
				$option = 3;
			}
			else if (isset($_POST['ranks_save'])) {
				$option = 3;
				
				$error = 0;
				if (!isset($_POST['ranks_multic']) || $_POST['ranks_multic'] < 0 || $_POST['ranks_multic'] > 999 ||
					!isset($_POST['ranks_mod']) || $_POST['ranks_mod'] < 0 || $_POST['ranks_mod'] > 999 ||
					!isset($_POST['ranks_spleef']) || $_POST['ranks_spleef'] < 0 || $_POST['ranks_spleef'] > 999 ||
					!isset($_POST['ranks_mute']) || $_POST['ranks_mute'] < 0 || $_POST['ranks_mute'] > 999 ||
					!isset($_POST['ranks_water']) || $_POST['ranks_water'] < 0 || $_POST['ranks_water'] > 999 ||
					!isset($_POST['ranks_hidesilent']) || $_POST['ranks_hidesilent'] < 0 || $_POST['ranks_hidesilent'] > 999 ) {
					
					$msg = "Failed to save changes: Rank settings out of bounds.<br>";
					$error = 1;
				}
				
				if ($error == 0) {
					
					$titles = $_POST['rank_title'];
					$values = $_POST['rank_val'];
					$prefixes = $_POST['rank_prefix'];
					$colors = $_POST['rank_color'];
					$promoto = $_POST['rank_promoto'];
					
					if (count($titles) <= 20 &&
						count($titles) == count($values) && count($titles) == count($prefixes) && 
						count($titles) == count($colors) && count($titles) == count($promoto)) {

						$query = "INSERT into RankedVisitors (Server, Title, Rank, Prefix, Color, Promoto) VALUES";	
						$first = 0;
						
						for ($i = 0; $i < count($titles); $i++) {
							if (strlen(trim($titles[$i])) > 0 ) {
							
								// Confirm no rank with same prefix and color exists
								for ($y = 0; $y < $i; $y++) {
									if (strlen(trim($titles[$y])) > 0) {
										if ($colors[$i] == $colors[$y] && $prefixes[$i] == $prefixes[$y]) {
											$error = 1;
											break;
										}
									}
								}
								if ($error == 1) {
									$msg = "Failed to save changes: There were two or more ranks with same colors and prefixes<br>";
									break;
								}
							
								// Check input validy
								if (strlen(trim($titles[$i])) <= 16 && 
									strlen(trim($prefixes[$i])) <= 1 && 
									$colors[$i] >= 0 &&  $colors[$i] <= 15 && 
									$promoto[$i] >= 0 && $promoto[$i] <= 5 &&
									$values[$i] >= 0 && $values[$i] <= 999) {
										
										
									if ($first == 1) {
										$query = $query .",";
									}
								
									$query = $query ." (".$servid.", '".
											mysql_real_escape_string(trim($titles[$i]))."', ".
											mysql_real_escape_string($values[$i]).", '".
											mysql_real_escape_string(trim($prefixes[$i]))."', ".
											mysql_real_escape_string($colors[$i]).", ".
											mysql_real_escape_string($promoto[$i]).")";
											
									$first = 1;
									
								}
								else {
									$error = 1;
									$msg = "Failed to save changes: Data out of bounds<br>";
									break;
								}
							}
						}
						if ($error == 0) {
							$tmp_query = sprintf("delete from RankedVisitors where server = %d",$servid);
							if (mysql_query($tmp_query, $DB)) {
							
								$tmp_query = sprintf("update Servers set MultiColorValue=%d, PromoRank=%d, SpleefRank=%d, MuteRank=%d, WaterRank=%d, HideSilent=%d where id = %d",
											mysql_real_escape_string($_POST['ranks_multic']), 
											mysql_real_escape_string($_POST['ranks_mod']), 
											mysql_real_escape_string($_POST['ranks_spleef']), 
											mysql_real_escape_string($_POST['ranks_mute']), 
											mysql_real_escape_string($_POST['ranks_water']),
											mysql_real_escape_string($_POST['ranks_hidesilent']),
											$servid);
								mysql_query($tmp_query, $DB);		
											
								if (count($titles) == 0 || mysql_query($query, $DB)) {	// 0 ranks is a valid rank setup too
									$resetErr_q = sprintf("delete from RankErrors where server = %d",$servid);
									mysql_query($resetErr_q, $DB);
									tellmirc("upd_ranks " . $servid);	
								}
								else {
									$msg = "Failed to save changes: SQL misformed, contact Dankirk<br>".$query;
								}
							}
							else {
								$msg = "Failed to save changes: Database connection lost";
							}
						}	
					}
				}
			
			}
			else if (isset($_POST['customrules'])) {
				$option = 4;
			}
			else if (isset($_POST['rules_save'])) {
				$option = 4;
				
				if (count($_POST['rule_match']) <= 40 && count($_POST['rule_match']) == count($_POST['rule_reply'])) {
				
					#$enables = $_POST['rule_enabled'];
					$enables = array();
					$matches = $_POST['rule_match'];
					$replies = $_POST['rule_reply'];
					
					for ($i = 0; $i < count($matches); $i++)
						$enables[$i] = (isset($_POST['rule_enabled'][$i]) ? 1 : 0); 

					$query = "INSERT into CustomRules (Server, Enabled, RegMatch, Reply) VALUES";	
					$error = 0;
					$first = 0;
					
					for ($i = 0; $i < count($enables); $i++) {
					
						// Check input validy
						if (strlen($matches[$i]) <= 256 && 
							strlen($replies[$i]) <= 128) {
							
							if (strlen($matches[$i]) > 3 &&
								strlen($replies[$i]) >= 2) {
								
								// Test regex performance, accuracy and validity
								if ($enables[$i] == 1) {
									if (preg_match($matches[$i], '') === false) {
									
										// Failed? Try adding slashes.
										$original = $matches[$i];
										if (substr($matches[$i], 0) != '/') $matches[$i] = '/' . $matches[$i];
										if (substr($matches[$i], -1,2) != "/i") $matches[$i] = $matches[$i] . "/i";
										if (strlen($matches[$i]) > 256 || !testRegex($matches[$i])) {
										
											$matches[$i] = $original;
											$enables[$i] = 0;
										}
									}
									if ($enables[$i] == 0 || !testRegex($matches[$i])) {
										$enables[$i] = 0;
										$msg = "Some regexes are invalid or failed performance and accuracy test and thus have been disabled.<br>";
									}
								}
								
										
								if ($first == 1) {
									$query = $query .",";
								}
							
								$query = $query ." (".$servid.", ".
										mysql_real_escape_string($enables[$i]).", '".
										mysql_real_escape_string($matches[$i])."', '".
										mysql_real_escape_string($replies[$i])."')";
										
								$first = 1;
							}
						}
						else {
							$error = 1;
							$msg = "Failed to save changes: Data out of bounds<br>";
							break;
						}
					}	
					if ($error == 0) {
					
						$tmp_query = sprintf("delete from CustomRules where server = %d",$servid);
						if (mysql_query($tmp_query, $DB)) {
							if ($first == 0 || mysql_query($query,$DB)) {	// 0 custom rules is also acceptable.
								tellmirc("upd_db_rules " . $servid);
							}
							else {
								$msg = "Failed to save changes: SQL misformed, contact Dankirk<br>".$query;
							}
						}
						else {
							$msg = "Failed to save changes: Database connection lost";
						}
					}
				}
				else {
					$msg = "nope " . count($enables) . " " . count($matches) . " " . count($replies);
				}
			}
			else if (isset($_POST['set_save'])) {
			
				$ranks = false;
				$impersonation = false;
				$funfacts = false;
				$jokes = false;
				$pony = false;
				$publicstats = false;
				$muted = false;
				$multilang = false;
				$disableplayers = false;
				if (isset($_POST["ranks"])) $ranks = true;
				if (isset($_POST["impersonation"])) $impersonation = true;
				if (isset($_POST["funfacts"])) $funfacts = true;
				if (isset($_POST["jokes"])) $jokes = true;
				if (isset($_POST["pony"])) $pony = true;
				if (isset($_POST["publicstats"])) $publicstats = true;
				if (isset($_POST["muted"])) $muted = true;
				if (isset($_POST["multilang"])) $multilang = true;
				if (isset($_POST["disableplayers"])) $disableplayers = true;
				
				$botname = mysql_real_escape_string( $_POST["botname"] );
				$botauth = mysql_real_escape_string( $_POST["botauth"] );
				$website = mysql_real_escape_string( $_POST["website"] );
				$servname = mysql_real_escape_string( $_POST["servname"] );
				$howtofly = mysql_real_escape_string( $_POST["howtofly"] );

				
				$query = sprintf("update Servers set ranks=%d, impersonation=%d, funfacts=%d, jokes=%d, pony=%d, botname='%s', botauth='%s', website='%s', dispname='%s', howtofly='%s', publicstats='%d', muted='%d', multilang=%d, disableplayers=%d where id = %d", 
					$ranks, $impersonation, $funfacts, $jokes, $pony, $botname, $botauth, $website, $servname, $howtofly, $publicstats, $muted, $multilang, $disableplayers, $servid);
				
				if (mysql_query($query,$DB)) {
					tellmirc("upd_db " . $servid);
				}
				else {
					$msg = "Failed to save changes. Contact Dankirk.";
				}
			}
					
			displayServer($servid,$DB,$msg,$askpw,$option);
		}
	}

	// ----------------------------------------
	// The Frontpage
	// ----------------------------------------
	
	if (!isset($login) || $login <= 0) {
		?>
		<div style="display: inline-block">
		
		<form accept-charset="utf-8" enctype="multipart/form-data" action="index.php" method="POST">
		
		<table cellpadding=2 bgcolor=lightgrey><tr><td><b>Login</b></td></tr>
		<tr>
		<td>Channel</td><td><input name="user" type="text" value="#example" maxlength=24 size="16"></td></tr><tr>
		<td>Password</td><td><input name="pass" type="password" maxlength=16  size="16"></td></tr><tr>
		<td></td><td align="right"><input type="submit" value="Login"></td></tr>
		</table>
		</form>
		
		</div>
		<div style="display: inline-block">
		<div>
		
		<b><font color=darkblue style="font-size:14px">Daily Averages From Last 2 Months</font></b>
		
		<table border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>Server</b></td><td><b>Visitors</b></td><td><b>Kicks</b></td><td><b>Bans</b></td><td><b>Promotes</b></td><td><b>Demotes</b></td><td><b>Growth %</b></td><td><b>Status</b></td></tr><tr bgcolor="beige">
		<?php 
			
			$query = "select servers.dispname, ROUND(AVG(stats.visitors),0), ROUND(AVG(stats.kicks),0), ROUND(AVG(stats.bans),0), ROUND(AVG(stats.promotes),0), ROUND(AVG(stats.demotes),0), ROUND((((select AVG(stats.visitors) from stats where servers.id = server and date <= (NOW() - INTERVAL 1 DAY) and date >= (NOW() - INTERVAL 15 DAY) ) / AVG(stats.visitors) -1) *100),0), servers.IsOnline from stats inner join servers on servers.id = stats.server and servers.publicstats = 1 and stats.date <= (NOW() - INTERVAL 1 DAY) and stats.date >= (NOW() - INTERVAL 2 MONTH) group by servers.id order by AVG(stats.visitors) DESC";	
			print_tablerows($query,$DB);
			
		?>
		<font style="font-size:10px" color=darkblue>*Growth % is calculated by comparing daily visitor averages of the most recent 2 months to most recent 2 weeks.<br>
		*Server status is updated every 10 minutes.
		</font>
		</div>
		
		<div>
		<b><font color=darkblue style="font-size:14px">Most Active Staff</font></b>

		<table border=0 cellpadding=2 cellspacing=1><tr bgcolor="darkgray"><td><b>Server</b></td><td><b>Moderator</b></td><td><b>Kicks</b></td></tr><tr bgcolor="beige">
		<?php 
			$query = OpWithMostQuery("Kicks"); print_tablerows($query,$DB); 
		?>
		</div>
		</div>
		<?php
	} 
	mysql_close($DB);
?>
	</div>
</div>
<div id="footer">
<table><tr><td>
<p>Made by Dankirk 2012 | <a href="http://forum.fcraft.net/viewtopic.php?f=2&amp;t=22">Info & Suggestion thread</a> | <a href="http://www.mibbit.com/#fCraft@irc.esper.net">#fCraft@EsperNet</a> |</p> 
</td><td>
<form action="https://www.paypal.com/cgi-bin/webscr" method="post"> 
<input type="hidden" name="cmd" value="_s-xclick"> <input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----MIIHPwYJKoZIhvcNAQcEoIIHMDCCBywCAQExggEwMIIBLAIBADCBlDCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJKoZIhvcNAQEBBQAEgYB8yO7GjqWsWnDcnBaGNzDjZwg2udhxWz/eIcoytn7LO1d5UI2cuRFVsg3/zJvvBViY3MuxyZt4QE29aShBwypsaXB6cpOU/6ogFL/W67ftLKodIDkeqCzc560VjvF/YWST+rThMxl6a+N6rIsTQm97l+uWmBB/yZlYXJN5fIQPAzELMAkGBSsOAwIaBQAwgbwGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQI3VyHqmz330eAgZiyeeKfVWhVmfiHg3lFrnHXbpwlbnb7a2TzSb+/DO5+PaI9VXQ4Uip3pQWr7PlGNeJw21D9RMz9Qr1YszypFe4XKXzAjzWG9Bnl6BB1uO/l+3Jvk5o6Ziwz+YCnGBgmW5lTZZCRdmZnH2AR1gfSQ2Ry4/2StEco+1pB33FUw2U966tAOGIsc7J6P/S409zY9M5ZAV7LDfMy0KCCA4cwggODMIIC7KADAgECAgEAMA0GCSqGSIb3DQEBBQUAMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQDFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbTAeFw0wNDAyMTMxMDEzMTVaFw0zNTAyMTMxMDEzMTVaMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQDFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAwUdO3fxEzEtcnI7ZKZL412XvZPugoni7i7D7prCe0AtaHTc97CYgm7NsAtJyxNLixmhLV8pyIEaiHXWAh8fPKW+R017+EmXrr9EaquPmsVvTywAAE1PMNOKqo2kl4Gxiz9zZqIajOm1fZGWcGS0f5JQ2kBqNbvbg2/Za+GJ/qwUCAwEAAaOB7jCB6zAdBgNVHQ4EFgQUlp98u8ZvF71ZP1LXChvsENZklGswgbsGA1UdIwSBszCBsIAUlp98u8ZvF71ZP1LXChvsENZklGuhgZSkgZEwgY4xCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFsIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAgV86VpqAWuXvX6Oro4qJ1tYVIT5DgWpE692Ag422H7yRIr/9j/iKG4Thia/Oflx4TdL+IFJBAyPK9v6zZNZtBgPBynXb048hsP16l2vi0k5Q2JKiPDsEfBhGI+HnxLXEaUWAcVfCsQFvd2A1sxRr67ip5y2wwBelUecP3AjJ+YcxggGaMIIBlgIBATCBlDCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTEyMDUyMzIwMDAwMFowIwYJKoZIhvcNAQkEMRYEFItS8fdnD3Wn/eolKQah5u6cShQoMA0GCSqGSIb3DQEBAQUABIGApDWRdzPI5KhT1MKty5chyqrW3YcIUaTj5sDXbPRvfCLnTSE0HcFV5QntCjdj6yKI9yWa0dgzb2oXhUVZwsqFQxf8Pi38KXE1nl44n8BvYwqYOOHdZ9yl5btvp+WaKf5FK2Am+f0d6dMHlTjVc8YtIHHYyNZKnG4ISRUC1wMJ9EA=-----END PKCS7-----
"> 
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!"> 
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
</td>
<td>

</td>
</tr></table>
</div>
</body>
</html>
