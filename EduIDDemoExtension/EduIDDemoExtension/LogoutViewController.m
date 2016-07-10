//
//  LogoutViewController.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 24/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "LogoutViewController.h"
#import "AppDelegate.h"
#import "../OAuthRequester.h"
#import "../RequestData.h"

@interface LogoutViewController ()

@property (readonly) OAuthRequester *req;

@end

@implementation LogoutViewController{
    NSInteger didAppear;
}

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];
    didAppear = 0;

    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    req = [main oauth];
    [req registerReceiver:self
             withCallback:@selector(requestDone:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)logoutButtonPressed:(id)sender {
    NSLog(@"logout");
    [req logout:nil];
}

- (void)requestDone: (RequestData*)result
{
    // we expect only logout completions.
    NSLog(@"request done ");

    if (![req accessToken]) {
        // switch to profile view
        NSLog(@"got access token, switch to profile view");
        [self performSegueWithIdentifier:@"toLoginSegue"
                                  sender:self];

    }
    else {
        NSLog(@"access token is still present %@", [req accessToken]);
    }
}

@end
