<?php

/**
 * Configuration file for testing Social Login Authentication.
 * @author Ignacio Nieto
 */

define('USER_CREATED_SUCCESSFULLY', 0);
define('USER_CREATION_FAILED', 1);
define('USER_ALREADY_EXISTED', 2);
define('INCORRECT_USER_OR_PASSWORD', 3);

define('AUTHENTICATION_METHOD_PASSWORD', 'password');
define('AUTHENTICATION_METHOD_FACEBOOK', 'facebook');
define('AUTHENTICATION_METHOD_TWITTER', 'twitter');

define('FACEBOOK_USER_INFORMATION_URL', 'https://graph.facebook.com/me?fields=email,picture.type(large),name,id');
define('TWITTER_VERIFY_CREDENTIALS_URL', 'https://api.twitter.com/1.1/account/verify_credentials.json');
define('TWITTER_USER_INFORMATION_URL', 'https://api.twitter.com/1/account/verify_credentials.json');
define('TWITTER_CONSUMER_KEY', 'INSERT_YOUR_TWITTER_CONSUMER_KEY_HERE');
define('TWITTER_CONSUMER_SECRET', 'INSERT_YOUR_TWITTER_CONSUMER_SECRET_HERE');

?>
