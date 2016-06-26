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
#import "../EduIDDemoExtension/JWT.h"

@interface ActionViewController ()

@property (retain) NSArray *myProtocols;
@property (retain) NSArray *myServices;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SharedDataStore *ds = [self eduIdDS];
    
    
    if (![self oauth]) {
        NSString *tString =@"{\"kid\":\"1234test-14\",\"mac_key\":\"helloWorld\",\"mac_algorithm\":\"HS256\",\"client_id\":\"ch.htwchur.eduid.ios.0\",\"access_token\":\"acf5acfaa58665e6e74f9d03e504b7dce7bc9568\"}";
        
        OAuthRequester *req = [OAuthRequester oauthWithUrlString:@"https://eduid.htwchur.ch/eduid/eduid.php"];
        
        [self setOauth: req];
        
        [req setDataStore:ds];
        [req setDeviceToken:tString];
    }
    
    [[self oauth] registerReceiver:self
                      withSelector:@selector(requestDone)];
    
    NSLog(@"Load Extension Context!");
    
    if (![self origContext]) {
        NSLog(@"init extension context");
        [self setOrigContext:self.extensionContext];
        
        NSExtensionItem *item = self.extensionContext.inputItems[0];
        NSItemProvider *itemProvider = item.attachments[0];
        
        NSLog(@"check type %@", EDUID_EXTENSION_TYPE);
        
        [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
                                        options:nil
                              completionHandler:^(id results, NSError *error)
         {
             if (!error) {
                 NSLog(@"no error and received data");
                 [self receiveProtocols:(NSArray*)results];
             }
             else {
                 NSLog(@"invalid extension context");
             }
         }];
    }

    _myProtocols = @[];
    _myServices  = @[];

    if ([self requestData] && [[self requestData] count]) {
        NSLog(@"request services for protocols");
        [[self oauth] postProtocolList:[self requestData]];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    // test if we are logged in
    if (![[self oauth] accessToken])
    {
        [self performSegueWithIdentifier:@"toLoginView" sender:self];
    }
    else {
        // find out if the user's services provide the appropriate interfaces
        
        // if not we send the user directly to the federation search.
    }
}

//This is called by the completion handler (when data unpacking of the data sent by the extension is finished)
-(void) receiveProtocols:(NSArray *) protocolList
{
    NSLog(@"receive %lu protocols", [protocolList count]);
    [self setRequestData:protocolList];
    _myProtocols = protocolList;

    if ([self requestData] && [[self requestData] count]) {
        NSLog(@"request services for protocols");
        [[self oauth] postProtocolList:[self requestData]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//button to finish extension was pressed
- (IBAction)done {
    //we are finished
    NSLog(@"return to container app");
    [self extensionDone];
}

/** enable or disable the whole GUI
 @param inEnable: YES: enable GUI, NO: disabl GUI */
//we are done with the extension, return to caller
-(void) extensionDone
{
    //create a dummy json string for the service token.
    // FIXME use shared persistant data store for keeping the data
    // TODO load data from data store and filter the apis.
    // TODO attach the token data from the service endpoints to the RSD.

    NSDictionary *token = @{@"kid": @"1234",
                            @"mac_key": @"helloWorld",
                            @"mac_algorithm": @"HS256",
                            @"client_id": @"123123121241513513"};
    
    NSDictionary *xapi  = @{@"apiLink":@"lrs/xapi"};
    NSDictionary *qti  = @{@"apiLink": @"content/qti"};
    
    NSDictionary *apis  = @{@"gov.adlnet.xapi": xapi,
                            @"org.imsglobal.qti": qti};
    
    NSDictionary *engineRsd = @{@"homePageLink": @"https://moodle.htwchur.ch",
                                @"engineLink": @"",
                                @"apis": apis,
                                @"token": token,
                                @"name": @"moodle@HTW Chur"};
    

    NSDictionary *services = [NSDictionary dictionaryWithObjectsAndKeys: engineRsd, @"moodle.htwchur.ch", nil];

    //create structure to return data to the calling app
    NSExtensionItem* extensionItem = [[NSExtensionItem alloc] init];
    //Place the data in the transfer data structure.

    [extensionItem setAttributedTitle:[[NSAttributedString alloc] initWithString:EDUID_EXTENSION_TITLE]];

    [extensionItem setAttachments:@[[[NSItemProvider alloc] initWithItem:services
                                                          typeIdentifier:EDUID_EXTENSION_TYPE]]];

    // call directly because the extension terminates after returning the data.
    [[self origContext] completeRequestReturningItems:@[extensionItem] completionHandler:nil];
}

- (void) requestDone
{
    // the protocol request succeeded
    NSString *result = [[self oauth] result];
    if (result != nil) {
        if (result != [[self oauth] clientToken] &&
            result != [[self oauth] accessToken]) {
            // only respond to our requests
            NSLog(@"received result %@", result);
            
            _myServices = (NSArray*)[JWT jsonDecode:result];
            
            // display
            [_tableView reloadData];
        }
        NSLog(@"result data: %@", result);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"init tableview with %lu rows", (unsigned long)[_myServices count]);
    return [_myServices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"get cell at index %@", indexPath);
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [[_myServices objectAtIndex:indexPath.row] objectForKey:@"engineName"];
    return cell;
}

@end
