//
//  ViewController.m
//  EduIDDemoContainer
//
//  Created by SII on 26.05.16.
//  Copyright © 2016 HTW Chur. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ViewController.h"
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

    nail = [[IdNativeAppIntegrationLayer alloc] init];

    // [nail getEndpointAuthorization:@"foo" withProtocol:@"bar" withClaims: nil];

    // self.token.text = @"foo";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)authorButtonPressed:(id)sender
{
    NSArray *protocols = @[@"gov.adlnet.xapi", @"org.imsglobal.qti"];

    [nail requestProtocols:protocols forObject:self withSelector:@selector(idExtensionCompleted)];
}

- (void) idExtensionCompleted {
    NSLog(@"ID Extension Completed");

    NSLog(@"%@", [nail getServiceUrl:@"moodle.htwchur.ch" forProtocol:@"gov.adlnet.xapi"]);
    NSLog(@"%@", [nail getServiceAuthorization:@"moodle.htwchur.ch" forProtocol:@"gov.adlnet.xapi"]);
}


@end
