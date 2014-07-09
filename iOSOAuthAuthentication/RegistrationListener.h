//
//  RegistrationListener.h
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//



@protocol RegistrationListener <NSObject>

/** Registration was successful. */
- (void) registrationSucceedWithAccountType: (NSString *) accountType passkey: (NSString *) passkey passcode: (NSString *) passcode andMessage: (NSString *) message;

/** Registration failed with reason message */
- (void) registrationFailedReason: (NSString *) message;

@optional

/** This method is just for testing purposes, to show the results of the OAUth reverse authentication flow steps */
- (void) notifyOfAuthenticationProcess: (NSString *) message;

@end