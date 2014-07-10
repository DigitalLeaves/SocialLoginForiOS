SocialLoginForiOS
=================

SocialLoginForiOS is a Social Login platform for iOS with frontend and testing backend (in Slim) to integrate Social 
Login OAuth authentication in your own RESTful API. I decided to implement this class because I couldn't find a good
resource for learning about the implementation of a real authentication scheme using social login via OAuth.

There is a [extensive blog post](http://digitalleaves.com/blog/2014/07/building-your-own-rest-api-with-oauth-2-0-iii-hands-on/) 
explaining the implementation of the platform.

# Integration

The integration is divided in two parts: foreground and backend.

## Foreground

The foreground is an iPhone App. The project includes a full example of use, with social login buttons and a fake 
registration process with the REST API backend server, but if you want to integrate it into your own project, you 
just need to copy the class "OAuthRESTManager" into your project. Then, you would call `getTwitterAccountsWithListener:` 
for Twitter accounts and `getFacebookAccountsWithListener:` for Facebook accounts. 

```
[[OAUthRESTManager sharedInstance] getTwitterAccountsWithListener];
```

Your class will need to implement the "SocialAccountsDelegate" protocol, with the following methods:
```
/** The user refused access to the service accounts */
- (void) accessRefusedByUserToService: (NSString *) serviceType;

/** Access was granted for an array of ACAccounts like twitter/facebook */
- (void) accessGrantedForAccounts:(NSArray *) accounts inService:(NSString *) serviceType;

/** There are no accounts configured for the specified service */
- (void) noAccountsForService: (NSString *) serviceType;

```

accessRefusedByUserToService: will be called when the user denies access to the social accounts, accessGrantedForAccounts:inService: 
will return a NSArray of accounts (if at least one is configured) and noAccountsForService: will be called when there are 
no accounts for that social network configured in the device.

It is important that you set your Facebook and Twitter App IDs and Secret at the top of OAuthRESTManager.m:

```
#define kOAuthAuthenticationRESTFacebookAppID     @"ENTER_YOUR_FACEBOOK_APP_ID_HERE"
#define kOAuthAuthenticationTwitterAPIKey         @"ENTER_YOUR_TWITTER_APP_ID_HERE"
#define kOAuthAuthenticationTwitterAPISecret      @"ENTER_YOUR_TWITTER_APP_SECRET_HERE"
```

Once you get at least one account, you can call OAuthRESTManager's `registerUserBySocialAccount:listener:`. The listener 
will need to adhere to the RegistrationListener protocol, with the following methods:

```
/** Registration was successful. */
- (void) registrationSucceedWithAccountType: (NSString *) accountType passkey: (NSString *) passkey passcode: (NSString *) passcode andMessage: (NSString *) message;

/** Registration failed with reason message */
- (void) registrationFailedReason: (NSString *) message;

@optional

/** This method is just for testing purposes, to show the results of the OAUth reverse authentication flow steps */
- (void) notifyOfAuthenticationProcess: (NSString *) message;
```

notifyOfAuthenticationProcess: is optional, just in case you want to be notified throughtout the process. The registration tries to connect to a /register REST endpoint in a URL configured by the constant kOAuthAuthenticationRESTBaseURL. The testing backend is included and implemented to respond properly to this request.

## Backend

In order to be able to test this properly, I have included a simple testing backend without any kind of DDBB access. It will just use the OAuth tokens to verify the user’s identity and retrieve information from the user that would be stored in the user’s credentials. For the backend platform, I selected [Slim](http://www.slimframework.com) because I think it is a pretty cool, simple and elegant framework for developing backends, and because it’s written in PHP, and I loathe Ruby (sorry Ruby guys… ;).

In order to setup the backend environment, you would need a MAMP environment (unless you have another testing machine with Linux, Windows or whatever). I recommend [bitnami’s MAMPStack](https://bitnami.com/stack/mamp), because [MAMP](http://www.mamp.info/en/) is missing some important features for a serious backend development process (i.e: it lacks Mysqli support for prepared SQL statements). Once you have it downloaded, installed and configured, you must set the directory for the base URL of the backend. In the iOS project, this is set to “http://localhost:8080/testSocialLogin/v1″ in the kOAuthAuthenticationRESTBaseURL constant, so you can just make a “testSocialLogin” directory and put the contents of the “backend” directory. Don’t forget to set the port to 8080 or change the port in kOAuthAuthenticationRESTBaseURL. The v1 (version 1) contains a .htaccess file that will redirect all requests to the backend (i.e: /register, /login, /users…) to index.php. It is always a good practice to version your backend for deploying in a production scenario.

The only thing you need to remember is to change your Twitter App Consumer Key and Secret in the Config.php file found in the “include” directory.

This backend is just a proof of concept. It will not connect to any database or perform any operations, apart from verifying the identity of the user (using the designated OAuth endpoints from Twitter and Facebook) and then return the retrieved information from the user. In a production/real backend, you would use that data to create a user’s record, store it in the database, and return a “registration succeed” response to your frontend application, so it knows that it can start login and performing CRUD operations in the REST server.

The backend uses a OAuthHelper class to retrieve the user’s information from the user. The Facebook method uses a plain simple curl request:

```
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
```
The Twitter method uses the lightweight twitteroauth library. Notice that, as the twitter oauth token and secret are encoded and sent to the backend in the passcode parameter as “oauth_token:oauth_token_secret”, we must separate these values before calling the library (this is done in index.php):

```
...
// separate $access_token and $access_token_secret from $access_token_combined
$token_parts = explode(":", $access_token_combined);
if (count($token_parts) != 2) return USER_CREATION_FAILED;
$access_token = $token_parts[0];
$access_token_secret = $token_parts[1];

// Connect to Twitter via OAuth and request the information of the user with the access token.
$twitterData = $this->requestUserDataFromTwitter(TWITTER_USER_INFORMATION_URL, $access_token, $access_token_secret);

...

public function requestUserDataFromTwitter($url, $access_token, $access_token_secret) {
	$connection = new TwitterOAuth(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, $access_token, $access_token_secret);
	$account = $connection->get('account/verify_credentials');
	return $account;
}
```

The backend will respond to the /register request with three possible codes: USER_CREATED_SUCCESSFULLY, USER_CREATION_FAILED, and USER_ALREADY_EXISTED. The last one would never happen because we are not actually storing the user anywhere. Instead of returning a USER_CREATED_SUCCESSFULLY code, for testing purposes, the backend returns a string with the user’s info returned from the social network’s OAuth communication, so the frontend can show it in the ViewController’s UITextView.

# Use

The App is very simple to use once everything is set up. You just need to set the backend and make sure you can communicate with it. You can test it easily by opening a terminal on OS X and typing “curl -k -X POST https://localhost:8080/testSocialLogin/v1/register”, and hitting Enter. It should return a JSON informing of an error in registration due to missing parameters.

```
{"error":true,"message":"Required field(s) access_type, passkey, passcode missing or empty"}
```

Don’t forget to set the Consumer Key and Secret in Config.php. If the backend is ready, you just have to set the same Consumer Key and Secret, along with the Facebook App ID at the top of OAuthRESTManager.m, and you are ready to run. The interface will look similar to this:

![SocialLoginForiOS](http://digitalleaves.com/blog/wp-content/uploads/2014/07/SocialLoginForiOS.jpg)


# License

This software is licensed under the MIT license. You can use it in your personal or commercial projects without 
permission, but if you find it useful, I would love to hear from you.

Copyright (c) 2014 Ignacio Nieto Carvajal
http://digitalleaves.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
