//
//  ViewController.m
//  EduIDDemoExtension
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ViewController.h"


@import MobileCoreServices;

#import "../OAuthRequester.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *serverURLText;

@property (weak, nonatomic) IBOutlet UIButton *setServerURL;

@property (readonly) OAuthRequester *req;

@end

@implementation ViewController {
    NSInteger cntUserAuth;
}

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *tString =@"{\"kid\":\"1234test-14\",\"mac_key\":\"helloWorld\",\"mac_algorithm\":\"HS256\",\"client_id\":\"ch.htwchur.eduid.ios.0\",\"access_token\":\"acf5acfaa58665e6e74f9d03e504b7dce7bc9568\"}";

    cntUserAuth = 0;
    
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    SharedDataStore *ds = [main eduIdDS];
    
    req = [OAuthRequester oauthWithUrlString:@"https://eduid.htwchur.ch/eduid/eduid.php/token"];
    
    [req setDataStore:ds];
    [req setDeviceToken:tString];

    [req registerReceiver:self withSelector:@selector(requestDone)];
    if (![req clientToken]) {
        [req postClientCredentials];
    }
}

- (void) requestDone
{
    NSLog(@"Oauth request completed with %@", [req status]);

    if ([req result])
        NSLog(@"request result %@", [req result]);

    if ([req deviceToken])
        NSLog(@"device token %@", [req deviceToken]);
    if ([req clientToken])
        NSLog(@"client token %@", [req clientToken]);
    if ([req accessToken])
        NSLog(@"user token %@", [req accessToken]);

    if ([[req status]  isEqual: @200] &&
        [req clientToken] &&
        cntUserAuth == 0) {
        NSLog(@"try to authenticate");
        cntUserAuth = cntUserAuth + 1;
        [req postPassword:@"test1234" forUser:@"cgl@htwchur.ch"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
