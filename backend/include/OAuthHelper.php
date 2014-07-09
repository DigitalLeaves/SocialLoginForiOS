<?php

require_once '../libs/twitteroauth/twitteroauth.php';
require_once '../libs/twitteroauth/OAuth.php';
require_once '../include/Config.php';

/**
 * This class retrieves info from OAuth social network services and help registering 
 * the user.
 *
 * @author Ignacio Nieto
 */
class OAuthHelper {

    function __construct() {
		// init the instance of this class...
    }

    /**
     * Creating new user via Email
     * @param String $name User full name
     * @param String $password User login password
     */
    public function createUserByUsernameAndPassword($name, $password) {
        require_once 'PassHash.php';
        $response = array();


        // First check if user already existed in db
        if (!$this->userExistsByEmail($email)) {
            // Generating password hash
            $password_hash = PassHash::hash($password);

			// here you would generate other user's properties, like alias
			// default avatar, api_key for authentication, and insert it in the DB.
			$usercreationsucceed = true;

            // Check for successful insertion
            if ($usercreationsucceed) {
                // User successfully inserted
                // here you should return USER_CREATED_SUCCESSFULLY;
                return "user created with name: ".$name.", password: ".$password;
            } else {
                // Failed to create user
                return USER_CREATION_FAILED;
            }
        } else {
            // User with same email already existed in the db
            return USER_ALREADY_EXISTED;
        }

        return $response;
    }
    
    /**
     * Creating new user via Facebook
	 * @param String $service_id the id of the user in Facebook.
	 * @param String $access_token the access token to retrieve information from Facebook
     */
    public function createUserByFacebook($service_id, $access_token) {
        // First check if user already existed in db
        if (!$this->userExistsByService(AUTHENTICATION_METHOD_FACEBOOK, $service_id)) {
			// Connect to Facebook via OAuth and request the information of the user with the access token.
			$facebookData = $this->requestUserDataFromFacebook(FACEBOOK_USER_INFORMATION_URL, $access_token);
			if (is_null($facebookData)) return USER_CREATION_FAILED;
			
			// extract data from facebook.
			if (isset($facebookData->id)) $fbID = $facebookData->id;
			else return USER_CREATION_FAILED;
			
			// THIS IS THE IMPORTANT STEP: we must check the retrieved user id
			// and make sure it matches the one that the user sent us.
			if ($service_id != $fbID) return USER_CREATION_FAILED;

			// retrieve other data from facebook
			if (isset($facebookData->email)) $email = $facebookData->email;
			else return USER_CREATION_FAILED;
			if (isset($facebookData->name)) $name = $facebookData->name;
			else $name = "unknown";
			$avatar = "unknown";
			if (isset($facebookData->picture)) {
				$fbAvatarURL = $facebookData->picture->data->url;
				if (isset($fbAvatarURL)) $avatar = $fbAvatarURL;
			} 
			
			// generate an api_key and store the new user in the DB with the
			// additional properties email, avatar (URL), name and such.
			$usercreationsucceed = true;

            // Check for successful insertion
            if ($usercreationsucceed) {
                // User successfully inserted
                // here you should return USER_CREATED_SUCCESSFULLY;
                return "Retrieved facebook data. name: ".$name.", id: ".$fbID.", email: ".$email.", avatar: ".$avatar;
            } else {
                // Failed to create user
                return USER_CREATION_FAILED;
            }
        } else {
            // User with same email already existed in the db
            return USER_ALREADY_EXISTED;
        }
	}

    /**
     * Creating new user via Twitter
	 * @param String $service_id the id of the user in Twitter.
	 * @param String $access_token the access token to retrieve information from Twitter
     */
    public function createUserByTwitter($service_id, $access_token_combined) {
        // First check if user already existed in db
        if (!$this->userExistsByService(AUTHENTICATION_METHOD_TWITTER, $service_id)) {
			// separate $access_token and $access_token_secret from $access_token_combined
			$token_parts = explode(":", $access_token_combined);
			if (count($token_parts) != 2) return USER_CREATION_FAILED;
			$access_token = $token_parts[0];
			$access_token_secret = $token_parts[1];
			if (is_null($access_token)) $access_token = "";
			if (is_null($access_token_secret)) $access_token_secret = "";
			
			// Connect to Twitter via OAuth and request the information of the user with the access token.
			$twitterData = $this->requestUserDataFromTwitter(TWITTER_USER_INFORMATION_URL, $access_token, $access_token_secret);
			if (is_null($twitterData)) return USER_CREATION_FAILED;
			// extract data from facebook.
			if (isset($twitterData->id_str)) $twitterID = $twitterData->id_str;
			else return USER_CREATION_FAILED;
			
			// THIS IS THE IMPORTANT STEP: we must check the retrieved user id
			// and make sure it matches the one that the user sent us.
			if ($service_id != $twitterID) return USER_CREATION_FAILED;
			
			// retrieve other data from twitter
			$avatar = "unknown";
			$name = $twitterData->name;
			if (is_null($name)) return USER_CREATION_FAILED;
			$twitterAvatarURL = $twitterData->profile_image_url;
			// change a "normal" (small) image for a big one, by replacing "normal" for "400x400" in the image URL
			if (strpos($twitterAvatarURL, "normal") != false) { $twitterAvatarURL = str_replace("normal", "400x400", $twitterAvatarURL); }
			if (isset($twitterAvatarURL)) $avatar = $twitterAvatarURL;

			// generate an api_key and store the new user in the DB with the
			// additional properties email, avatar (URL), name and such.
			$usercreationsucceed = true;

            // Check for successful insertion
            if ($usercreationsucceed) {
                // User successfully inserted
                // here you should return USER_CREATED_SUCCESSFULLY;
                return "Retrieved twitter data. name: ".$name.", id: ".$twitterID.", avatar: ".$avatar;
            } else {
                // Failed to create user
                return USER_CREATION_FAILED;
            }
        } else {
            // User with same email already existed in the db
            return USER_ALREADY_EXISTED;
        }
	}


    /**
     * Checking for previously existing user by email address
     * @param String $email email to check in db
     * @return boolean
     */
    private function userExistsByUsername($username) {
		// here you would check if the user exists in the database
		return false;
    }

    /**
     * Checking for duplicate user by Service ID
     * @param String $email email to check in db
     * @return boolean
     */
    private function userExistsByService($access_type, $service_id) {
		// here you would check if the user exists by access_type and user_id
		return false;
    }

/************************* OAUTH COMMUNICATION FUNCTIONS **********************/

	/** Retrieves the user data from Facebook. Returns a JSON decoded object */
	public function requestUserDataFromFacebook($url, $access_token) {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL,$url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER,true);
		curl_setopt($ch, CURLOPT_FAILONERROR, true);
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 30);
		$headers = array("Authorization: Bearer " . $access_token);
		curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
		// execute the CURL request.
		$data = curl_exec($ch);
		
		if(!curl_errno($ch)){ 
			return json_decode($data);
		} else {
		  return NULL; 
		}
		curl_close($ch);
	}
	
	public function requestUserDataFromTwitter($url, $access_token, $access_token_secret) {
		$connection = new TwitterOAuth(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, $access_token, $access_token_secret);
		$account = $connection->get('account/verify_credentials');
		return $account;
	}
}
?>
