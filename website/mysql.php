<?php
require_once("settings.php");

// Connects to database
function MA_ConDB() {
	$DB = mysql_connect($settings['DB']['host'], $settings['DB']['user'], $settings['DB']['pass']);
	if (!$DB)
		die ('Could not connect to Minecraft DB');

	if (!mysql_select_db($settings['DB']['db'], $DB))
		die ('Could not connect to Minecraft DB');
		
	return $DB;	
}

// Gets a single value specified query should return. Otherwise returns an empty string.
function getSingleValue($query,$DB) {
	$ret = '';
	$res = mysql_query($query, $DB);
	if ($res) {
		if ($row = mysql_fetch_row($res)) {	
			$ret = $row[0];	
		}
		mysql_free_result($res);
	}
	return $ret;
}
?>