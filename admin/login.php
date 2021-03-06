<?php

/**
 * login.php -- part of Server side of Extended QGIS Web Client
 *
 * Copyright (2014-2015), Level2 team All rights reserved.
 * More information at https://github.com/uprel/gisapp
 */

use GisApp\Login;

require_once("class.Login.php");

$server_os = php_uname('s');

session_start();

$login = new Login();

$pp='';
if (isset($_SESSION['project'])) {
	$pp = $_SESSION['project'];
}

//check action parameter
$action = filter_input(INPUT_GET,"action",FILTER_SANITIZE_STRING);
if ($action != null) {
	if($action == "logout") {
		//logout
		$login->doLogout();
		if($server_os=='Windows NT') {
			header("Location: ../index.php?map=".PROJECT_PATH.$pp.'.qgs');
		}
		else {
			header("Location: ../".$pp);
		}
	}
}
else {
	//login   				
	$loginUsername = filter_input(INPUT_POST,"user_name",FILTER_SANITIZE_STRING);
    $loginPass = filter_input(INPUT_POST,"user_password",FILTER_SANITIZE_STRING);
	
	$login->doLoginWithPostData();
	 
	$result["success"] = $login->getUserLoginStatus();
	$result["message"] = $login->feedback;

	echo json_encode($result);
}
