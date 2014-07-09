//
//  ViewController.m
//  SocialLoginForiOS
//
//  Created by Nacho on 9/7/14.
//  Copyright (c) 2014 Ignacio Nieto Carvajal. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
            
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *signWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *signWithTwitterButton;

@property (nonatomic, strong) NSArray * accounts; // array of social accounts.

@end

@implementation ViewController

@synthesize accounts = _accounts;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark button actions

- (IBAction)signWithFacebook:(id)sender {
    // update UI
    self.textView.text = @"";
    self.signWithFacebookButton.userInteractionEnabled = NO;
    self.signWithTwitterButton.userInteractionEnabled = NO;
    // let's retrieve the facebook accounts.
    [[OAuthRESTManager sharedInstance] getFacebookAccountsWithListener:self];
}

- (IBAction)signWithTwitter:(id)sender {
    // update UI
    self.textView.text = @"";
    self.signWithFacebookButton.userInteractionEnabled = NO;
    self.signWithTwitterButton.userInteractionEnabled = NO;
    // let's retrieve the twitter accounts.
    [[OAuthRESTManager sharedInstance] getTwitterAccountsWithListener:self];
}

#pragma mark social accounts delegate methods

/** The user refused access to the service accounts */
- (void) accessRefusedByUserToService: (NSString *) serviceType {
    [self.textView insertText:[NSString stringWithFormat:@"Access denied to your accounts of type %@\n", serviceType]];
    self.signWithFacebookButton.userInteractionEnabled = YES;
    self.signWithTwitterButton.userInteractionEnabled = YES;
}

/** Access was granted for an array of ACAccounts like twitter/facebook */
- (void) accessGrantedForAccounts:(NSArray *) accounts inService:(NSString *) serviceType {
    if (!accounts || accounts.count < 1) {
        [self noAccountsForService:serviceType];
    }
    else if (accounts.count == 1) { // just one account. Register-login using this one
        ACAccount * account = [accounts firstObject];
        [[OAuthRESTManager sharedInstance] registerUserBySocialAccount:account listener:self];
    } else { // more than one account. Ask the user.
        UIAlertView * alertView;
        self.accounts = accounts;
        alertView = [[UIAlertView alloc] initWithTitle:@"Choose account" message:@"Choose the account you want to register with" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:nil];
        for (ACAccount * account in self.accounts) [alertView addButtonWithTitle:account.username];
        [alertView show];
    }
}

/** There are no accounts configured for the specified service */
- (void) noAccountsForService: (NSString *) serviceType {
    [self.textView insertText:[NSString stringWithFormat:@"You don't have any accounts configured for %@. You need to go to the Settings App and configure at least one.\n", serviceType]];
    self.signWithFacebookButton.userInteractionEnabled = YES;
    self.signWithTwitterButton.userInteractionEnabled = YES;
}

#pragma mark registration listener methods

/** Registration was successful. */
- (void) registrationSucceedWithAccountType: (NSString *) accountType passkey: (NSString *) passkey passcode: (NSString *) passcode andMessage: (NSString *) message {
    [self.textView insertText:[NSString stringWithFormat:@"\nRegistration succeed:\n%@\n", message]];
    self.signWithFacebookButton.userInteractionEnabled = YES;
    self.signWithTwitterButton.userInteractionEnabled = YES;

    // here you would probably want to start a login request.
}

/** Registration failed with reason message */
- (void) registrationFailedReason: (NSString *) message {
    [self.textView insertText:[NSString stringWithFormat:@"\nRegistration failed:%@\n", message]];
    self.signWithFacebookButton.userInteractionEnabled = YES;
    self.signWithTwitterButton.userInteractionEnabled = YES;
}

- (void) notifyOfAuthenticationProcess:(NSString *)message {
    [self.textView insertText:[NSString stringWithFormat:@"%@\n", message]];
}

#pragma mark alert views

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.accounts && (buttonIndex > 0)) {
        [[OAuthRESTManager sharedInstance] registerUserBySocialAccount:[self.accounts objectAtIndex:buttonIndex - 1] listener:self];
    } else {
        [self.textView insertText:@"Registration cancelled by the user.\n"];
    }
}


@end
