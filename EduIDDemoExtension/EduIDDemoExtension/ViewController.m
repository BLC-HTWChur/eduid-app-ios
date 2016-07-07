//
//  ViewController.m
//  EduIDDemoExtension
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project: UNUSED

#import "ViewController.h"


@import MobileCoreServices;

#import "AppDelegate.h"

#import "../OAuthRequester.h"
#import "../RequestData.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (readonly) OAuthRequester *req;

@end

@implementation ViewController {
    NSInteger didAppear;
    BOOL kbResize;
    BOOL authRetry;
}

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];
    didAppear = 0;
    kbResize = NO;
    authRetry = NO;

    // Do any additional setup after loading the view, typically from a nib.

    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    req = [main oauth];

    [req registerReceiver:self withCallback:@selector(requestDone:)];

    [self registerForKeyboardNotifications];
}

-(void) viewDidAppear:(BOOL)animated
{
    didAppear = 1;
}

- (void) requestDone: (RequestData*)result
{
    
    // There are 3 cases during login.
    // case 1: There is no client token, in this case our login has failed badly and we have to retry after reset
    // case 2: there is a client token but no access token and we should retry.
    // case 3: there is a client token but no access token in this case the login has just normally failed.

    if ([[result status] integerValue] > 0) {
        if (![req clientToken]) {
            authRetry = [result shouldRetry];
        }
        else if ([req clientToken] && ![req accessToken] && authRetry) {
            authRetry = NO;
            if ([_passwordInput.text length] &&
                [_usernameInput.text length]) {

                [req postPassword:_passwordInput.text
                          forUser:_usernameInput.text
                     withCallback:nil];
            }
        }
        else if ([req clientToken] && ![req accessToken]) {
            // login failed.
            // TODO display error message
        }
        else {
            [self performSegueWithIdentifier:@"toProfileSegue"
                                      sender:self];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    [_passwordInput resignFirstResponder];
    [_usernameInput resignFirstResponder];

    if ([_passwordInput.text length] && [_usernameInput.text length]) {
        [req postPassword:_passwordInput.text
                  forUser:_usernameInput.text
             withCallback:@selector(requestDone:)];
    }
    else {
        NSLog(@"username and/or password empty");
    }
}

- (void)registerForKeyboardNotifications
{
    NSLog(@"register keyboard notifications");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];

    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.contentView.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];

    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.contentView.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
    } completion:nil];
}

@end
