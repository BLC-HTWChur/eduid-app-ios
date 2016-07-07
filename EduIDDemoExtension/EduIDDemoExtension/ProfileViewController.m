//
//  ProfileViewController.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 24/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "ProfileViewController.h"

#import "AppDelegate.h"
#import "../OAuthRequester.h"
#import "JWT.h"

#import "../RequestData.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (retain) OAuthRequester *req;
@end

@implementation ProfileViewController

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    req = [main oauth];
    
    [req registerReceiver:self withCallback:@selector(requestDone:)];
    // load the profile
    [req getUserProfile:@selector(requestDone:)];
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

- (void) requestDone:(RequestData*)result
{
    // ok we got the user data
    NSArray  *profile = [result processedResult];
    
    if (profile != nil &&
        [profile count] > 0) {
        
        NSDictionary *extras =(NSDictionary*)[(NSDictionary*)[profile objectAtIndex:0] objectForKey:@"extra"];
        NSString *un = (NSString*)[extras objectForKey:@"name"];
        NSString *em = (NSString*)[(NSDictionary*)[profile objectAtIndex:0] objectForKey:@"mailaddress"];
        
        _usernameLabel.text = un;
        _emailLabel.text    = em;
    }
}


@end
