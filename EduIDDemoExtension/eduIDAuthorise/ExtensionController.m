//
//  ExtensionController.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 25/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "ExtensionController.h"

@interface ExtensionController ()

@end

@implementation ExtensionController

@synthesize origContext;
@synthesize requestData;
@synthesize oauth;

@synthesize eduIdDS = _dataStore;

- (SharedDataStore*)eduIdDS
{
    if (!_dataStore) {
        _dataStore = [[SharedDataStore alloc] init];
    }
    return _dataStore;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!origContext) {
        NSLog(@"load: original context is missing");
    }
    if (!_dataStore) {
        NSLog(@"load: data store is missing");
    }
    if (!requestData) {
        NSLog(@"load: request data is missing");
    }
    if (!oauth) {
        NSLog(@"load: oauth handler is missing");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // for extensions we must pass ALL shared resources between the views.
    ExtensionController *target = [segue destinationViewController];
    
    if (!origContext) {
        NSLog(@"original context is missing");
    }
    else {
        NSLog(@"original context is OK");
    }
    if (!_dataStore) {
        NSLog(@"data store is missing");
    }
    else {
        NSLog(@"data store is OK");
    }
    if (!requestData) {
        NSLog(@"request data is missing");
    }
    else {
        NSLog(@"request data is OK");
    }
    if (!oauth) {
        NSLog(@"oauth handler is missing");
    }
    else {
        NSLog(@"oauth handler is OK");
    }
    
    [target setOrigContext:origContext];
    [target setEduIdDS:_dataStore];
    [target setRequestData:requestData];
    [target setOauth:oauth];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// override to do something with OAuth data
-(void) requestDone: (NSNumber*) status withResult: (NSString*)result
{}


@end
