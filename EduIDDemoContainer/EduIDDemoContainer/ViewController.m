//
//  ViewController.m
//  EduIDDemoContainer
//
//  Created by SII on 26.05.16.
//  Copyright © 2016 HTW Chur. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ViewController.h"

#import "AppDelegate.h"
#import "IdNativeAppIntegrationLayer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *eduIdLoginName;

@property (weak, nonatomic) IBOutlet UITextField *eduIdPassword;

@property (weak, nonatomic) IBOutlet UILabel *token;

@property (weak, nonatomic) IBOutlet UIButton *buttonAuthorise;

@property (readonly, atomic) IdNativeAppIntegrationLayer *nail;

@end


@implementation ViewController

@synthesize nail;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.


    // [nail getEndpointAuthorization:@"foo" withProtocol:@"bar" withClaims: nil];

    // self.token.text = @"foo";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)authorButtonPressed:(id)sender
{
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    nail = [[IdNativeAppIntegrationLayer alloc] init];
    [main setNail:nail];

    NSArray *protocols = @[@"gov.adlnet.xapi", @"powertla.content.courselist"];

    [nail requestProtocols:protocols forObject:self withSelector:@selector(idExtensionCompleted)];
}

- (void) idExtensionCompleted {
    NSLog(@"ID Extension Completed");
    if ([[nail serviceNames] count]) {
        // continue with authorized requests

        // handover to the authorization list
        [self performSegueWithIdentifier:@"toAuthorizationList" sender:self];
    }
}


@end
