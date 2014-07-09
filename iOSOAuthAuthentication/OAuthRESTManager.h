//
//  OAuthRESTManager.h
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "AFNetworking.h"
#import "TwitterReverseOAuthCredentials.h"

// protocols and delegates
#import "SocialAccountsDelegate.h"
#import "RegistrationListener.h"


@interface OAuthRESTManager : NSObject

/** This Manager follows the Singleton design pattern, so it must be accessed through this shared instance */
+ (OAuthRESTManager *) sharedInstance;

#pragma mark registration

- (void) registerUserByName: (NSString *) name andPassword: (NSString *) password listener: (id <RegistrationListener>) listener;
- (void) registerUserBySocialAccount: (ACAccount *) account listener: (id <RegistrationListener>) listener;

#pragma mark twitter account

/**
 * Request the list of configured twitter accounts in the device. Will call on the SocialAccountsDelegate accessRefusedByUserToService:
 * if the access is not granted by the client, noAccountsForService: if no accounts are configured in the device, or
 * accessGrantedForAccounts:inService: in case of successfully retrieving the accounts.
 */
- (void) getTwitterAccountsWithListener: (id <SocialAccountsDelegate>) listener ;

#pragma mark Facebook accounts

/**
 * Request the list of configured facebook accounts in the device. Will call on the IMLoginDelegate accessRefusedByUserToService:
 * if the access is not granted by the client, noAccountsForService: if no accounts are configured in the device, or
 * accessGrantedForAccounts:inService: in case of successfully retrieving the accounts.
 */
- (void) getFacebookAccountsWithListener: (id <SocialAccountsDelegate>) listener ;

#pragma mark OAuth Reverse auth.

- (void) getTwitterOAuthTokenForAccountWithId: (NSString *) twitterId andBlock: ( void (^) (BOOL success, TwitterReverseOAuthCredentials * credentials) ) tokenBlock;


@end
