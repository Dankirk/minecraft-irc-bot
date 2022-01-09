<?php
require_once("mirc.php");
require_once("mysql.php");

// Returns array of ($serverID, $check_password_exists) if logged in sucecsfully
// Otherwise array of (0,0)
function GetLoginInfo($DB) {

	// Authenticate using preset cookies
	if (isset($_COOKIE["login"])) {

		$query = sprintf("select Server, Created, master from Logins where hash = '%s'",
							mysql_real_escape_string( $_COOKIE["login"] ));
							
		
		$res = mysql_query($query, $DB);
		if ($res) {
			if ($row = mysql_fetch_assoc($res)) {	
				$servid = $row['Server'];
				$created = strtotime($row['Created']);	
				$ignorePwCheck = $row['master'];
				
				if ($created + 3600 >= time()) {	
				
					mysql_free_result($res);
				
					// Refresh cookie when nearing expiration
					if ($created + 2700 < time() && !isset($_POST["logout"])) {
						SetNewLogin($servid,$DB,$ignorePwCheck,mysql_real_escape_string( $_COOKIE["login"] ));
					}
				
					return array($servid,!$ignorePwCheck);
				}
	
			}
			mysql_free_result($res);
		}
		Logout($servid,$DB);
	}
	
	// Authenticate with given username and password
	if (isset($_POST['user']) && isset($_POST['pass'])) {

		$servid = LoginUserPass($DB, $_POST['user'], $_POST['pass']);
		if ($servid > 0) {
			return array($servid,0);
		}
	}
	
	// Try to authenticate with a token
	if (isset($_GET['token'])) {
	
		if (strlen($_GET['token']) == 32) { 

			$query = sprintf("select id from Servers where token = '%s'", mysql_real_escape_string( $_GET['token'] )); 
			
			$serverID = getSingleValue($query, $DB);
			if (!empty($serverID)) {			
				if (SetNewLogin($serverID,$DB)) {
					return array($serverID,1);
				}
			}	
		}
	}
	
	return array(0,0);
}

// Returns a string of random characters
function getRandomString($length = 32) {

    $validCharacters = "abcdefghijklmnopqrstuxyvwzABCDEFGHIJKLMNOPQRSTUXYVWZ0123456789";
    $validCharNumber = strlen($validCharacters);

    $result = "";

    for ($i = 0; $i < $length; $i++) {

        $index = mt_rand(0, $validCharNumber - 1);
        $result .= $validCharacters[$index];
    }

    return $result;

}

// Saves login cookies to database
// Returns TRUE if succesful, otherwise FALSE
function SetNewLogin($servid, $DB, $master = 0, $oldhash = -1) {
	$hash = getRandomString();
			
	$query = sprintf("INSERT into Logins (hash,server,master) VALUES ('%s',%d,%d)",$hash,$servid,$master);
	if (mysql_query($query,$DB)) {
		setcookie("login", $hash, time()+3600);
		if ($oldhash != -1) {
			$query = sprintf("DELETE from Logins where hash = '%s' AND server = %d",$oldhash,$servid);
			mysql_query($query,$DB);
		}
	}
	else {
		return FALSE;
	}	
	return TRUE;
}

function Logout($servid, $DB) {

	if (isset($_COOKIE["login"]) && $servid > 0) {
		$query = sprintf("delete from Logins where hash = '%s' and Server = %d",
			mysql_real_escape_string( $_COOKIE["login"] ), $servid);
		mysql_query($query, $DB);
	}
	setcookie("login", "", time() - 3600);
}

// Login using a username and password
// Returns ID of the server logged to or 0 if unsuccesful
function LoginUserPass($DB,$user,$pass) {

	$serverID = 0;
	if (!empty($user) && !empty($pass)) {

		$pass_md5 = md5( $pass );
		
		// Authenticate using server's password
		$query = sprintf("select id from Servers where name = '%s' AND pass = '%s'",
							mysql_real_escape_string( $user ),
							$pass_md5);
			
		
		$serverID = getSingleValue($query, $DB);
		if (!empty($serverID)) {		
			if (SetNewLogin($serverID,$DB)) {
				tellmirc("log " . $serverID . " " . $_SERVER['REMOTE_ADDR']);
			}	
			else
				$serverID = 0;
		}
		
		else {
		
			// Authenticate with master password
			$query = sprintf("select id from Servers where name = '%s' AND masterpass= '%s'",
								mysql_real_escape_string( $user ),
								$pass_md5);
				
			
			$serverID = getSingleValue($query, $DB);
			if (!empty($serverID)) {		
				if (SetNewLogin($serverID,$DB,1)) {
					tellmirc("masterlog " . $serverID . " " . $_SERVER['REMOTE_ADDR']);
				}
				else
					$serverID = 0;
			}
		}
	}
	
	return $serverID;
}
?>