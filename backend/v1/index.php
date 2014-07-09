<?php
/**
 * Index for a simple RESTful API for testing Social Login Authentication, in Slim.
 * @author Ignacio Nieto
 */
require_once '../include/Config.php';
require_once '../include/PassHash.php';
require_once '../include/OAuthHelper.php';
require '.././libs/Slim/Slim.php';

\Slim\Slim::registerAutoloader();

$app = new \Slim\Slim();


/**
 * User Registration
 * url - /register
 * method - POST
 * params - access_type
 *       1: name, email, password
 *       2: service_id, access_token
 *       3: service_id, access_token 
 */
$app->post('/register', function() use ($app) {
		$oauthHelper = new OAuthHelper();

		// check for required access_type
		verifyRequiredParams(array('access_type', 'passkey', 'passcode'));
		$access_type = $app->request->post('access_type');
	    $passkey = $app->request->post('passkey');
	    $passcode = $app->request->post('passcode');

		// verify parameters based on access_type
		if ($access_type == AUTHENTICATION_METHOD_PASSWORD) { // email/password
			$res = $oauthHelper->createUserByUsernameAndPassword($passkey, $passcode);
		} else if ($access_type == AUTHENTICATION_METHOD_FACEBOOK) { // facebook
			$res = $oauthHelper->createUserByFacebook($passkey, $passcode);
		} else if ($access_type == AUTHENTICATION_METHOD_TWITTER) { // twitter
			$res = $oauthHelper->createUserByTwitter($passkey, $passcode);
		} else {
	        $response = array();
	        $app = \Slim\Slim::getInstance();
	        $response["error"] = true;
	        $response["message"] = 'Required field access_type is missing or empty';
	        echoResponse(400, $response);
	        $app->stop();
		}

	    $response = array();
	    /* IN A NON-TESTING ENVIRONMENT, YOU SHOULD CHECK FOR USER_CREATED_SUCCESSFULLY
	       AND RETURN A NON-ERROR MESSAGE (201).
	    if ($res == USER_CREATED_SUCCESSFULLY) {
	        $response["error"] = false;
	        $response["message"] = "You are successfully registered";
	    } else ...*/
	     if ($res == USER_CREATION_FAILED) {
	        $response["error"] = true;
	        $response["message"] = "I was unable to complete the registration";
	    } else if ($res == USER_ALREADY_EXISTED) {
	        $response["error"] = true;
	        $response["message"] = "Sorry, this account already exists";
	    } else { // FOR TESTING PURPOSES, WE RETURN THE RETRIEVED DATA FROM SOCIAL NETS.
	    	$response["error"] = false;
	    	$response["message"] = $res;
	    }
	    // echo json response
	    echoResponse(201, $response);
	}
);

/**
 * Verifying required params posted or not
 */
function verifyRequiredParams($required_fields) {
    $error = false;
    $error_fields = "";
    $request_params = array();
    $request_params = $_REQUEST;
    // Handling PUT request params
    if ($_SERVER['REQUEST_METHOD'] == 'PUT') {
        $app = \Slim\Slim::getInstance();
        parse_str($app->request()->getBody(), $request_params);
    }
    foreach ($required_fields as $field) {
        if (!isset($request_params[$field]) || strlen(trim($request_params[$field])) <= 0) {
            $error = true;
            $error_fields .= $field . ', ';
        }
    }

    if ($error) {
        // Required field(s) are missing or empty
        // echo error json and stop the app
        $response = array();
        $app = \Slim\Slim::getInstance();
        $response["error"] = true;
        $response["message"] = 'Required field(s) ' . substr($error_fields, 0, -2) . ' missing or empty';
        echoResponse(400, $response);
        $app->stop();
    }
}

/**
 * Echoing json response to client
 * @param String $status_code Http response code
 * @param Int $response Json response
 */
function echoResponse($status_code, $response) {
    $app = \Slim\Slim::getInstance();
    // Http response code
    $app->status($status_code);

    // setting response content type to json
    $app->contentType('application/json');

    echo json_encode($response);
}

$app->run();
?>