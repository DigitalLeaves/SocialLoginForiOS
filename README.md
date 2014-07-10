SocialLoginForiOS
=================

SocialLoginForiOS is a Social Login platform for iOS with frontend and testing backend (in Slim) to integrate Social 
Login OAuth authentication in your own RESTful API. I decided to implement this class because I couldn't find a good
resource for learning about the implementation of a real authentication scheme using social login via OAuth.

There is a [extensive blog post](http://digitalleaves.com/blog/2014/07/building-your-own-rest-api-with-oauth-2-0-iii-hands-on/) 
explaining the implementation of the platform.

# Integration

The integration is divided in two parts: foreground and background.

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

# Use

