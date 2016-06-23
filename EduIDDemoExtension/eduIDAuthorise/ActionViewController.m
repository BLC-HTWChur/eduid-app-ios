//
//  ActionViewController.m
//  eduIDAuthorise
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

@import MobileCoreServices;

#import "ActionViewController.h"
#import "../OAuthRequester.h"

@interface ActionViewController ()

@property (weak, nonatomic) IBOutlet UITextField *eduIdLoginName;

@property (weak, nonatomic) IBOutlet UITextField *eduIdPassword;

@property (weak, nonatomic) IBOutlet UILabel *serverURL;

@property (weak, nonatomic) IBOutlet UIButton *buttonLogIn;

@property (weak, nonatomic) IBOutlet UIView *canvas;

@end

@implementation ActionViewController


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

    // init out shared data and the OAuthRequester
    
    SharedDataStore *ds = [self eduIdDS];
    
    NSString *tString =@"{\"kid\":\"1234test-14\",\"mac_key\":\"helloWorld\",\"mac_algorithm\":\"HS256\",\"client_id\":\"ch.htwchur.eduid.ios.0\",\"access_token\":\"acf5acfaa58665e6e74f9d03e504b7dce7bc9568\"}";
    
    OAuthRequester *req = [OAuthRequester oauthWithUrlString:@"https://eduid.htwchur.ch/eduid/eduid.php/token"];
    
    [req setDataStore:ds];
    [req setDeviceToken:tString];
    
    // we should see our shared keys in the logs.
    
    // Now it is time to look at which protocols have to be handled.

    NSExtensionItem *item = self.extensionContext.inputItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    
    [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
                                    options:nil
                          completionHandler:^(id results, NSError *error)
     {
         if (!error) {
             [self receiveProtocols:(NSArray*)results];
         }
     }];

}

//This is called by the completion handler (when data unpacking of the data sent by the extension is finished)
-(void) receiveProtocols:(NSArray *) protocolList
{
    for (NSString *s in protocolList) {
        NSLog(@"Protocol Name: %@", s);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//button to finish extension was pressed
- (IBAction)done {
    //we are finished
    [self extensionDone];
}

/** enable or disable the whole GUI
 @param inEnable: YES: enable GUI, NO: disabl GUI */
-(void)viewEnableGUI:(BOOL) inEnable
{
    [_eduIdLoginName setEnabled:inEnable];
    [_eduIdLoginName setEnabled:inEnable];
    [_eduIdPassword setEnabled:inEnable];
    [_buttonLogIn setEnabled:inEnable];
}

//we are done with the extension, return to caller
-(void) extensionDone
{
    //create a dummy json string for the service token.
    // FIXME use shared persistant data store for keeping the data
    // TODO load data from data store and filter the apis.
    // TODO attach the token data from the service endpoints to the RSD.

    NSDictionary *token = [NSDictionary dictionaryWithObjectsAndKeys:@"1234", @"kid", @"helloWorld", @"mac_key", @"HS256", @"mac_algorithm", @"123123121241513513", @"client_id",nil];
    NSDictionary *xapi  = [NSDictionary dictionaryWithObjectsAndKeys:@"lrs/xapi", @"apiLink", nil];
    NSDictionary *qti  = [NSDictionary dictionaryWithObjectsAndKeys:@"content/qti", @"apiLink", nil];
    NSDictionary *apis  = [NSDictionary dictionaryWithObjectsAndKeys: xapi, @"gov.adlnet.xapi", qti, @"org.imsglobal.qti", nil];
    NSDictionary *engineRsd = [NSDictionary dictionaryWithObjectsAndKeys:@"https://moodle.htwchur.ch", @"homePageLink", @"", @"engineLink", apis, @"apis", token, @"token", nil];

    NSDictionary *services = [NSDictionary dictionaryWithObjectsAndKeys: engineRsd, @"moodle.htwchur.ch", nil];

    //create structure to return data to the calling app
    NSExtensionItem* extensionItem = [[NSExtensionItem alloc] init];
    //Place the data in the transfer data structure.

    [extensionItem setAttributedTitle:[[NSAttributedString alloc] initWithString:EDUID_EXTENSION_TITLE]];

    [extensionItem setAttachments:@[[[NSItemProvider alloc] initWithItem:services
                                                          typeIdentifier:EDUID_EXTENSION_TYPE]]];

    // call directly because the extension terminates after returning the data.
    [self.extensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
}

@end
