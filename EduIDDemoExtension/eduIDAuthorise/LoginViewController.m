//
//  LoginViewController.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 25/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation LoginViewController {
    BOOL authRetry;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    authRetry = NO;
    
    [[self oauth] registerReceiver:self
                      withSelector:@selector(requestDone:withResult:)];
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performLogin:(id)sender {
    
    [_passwordInput resignFirstResponder];
    [_usernameInput resignFirstResponder];
    
    if ([_passwordInput.text length] && [_usernameInput.text length]) {
        [[self oauth] postPassword:_passwordInput.text
                           forUser:_usernameInput.text];
    }
    else {
        NSLog(@"username and/or password empty");
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) requestDone: (NSNumber*)status withResult: (NSString*)result
{
    OAuthRequester *req = [self oauth];
    
    // There are 3 cases during login.
    // case 1: There is no client token, in this case our login has failed badly and we have to retry after reset
    // case 2: there is a client token but no access token and we should retry.
    // case 3: there is a client token but no access token in this case the login has just normally failed.

    if ([status integerValue] > 0) {
        if (![req clientToken]) {
            authRetry = [req retry];
        }
        else if ([req clientToken] && ![req accessToken] && authRetry) {
            // retry with fixed client token
            authRetry = NO;
            if ([_passwordInput.text length] &&
                [_usernameInput.text length]) {
                
                [req postPassword:_passwordInput.text
                          forUser:_usernameInput.text];
            }
        }
        else if ([req clientToken] && ![req accessToken]) {
            // login failed.
            
            // TODO display error message
        }
        else {
            // authorization OK, pass on to the users service overview
            [self performSegueWithIdentifier:@"toMyServiceView"
                                      sender:self];
        }
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
