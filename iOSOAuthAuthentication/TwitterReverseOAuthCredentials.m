//
//  TwitterReverseOAuthCredentials.m
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

#import "TwitterReverseOAuthCredentials.h"

@implementation TwitterReverseOAuthCredentials

- (id) initWithTwitterId: (NSString *) twitterId screenName: (NSString *) screenName OAuthToken: (NSString *) oauthToken andOAuthAccessToken: (NSString *) oauthTokenSecret {
    self = [super init];
    if (self) {
        self.twitterId = twitterId;
        self.screenName = screenName;
        self.oauthToken = oauthToken;
        self.oauthTokenSecret = oauthTokenSecret;
    }
    return self;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"Twitter Reverse OAuth Credentials: Twitter ID = %@, Screen Name = %@, OAuth Token = %@, OAuth Token Secret = %@",
            self.twitterId, self.screenName, self.oauthToken, self.oauthTokenSecret];
}

@end
