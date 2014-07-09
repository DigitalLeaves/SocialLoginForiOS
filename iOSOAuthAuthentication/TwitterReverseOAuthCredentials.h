//
//  TwitterReverseOAuthCredentials.h
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterReverseOAuthCredentials : NSObject

/** The associated twitter ID for this credentials */
@property (nonatomic, strong) NSString * twitterId;

/** The associated twitter screen name for this credentials */
@property (nonatomic, strong) NSString * screenName;

/** The OAuth token */
@property (nonatomic, strong) NSString * oauthToken;

/** The OAuth token secret */
@property (nonatomic, strong) NSString * oauthTokenSecret;

/** The designated intializer */
- (id) initWithTwitterId: (NSString *) twitterId screenName: (NSString *) screenName OAuthToken: (NSString *) oauthToken andOAuthAccessToken: (NSString *) oauthTokenSecret;

@end
