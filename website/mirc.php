<?php
require_once("settings.php");

function tellmirc($input)
{
	$onnistuiko = false;

	set_time_limit(5);

	if ($socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)) {

		if (socket_connect($socket,$settings['mIRC']['host'],$settings['mIRC']['port']) {

			if (socket_write($socket, $input . "\r\n")) {
					
				socket_close($socket);
				$onnistuiko = true;
			}
		}
	}	
	if (!$onnistuiko) {
		echo "Couldn't communicate with the bot. Changes will be loaded when bot comes online.<br><br>";
		socket_close($socket);
	}
	
	return $onnistuiko;
	
}
?>