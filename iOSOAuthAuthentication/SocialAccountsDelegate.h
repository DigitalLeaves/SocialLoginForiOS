//
//  SocialAccountsDelegate.h
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

@protocol SocialAccountsDelegate <NSObject>

/** The user refused access to the service accounts */
- (void) accessRefusedByUserToService: (NSString *) serviceType;

/** Access was granted for an array of ACAccounts like twitter/facebook */
- (void) accessGrantedForAccounts:(NSArray *) accounts inService:(NSString *) serviceType;

/** There are no accounts configured for the specified service */
- (void) noAccountsForService: (NSString *) serviceType;


@end