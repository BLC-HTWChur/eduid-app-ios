//
//  SplashViewController.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 24/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "SplashViewController.h"
#import "AppDelegate.h"
#import "../OAuthRequester.h"

#import "../RequestData.h"

@interface SplashViewController ()

@property (retain, nonatomic) OAuthRequester *req;

@end

@implementation SplashViewController {
}

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    req = [main oauth];

    [req registerReceiver:self withCallback:@selector(requestDone:)];
}

-(void) viewDidAppear:(BOOL)animated
{
    [req verifyAuthorization:@selector(requestDone:)];
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

- (void) requestDone: (RequestData*)result
{
    if ([req accessToken]) {
        NSLog(@"appeared & got access token, switch to profile view");
        [self performSegueWithIdentifier:@"toRootProfileSegue" sender:self];
    }
    else {
        NSLog(@"appeared & should send to login view");
        [self performSegueWithIdentifier:@"toRootLoginSegue" sender:self];
    }
}


@end
