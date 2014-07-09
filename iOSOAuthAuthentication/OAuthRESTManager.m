//
//  OAuthRESTManager.m
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

#import "OAuthRESTManager.h"
#import <CommonCrypto/CommonHMAC.h>

#define kOAuthAuthenticationRESTFacebookAppID                         @"ENTER_YOUR_FACEBOOK_APP_ID_HERE"
#define kOAuthAuthenticationTwitterAPIKey                             @"ENTER_YOUR_TWITTER_APP_ID_HERE"
#define kOAuthAuthenticationTwitterAPISecret                          @"ENTER_YOUR_TWITTER_APP_SECRET_HERE"

#define kOAuthAuthenticationRESTBaseURL                               @"http://localhost:8080/testSocialLogin/v1"
#define kOAuthAuthenticationRESTRegisterURL                           @"/register"

#define kOAuthAuthenticationAccessTypeEmailPassword                   @"password"
#define kOAuthAuthenticationAccessTypeFacebook                        @"facebook"
#define kOAuthAuthenticationAccessTypeTwitter                         @"twitter"

#define kOAuthAuthenticationUserParameterAccessToken                  @"access_token"
#define kOAuthAuthenticationUserParameterAccessType                   @"access_type"
#define kOAuthAuthenticationUserParameterError                        @"error"
#define kOAuthAuthenticationUserParameterMessage                      @"message"
#define kOAuthAuthenticationUserParameterPasskey                      @"passkey"
#define kOAuthAuthenticationUserParameterPasscode                     @"passcode"

#define kOAuthAuthenticationReverseOAuthRequestTokenTwitterURL        @"https://api.twitter.com/oauth/request_token"
#define kOAuthAuthenticationReverseOAuthAccessTokenTwitterURL         @"https://api.twitter.com/oauth/access_token"
#define kOAuthAuthenticationReverseOAuthTwitterHTTPMethod             @"POST"
#define kOAuthAuthenticationReverseOAuthAuthorizationHeaderPrefix     @"Authorization"
#define kOAuthAuthenticationReverseOAuthAuthorizationHeaderValue      @"OAuth"
#define kOAuthAuthenticationReverseOAuthTwitterConsumerKeyParam       @"oauth_consumer_key"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthNonceParam        @"oauth_nonce"
#define kOAuthAuthenticationReverseOAuthTwitterSignatureMethodParam   @"oauth_signature_method"
#define kOAuthAuthenticationReverseOAuthTwitterSignatureMethodValue   @"HMAC-SHA1"
#define kOAuthAuthenticationReverseOAuthTwitterSignatureParam         @"oauth_signature"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthTimestampParam    @"oauth_timestamp"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthVersionParam      @"oauth_version"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthVersionValue      @"1.0"
#define kOAuthAuthenticationReverseOAuthTwitterXAuthModeParam         @"x_auth_mode"
#define kOAuthAuthenticationReverseOAuthTwitterXAuthModeValue         @"reverse_auth"
#define kOAuthAuthenticationReverseOAuthTwitterXReverseAuthParam      @"x_reverse_auth_target"
#define kOAuthAuthenticationReverseOAuthTwitterXReverseParamsParam    @"x_reverse_auth_parameters"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthTokenParam        @"oauth_token"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthTokenSecretParam  @"oauth_token_secret"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthUserIdParam       @"user_id"
#define kOAuthAuthenticationReverseOAuthTwitterOAuthScreenNameParam   @"screen_name"

@interface OAuthRESTManager ()

/** The account store representing the user's social account */
@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation OAuthRESTManager

@synthesize accountStore = _accountStore;

/** Singleton shared instance*/
+ (OAuthRESTManager *) sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static OAuthRESTManager * _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

/** Designated initializer. Should not be called. New instances should be invoked through sharedInstance */
- (id) init {
    self = [super init];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

#pragma mark twitter access

/** @brief retrieves the array containing the twitter accounts configured in the device.
 */
- (void) getTwitterAccountsWithListener: (id <SocialAccountsDelegate>) listener {
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterType];
                
                // check if there are any accounts in the system.
                if (!twitterAccounts || twitterAccounts.count < 1) { // no twitter accounts in the system.
                    [listener noAccountsForService:ACAccountTypeIdentifierTwitter];
                } else { // at least one account. Get them.
                    NSMutableArray * result = [NSMutableArray arrayWithCapacity:twitterAccounts.count];
                    for (ACAccount * account in twitterAccounts) {
                        [result addObject:account];
                    }
                    [listener accessGrantedForAccounts:result inService:ACAccountTypeIdentifierTwitter];
                }
                
            } else {
                [listener accessRefusedByUserToService:ACAccountTypeIdentifierTwitter];
            }
        });
    }];
}

#pragma mark Facebook

/** @brief rretrieves the array with the facebook accounts configured in the device.
 */
- (void) getFacebookAccountsWithListener: (id <SocialAccountsDelegate>) listener  {
    ACAccountType *facebookType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    // request access to Facebook accounts:
    NSDictionary *options = @{ ACFacebookAppIdKey: kOAuthAuthenticationRESTFacebookAppID,
                               ACFacebookPermissionsKey: @[@"email", @"read_stream", @"basic_info"],
                               ACFacebookAudienceKey: ACFacebookAudienceEveryone };
    
    [self.accountStore requestAccessToAccountsWithType:facebookType options:options completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSArray *facebookAccounts = [self.accountStore accountsWithAccountType:facebookType];
                
                // check if there are any accounts in the system.
                if (!facebookAccounts || facebookAccounts.count < 1) { // no facebook accounts in the system.
                    [listener noAccountsForService:ACAccountTypeIdentifierFacebook];
                } else { // at least one account. Get them.
                    NSMutableArray * result = [NSMutableArray arrayWithCapacity:facebookAccounts.count];
                    for (ACAccount * account in facebookAccounts) {
                        [result addObject:account];
                    }
                    [listener accessGrantedForAccounts:result inService:ACAccountTypeIdentifierFacebook];
                }
                
            } else {
                NSLog(@"Error authenticating with Facebook: %@", error.localizedDescription);
                [listener accessRefusedByUserToService:ACAccountTypeIdentifierFacebook];
            }
        });
    }];
}

- (void) searchForFacebookAccountWithId: (NSString *) serviceId andExecuteBlock: ( void (^) (BOOL success, ACAccount * account) ) searchResultsBlock {
    ACAccountType *facebookType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    // request access to Facebook accounts:
    NSDictionary *options = @{ ACFacebookAppIdKey: kOAuthAuthenticationRESTFacebookAppID,
                               ACFacebookPermissionsKey: @[@"email", @"read_stream", @"basic_info"],
                               ACFacebookAudienceKey: ACFacebookAudienceEveryone };
    
    [self.accountStore requestAccessToAccountsWithType:facebookType options:options completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSArray *facebookAccounts = [self.accountStore accountsWithAccountType:facebookType];
                
                // check if there are any accounts in the system.
                if (!facebookAccounts || facebookAccounts.count < 1) { // no facebook accounts in the system.
                    searchResultsBlock(NO, nil);
                } else { // at least one account. Get them.
                    for (ACAccount * account in facebookAccounts) {
                        if ([[account valueForKeyPath:@"properties.uid"] isEqual:serviceId]) { // found
                            searchResultsBlock(YES, account);
                            return;
                        }
                    }
                    // not found
                    searchResultsBlock(NO, nil);
                }
                
            } else {
                NSLog(@"Error authenticating with Facebook: %@", error.localizedDescription);
                searchResultsBlock(NO, nil);
            }
        });
    }];
}

#pragma mark reverse OAUth authentication

/** @brief First stage of Twitter OAuth reverse authentication
 * Performs the first request for the OAuth reverse authentication flow of Twitter, by sending signature-embedded OAuth request. If successful, will call the second
 * stage method retrieveTwitterOAuthTokenFromRequestTokenResponse:forTwitterId:withBlock:, that will do the final request and obtain the OAuth token and OAuth token
 * secrets, and return a response in a GCD block called tokenBlock.
 * @param twitterId the twitter ID to use for the reverse authentication flow. Must be obtained previously from the user's Twitter ACAccounts.
 * @param tokenBlock A GCD block that will receive the response of the reverse authentication. If successful, success will be set to YES and credentials will include the credentials for the reverse auth. Otherwise, success will be set to NO and credentials to nil.
 */
- (void) getTwitterOAuthTokenForAccountWithId: (NSString *) twitterId andBlock: ( void (^) (BOOL success, TwitterReverseOAuthCredentials * credentials) ) tokenBlock {
    // build the request, baseURL and parameters
    NSString * baseURL = kOAuthAuthenticationReverseOAuthRequestTokenTwitterURL;
    NSString * method = kOAuthAuthenticationReverseOAuthTwitterHTTPMethod;
    AFHTTPRequestOperationManager * manager = [[AFHTTPRequestOperationManager alloc] init];
    
    // set params for twitter reverse authentication request
    NSUInteger nowAsTimeInterval = (NSUInteger) [[NSDate date] timeIntervalSince1970];
    NSDictionary * params =  @{kOAuthAuthenticationReverseOAuthTwitterConsumerKeyParam: kOAuthAuthenticationTwitterAPIKey,
                               kOAuthAuthenticationReverseOAuthTwitterOAuthNonceParam: [[NSUUID UUID] UUIDString],
                               kOAuthAuthenticationReverseOAuthTwitterSignatureMethodParam: kOAuthAuthenticationReverseOAuthTwitterSignatureMethodValue,
                               kOAuthAuthenticationReverseOAuthTwitterOAuthTimestampParam: [NSString stringWithFormat:@"%lu", (unsigned long)nowAsTimeInterval],
                               kOAuthAuthenticationReverseOAuthTwitterOAuthVersionParam: kOAuthAuthenticationReverseOAuthTwitterOAuthVersionValue,
                               kOAuthAuthenticationReverseOAuthTwitterXAuthModeParam: kOAuthAuthenticationReverseOAuthTwitterXAuthModeValue};
    
    // calculate signature of params
    NSString * paramsToSign = [self paramsStringForReverseTwitterOauthRequest:params];
    NSString * stringToSign = [NSString stringWithFormat:@"%@&%@&%@", [method uppercaseString], [self rfc3986EncodedString:baseURL], paramsToSign];
    NSString * signature = [self signatureForString:stringToSign];
    
    // add the signature to the params.
    NSMutableDictionary * headerParams = [params mutableCopy];
    [headerParams setObject:signature forKeyedSubscript:kOAuthAuthenticationReverseOAuthTwitterSignatureParam];
    
    // calculate the Authentication String
    NSString * authHeader = [NSString stringWithFormat:@"%@ ", kOAuthAuthenticationReverseOAuthAuthorizationHeaderValue];
    NSArray * headerKeys = [headerParams allKeys];
    for (int i = 0; i < headerKeys.count; i++) {
        NSString * key = headerKeys[i];
        authHeader = [authHeader stringByAppendingFormat:@"%@=\"%@\"", [self rfc3986EncodedString:key], [self rfc3986EncodedString:[headerParams objectForKey:key]]];
        if (i != (headerKeys.count - 1)) authHeader = [authHeader stringByAppendingString:@", "];
    }
    
    // prepare an HTTP (plain text, actually) request and response for the communication.
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:authHeader forHTTPHeaderField:kOAuthAuthenticationReverseOAuthAuthorizationHeaderPrefix];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    // execute the request
    [manager POST:baseURL parameters:@{ @"x_auth_mode" : @"reverse_auth" } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // analyze results
        NSString * response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"Twitter Reverse OAuth step 1 response: %@", response);
        [self retrieveTwitterOAuthTokenFromRequestTokenResponse:response forTwitterId:twitterId withBlock:tokenBlock];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) { // invalid request.
        NSLog(@"Error in Twitter Reverse OAuth step 1: %@", error.localizedDescription);
        tokenBlock(NO, nil);
    }];
}

/** @brief Second stage of Twitter OAuth reverse authentication
 * Performs the second request for Twitter's Reverse OAuth authentication flow. Will send the response to the GCD block tokenBlock.
 * @param response the Twitter response from stage 1, that will be used for the second request.
 * @param twitterId the twitter ID to use for the reverse authentication flow. Must be obtained previously from the user's Twitter ACAccounts.
 * @param tokenBlock A GCD block that will receive the response of the reverse authentication. If successful, success will be set to YES and credentials will include the
 */
- (void) retrieveTwitterOAuthTokenFromRequestTokenResponse: (NSString *) response forTwitterId: (NSString *) twitterId withBlock: ( void (^) (BOOL success, TwitterReverseOAuthCredentials * credentials) ) tokenBlock {
    // set baseURL and parameters for second stage
    NSDictionary * params = @{kOAuthAuthenticationReverseOAuthTwitterXReverseAuthParam: kOAuthAuthenticationTwitterAPIKey,
                              kOAuthAuthenticationReverseOAuthTwitterXReverseParamsParam: response};
    NSURL * baseURL = [NSURL URLWithString:kOAuthAuthenticationReverseOAuthAccessTokenTwitterURL];
    // build request
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:baseURL parameters:params];
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter];

    // Check/obtain permissions for accessing the twitter account.
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if (!granted) { // access refused by user/system
            tokenBlock(NO, nil);
        } else { // access granted. Obtain all the local account instances
            NSArray *accounts = [self.accountStore accountsWithAccountType:twitterType];
            ACAccount * matchingAccount = nil;
            
            // find the account with matching twitterId
            for (ACAccount * account in accounts) {
                NSString * accountId = [account valueForKeyPath:@"properties.user_id"];
                if (accountId && [accountId isEqualToString:twitterId]) {
                    matchingAccount = account;
                    break;
                }
            }
            
            // match found?
            if (!matchingAccount) {
                tokenBlock(NO, nil);
                return;
            }
            
            // perform request with the matching account
            [request setAccount:matchingAccount];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (!error) {
                    NSString * result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"Twitter Reverse OAuth step 2 response: %@", result);
                    TwitterReverseOAuthCredentials * credentials = [self credentialsFromTwitterResponseString:result];
                    if (credentials) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            tokenBlock(YES, credentials);
                        });
                    }
                    else dispatch_async(dispatch_get_main_queue(), ^{ tokenBlock(NO, nil); });
                } else dispatch_async(dispatch_get_main_queue(), ^{ tokenBlock(NO, nil); });
            }];
        }
    }];
}

/** Extracts the credentials from Twitter reverse auth stage 2, including the OAuth Token and OAuth Token Secret */
- (TwitterReverseOAuthCredentials *) credentialsFromTwitterResponseString: (NSString *) string {
    TwitterReverseOAuthCredentials * credentials = [[TwitterReverseOAuthCredentials alloc] init];
    
    NSArray * components = [string componentsSeparatedByString:@"&"];
    if (components && components.count > 0) {
        for (NSString * keyValuePair in components) {
            NSArray * parameters = [keyValuePair componentsSeparatedByString:@"="];
            if (parameters && parameters.count > 1) {
                NSString * key = parameters[0];
                NSString * value = parameters[1];
                if ([key isEqualToString:kOAuthAuthenticationReverseOAuthTwitterOAuthTokenParam]) credentials.oauthToken = value;
                else if ([key isEqualToString:kOAuthAuthenticationReverseOAuthTwitterOAuthTokenSecretParam]) credentials.oauthTokenSecret = value;
                else if ([key isEqualToString:kOAuthAuthenticationReverseOAuthTwitterOAuthUserIdParam]) credentials.twitterId = value;
                else if ([key isEqualToString:kOAuthAuthenticationReverseOAuthTwitterOAuthScreenNameParam]) credentials.screenName = value;
            }
        }
        return credentials;
    }
    return nil;
}

- (NSString *) paramsStringForReverseTwitterOauthRequest: (NSDictionary *) params {
    NSArray * keys = [[params allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:keys.count];
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSString * paramToAdd = [NSString stringWithFormat:@"%@=%@", [self rfc3986EncodedString:key], [self rfc3986EncodedString:[params objectForKey:key]]];
        [parametersArray addObject:[self rfc3986EncodedString:paramToAdd]];
    }];
    return [parametersArray componentsJoinedByString:[self rfc3986EncodedString:@"&"]];
    
}

- (NSString *) signatureForString:(NSString *)string {
    NSString *key = [NSString stringWithFormat:@"%@&", kOAuthAuthenticationTwitterAPISecret]; // No OAuth token secret for the request token flow.
    
    const char *keyBytes = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *baseStringBytes = [string cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char digestBytes[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, keyBytes, strlen(keyBytes), baseStringBytes, strlen(baseStringBytes), digestBytes);
    
    NSData *digestData = [NSData dataWithBytes:digestBytes length:CC_SHA1_DIGEST_LENGTH];
    return [digestData base64EncodedStringWithOptions:0];
}

- (NSString *) rfc3986EncodedString: (NSString *) string {
    CFStringRef charactersToBeEscaped = CFSTR("!*'();:@&=+$,/?#[]<>\"{}|\\`^% ");
    NSString *encodeString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)string, NULL, charactersToBeEscaped, kCFStringEncodingUTF8));
    return encodeString;
}



#pragma mark register

/**
 * Optional: include a request for registering the user in your REST API platform by the common username(email?)/password schema.
 * @param name user's name
 * @param password user's password.
 */
- (void) registerUserByName: (NSString *) name andPassword: (NSString *) password listener: (id <RegistrationListener>) listener {
    // build the request, baseURL and parameters
    NSString * baseURL = [NSString stringWithFormat:@"%@%@", kOAuthAuthenticationRESTBaseURL, kOAuthAuthenticationRESTRegisterURL];
    AFHTTPRequestOperationManager * manager = [[AFHTTPRequestOperationManager alloc] init];
    [self prepareRequestOperationManagerForTestingWithInvalidCertificates:manager];
    NSDictionary * parameters = @{kOAuthAuthenticationUserParameterAccessType: kOAuthAuthenticationAccessTypeEmailPassword,
                                  kOAuthAuthenticationUserParameterPasskey: name,
                                  kOAuthAuthenticationUserParameterPasscode: password };

    // execute the request
    [manager POST:baseURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // analyze results
        NSLog(@"Response from /register: %@", responseObject);
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) { // success. Extract token.
            NSDictionary * responseDict = (NSDictionary *) responseObject;
            BOOL error = responseDict[kOAuthAuthenticationUserParameterError]?[responseDict[kOAuthAuthenticationUserParameterError] boolValue]:NO;
            NSString * message = responseDict[kOAuthAuthenticationUserParameterMessage]?kOAuthAuthenticationUserParameterMessage:@"";
            if (!error) {
                [listener registrationSucceedWithAccountType:kOAuthAuthenticationAccessTypeEmailPassword passkey:name passcode:password andMessage:message];
            } else [listener registrationFailedReason:message];
        } else [listener registrationFailedReason:@"unable to register"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) { // invalid request.
        NSLog(@"Error registering: %@", error.localizedDescription);
        [listener registrationFailedReason:error.localizedDescription];
    }];
}

- (void) registerUserBySocialAccount: (ACAccount *) account listener: (id <RegistrationListener>) listener {
    if ([account.accountType.identifier isEqualToString:ACAccountTypeIdentifierFacebook]) { // Facebook
        // get oauth token
        NSString * oauthToken = account.credential.oauthToken;
        if (oauthToken) {
            // build credentials
            NSString * userid = [account valueForKeyPath:@"properties.uid"];
            if ([listener respondsToSelector:@selector(notifyOfAuthenticationProcess:)])
                [listener notifyOfAuthenticationProcess:[NSString stringWithFormat:@"Registering with facebook account id = %@, oauth token = %@", userid, oauthToken]];
            
            // call registration
            [self registerUserBySocialAccountWithAccessType:kOAuthAuthenticationAccessTypeFacebook passkey:userid passcode:oauthToken andListener:listener];
        } else [listener registrationFailedReason:@"unable to register"];
    } else if ([account.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter]) { // Twitter
        // retrieve the oauth token and secrey by twitter reverse oauth flow.
        [self getTwitterOAuthTokenForAccountWithId:[account valueForKeyPath:@"properties.user_id"] andBlock:^(BOOL success, TwitterReverseOAuthCredentials *credentials) {
            if (success) {
                // build credentials
                NSString * userid = [account valueForKeyPath:@"properties.user_id"];
                NSString * combinedOAuthTokenAndSecret = [NSString stringWithFormat:@"%@:%@", credentials.oauthToken, credentials.oauthTokenSecret];
                if ([listener respondsToSelector:@selector(notifyOfAuthenticationProcess:)])
                    [listener notifyOfAuthenticationProcess:[NSString stringWithFormat:@"Registering with twitter account id = %@, oauth token = %@, oauth token secret = %@", userid, credentials.oauthToken, credentials.oauthTokenSecret]];

                // call registration
                [self registerUserBySocialAccountWithAccessType:kOAuthAuthenticationAccessTypeTwitter passkey:userid passcode:combinedOAuthTokenAndSecret andListener:listener];
            } else { // Unknown or unsupported account type
                [listener registrationFailedReason:@"unable to get authorization account"];
            }
        }];
    } else [listener registrationFailedReason:@"unable to register"];
}

- (void) registerUserBySocialAccountWithAccessType: (NSString *) accessType passkey: (NSString *) passkey passcode: (NSString *) passcode andListener: (id <RegistrationListener>)listener {
    // build the request, baseURL and parameters
    NSString * baseURL = [NSString stringWithFormat:@"%@%@", kOAuthAuthenticationRESTBaseURL, kOAuthAuthenticationRESTRegisterURL];
    AFHTTPRequestOperationManager * manager = [[AFHTTPRequestOperationManager alloc] init];
    [self prepareRequestOperationManagerForTestingWithInvalidCertificates:manager];
    
    NSDictionary * parameters = @{kOAuthAuthenticationUserParameterAccessType: accessType,
                                  kOAuthAuthenticationUserParameterPasskey: passkey,
                                  kOAuthAuthenticationUserParameterPasscode: passcode };
    
    // execute the request
    [manager POST:baseURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // analyze results
        NSLog(@"Recibida respuesta de /register: %@", responseObject);
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) { // success. Extract token.
            NSDictionary * responseDict = (NSDictionary *) responseObject;
            BOOL error = responseDict[kOAuthAuthenticationUserParameterError]?[responseDict[kOAuthAuthenticationUserParameterError] boolValue]:NO;
            NSString * message = responseDict[kOAuthAuthenticationUserParameterMessage]?responseDict[kOAuthAuthenticationUserParameterMessage]:@"";
            if (!error) [listener registrationSucceedWithAccountType:accessType passkey:passkey passcode:passcode andMessage:message];
            else [listener registrationFailedReason:message];
        } else {
            [listener registrationFailedReason:@"unable to register"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) { // invalid request.
        [listener registrationFailedReason:@"unable to register"];
    }];
    
}

#pragma mark utilities

/** 
 * This method's only purpose is to force AFNetworking to ignore invalid/self signed certificates issued by you when testing this
 * class locally. It should NOT be included in production environments where you have valid certificates.
 */
- (void) prepareRequestOperationManagerForTestingWithInvalidCertificates: (id) manager {
    if ([manager respondsToSelector:@selector(setSecurityPolicy:)]) {
        AFSecurityPolicy * sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        sp.allowInvalidCertificates = YES;
        sp.validatesDomainName = NO;
        sp.validatesCertificateChain = NO;
        [manager setSecurityPolicy:sp];
    }
}

@end
