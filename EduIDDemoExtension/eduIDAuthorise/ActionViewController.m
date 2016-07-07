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
#import "../UserService.h"
#import "../SharedDataStore.h"
#import "../RequestData.h"

#import "ServiceListCell.h"

@interface ActionViewController ()

@property (retain) NSArray *myServices;
@property (retain) NSDictionary *appRequest;
@property (retain, atomic) NSMutableArray *resultSet;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation ActionViewController {
    BOOL buildResult;
    BOOL initServiceTokens;

    NSInteger missingServices;
    NSInteger assertCountDown;
    NSInteger authSelfCountDown;
    NSInteger authAppCountDown;
}

@synthesize resultsController;
@synthesize resultSet;

- (void)viewDidLoad {
    [super viewDidLoad];

    buildResult = NO;
    initServiceTokens = NO;

    missingServices = 0;
    assertCountDown = 0;
    authSelfCountDown = 0;
    authAppCountDown = 0;

    SharedDataStore *ds = [self eduIdDS];
    
    
    if (![self oauth]) {
        NSString *tString =@"{\"kid\":\"1234test-14\",\"mac_key\":\"helloWorld\",\"mac_algorithm\":\"HS256\",\"client_id\":\"ch.htwchur.eduid.ios.0\",\"access_token\":\"acf5acfaa58665e6e74f9d03e504b7dce7bc9568\"}";
        
        OAuthRequester *req = [OAuthRequester oauthWithUrlString:@"https://eduid.htwchur.ch/eduid/eduid.php"];
        
        [self setOauth: req];
        
        [req setDataStore:ds];
        [req setDeviceToken:tString];
    }

    [self initializeFetchResultController];

    [[self oauth] registerReceiver:self
                      withCallback:@selector(requestDone:withResult:)];
    
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
                 [self setRequestData:results];
                 [self receiveProtocols:(NSArray*)[(NSDictionary*)results objectForKey:@"protocols"]];
             }
             else {
                 NSLog(@"invalid extension context");
             }
         }];
    }

    _appRequest = @{};
    _myServices  = @[];

    if ([self requestData]) {
        NSLog(@"request services for protocols %ld", [[self requestData] count]);
        [[self oauth] postProtocolList:[[self requestData] objectForKey:@"protocols"] withCallback:@selector(requestDone:)];
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
-(void) receiveProtocols:(NSArray *)protocolList
{
    NSLog(@"receive %lu protocols", [protocolList count]);
    NSLog(@"%@", [protocolList componentsJoinedByString: @", "]);
    if (protocolList && [protocolList count]) {
        NSLog(@"request services for protocols");

        [[self oauth] postProtocolList:protocolList
                          withCallback:@selector(requestDone:)];
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

    buildResult = NO;
    initServiceTokens = YES;

    SharedDataStore *ds = [[self oauth] dataStore];

    // for all services in the data that have no token, get one
    [[self oauth] registerReceiver:self
                      withCallback:@selector(userAssertionDone:)];

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
    
    NSDictionary *r = [self requestData];
    NSMutableDictionary *services = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *serviceApis = [NSMutableDictionary dictionary];
    
    for (NSDictionary *service in _myServices) {
        NSDictionary *apis = [service objectForKey:@"apis"];
        
        for (NSString *apiName in [r objectForKey:@"protocols"]) {
            NSDictionary *a = [apis objectForKey:apiName];
            if (a != nil) {
                [serviceApis setValue:a forKey:apiName];
            }
        }
        
        NSDictionary *engineRsd = @{@"homePageLink": [service valueForKey:@"homePageLink"],
                                    @"engineLink": [service valueForKey:@"engineLink"],
                                    @"apis": apis,
                                    @"token": token,
                                    @"engineName": [service valueForKey:@"engineName"]};

        [services setValue:engineRsd forKey:[service valueForKey:@"homePageLink"]];
    }
    
    

        //create structure to return data to the calling app
    NSExtensionItem* extensionItem = [[NSExtensionItem alloc] init];
    //Place the data in the transfer data structure.

    [extensionItem setAttributedTitle:[[NSAttributedString alloc] initWithString:EDUID_EXTENSION_TITLE]];

    [extensionItem setAttachments:@[[[NSItemProvider alloc] initWithItem:services
                                                          typeIdentifier:EDUID_EXTENSION_TYPE]]];

    // call directly because the extension terminates after returning the data.
    [[self origContext] completeRequestReturningItems:@[extensionItem] completionHandler:nil];
}

- (void) requestDone: (RequestData*)result
{
    if ([[result status] integerValue] != 200) {
        NSLog(@"ActionViewController received no data");
    }

    NSLog(@"LIST RESULT COMPLETE, REFRESH TABLE");

    NSError *err;
    if (![[self resultsController] performFetch:&err]) {
        NSLog(@"fetch failed %@ \n%@", [err localizedDescription], [err userInfo]);
    }

}

- (void) userAssertionDone: (RequestData*)result
{
    // count down the remaining services
    if (assertCountDown > 0) {
        assertCountDown = assertCountDown - 1;
    }
}

- (void) appAssertionDone: (RequestData*)result
{
    if (authAppCountDown > 0) {
        authAppCountDown = authAppCountDown - 1;
    }
    else {
        // now we can wrap up
    }
}

- (void) initializeFetchResultController
{
    NSFetchRequest *req= [NSFetchRequest fetchRequestWithEntityName:@"UserService"];

    [req setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES]]];

    OAuthRequester *oauth = [self oauth];

    NSManagedObjectContext *moc = [[oauth dataStore] managedObjectContext];

    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                            managedObjectContext:moc
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];

    [resultsController setDelegate:self];


    NSError *err;
    if (![[self resultsController] performFetch:&err]) {
        NSLog(@"fetch failed %@ \n%@", [err localizedDescription], [err userInfo]);
    }
    else {
        [_tableView reloadData];
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController*) controller
{
    NSLog(@"reload table view data");
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"number of sections %ld", [[[self resultsController] sections] count]);

    return [[[self resultsController] sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self resultsController] sections][section];

    NSLog(@"number of items in section %ld", [sectionInfo numberOfObjects]);

    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserService *us = [[self resultsController] objectAtIndexPath:indexPath];

    static NSString *serviceCellIdentifier = @"ServiceSelectionCEll";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:serviceCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:serviceCellIdentifier];
    }

    cell.textLabel.text = [us name];
    // [[us objectAtIndex:indexPath.row] objectForKey:@"engineName"];
    return cell;
}



@end
