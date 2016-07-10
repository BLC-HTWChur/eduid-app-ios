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
#import "../Tokens.h"

#import "../SharedDataStore.h"
#import "../RequestData.h"

#import "ServiceListCell.h"

@interface ActionViewController ()

@property (retain) NSArray *myServices;               // selected services, if empty all matching are used
@property (retain) NSMutableArray *filteredServices;  // all matching services

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

    // for all services in the data that have no token, get one

    [self completeProtocolRequest];
}

- (void) completeProtocolRequest
{
    SharedDataStore *ds = [[self oauth] dataStore];
    NSManagedObjectContext *moc = [ds managedObjectContext];

    NSFetchRequest *reqU= [NSFetchRequest fetchRequestWithEntityName:@"UserService"];


    NSError *error = nil;
    NSArray *resUS = [moc executeFetchRequest:reqU error:&error];
    NSArray *resUT = nil;

    if (!error && resUS) {
        
        NSFetchRequest *reqT= [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];
        authAppCountDown = [resUS count];

        for     (UserService *us in resUS) {
            // check if we have a token for the service already
            NSString *targetUrl = [us token_target];
            [reqT setPredicate:[NSPredicate predicateWithFormat:@"target == %@ and type == %@", targetUrl, @"service"]];

            resUT = [moc executeFetchRequest:reqU error:&error];
            if (!error){
                if (resUT && [resUT count]) {
                    
                    Tokens *serviceToken = [resUT objectAtIndex:0];
                    
                    if ([serviceToken token] &&
                        [[serviceToken token] length]) {
                        NSLog(@"Service Token has been previously rejected?");
                        NSLog(@"First: retry service assertion");
                        [[self oauth] retrieveServiceAssertion:[us token_target]
                                                  withCallback:@selector(serviceAssertionDone:)];
                    }
                    else {
                        // directly request the app assertion from the service
                        NSLog(@"First: get app assertion from the service ");
                        [[self oauth] authorizeApp:[[self requestData] objectForKey:@"client_id"]
                                         atService:targetUrl
                                      withCallback:@selector(appAssertionDone:)];
                    }
                }
                else {
                    // first try to connect to the service and then get the app assertion
                    NSLog(@"First: get service assertion");
                    [[self oauth] retrieveServiceAssertion:[us token_target]
                                              withCallback:@selector(serviceAssertionDone:)];
                }
            }
            else {
                NSLog(@"error %@", error);
                error = nil;
            }
        }
    }
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

    NSDictionary *r = [self requestData];
    NSMutableDictionary *services = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *serviceApis = [NSMutableDictionary dictionary];

    // if the user has selected nothing in the table view, then use all services
    if (!_myServices) {
        for (UserService *us in _filteredServices) {
            _myServices = [JWT jsonDecode:[us rsd]];
        }
    }

    for (NSDictionary *service in _myServices) {
        NSDictionary *token = [self serviceToken:service];

        if (token) {
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

- (NSDictionary*) serviceToken:(NSDictionary*)service
{
    NSDictionary *dict = nil;

    SharedDataStore *ds = [[self oauth] dataStore];
    NSManagedObjectContext *moc = [ds managedObjectContext];

    NSFetchRequest *reqT= [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];
    // compund predicate
    NSString *targetUrl = [[self oauth] serviceUrl:service forProtocol:@"oauth2"];

    [reqT setPredicate:[NSPredicate predicateWithFormat:@"target == %@ AND type == %@", targetUrl, @"app"]];

    NSError *error = nil;
    NSArray *resUT = [moc executeFetchRequest:reqT error:&error];

    if (!error && resUT && [resUT count]) {
        Tokens *token = [resUT objectAtIndex:0];
        dict = [JWT jsonDecode:[token token]];
    }

    return dict;
}

- (void) requestDone: (RequestData*)result
{
    if ([[result status] integerValue] != 200) {
        NSLog(@"ActionViewController received no data");
    }

    NSLog(@"LIST RESULT COMPLETE, REFRESH TABLE");
    [self filterServices];
}

- (void) filterServices {
    SharedDataStore *ds = [[self oauth] dataStore];
    NSManagedObjectContext *moc = [ds managedObjectContext];

    NSFetchRequest *reqU= [NSFetchRequest fetchRequestWithEntityName:@"UserService"];

    NSError *error = nil;
    NSArray *resUS = [moc executeFetchRequest:reqU error:&error];

    if (!error && resUS) {
        _filteredServices = [NSMutableArray arrayWithCapacity:[resUS count]];

        for (UserService *us in resUS) {
            if ([us rsd] &&
                [[us rsd] length] &&
                [self rsdProvidesProtocols:[JWT jsonDecode:[us rsd]]]) {

                [_filteredServices addObject:us];
            }
        }
    }
    [_tableView reloadData];
}

- (BOOL) rsdProvidesProtocols:(NSDictionary*)myRsd {
    NSArray * protocols;

    if ([self requestData]) {
        protocols = [[self requestData] objectForKey:@"protocols"];
    }

    if (protocols && [protocols count]) {
        NSArray *apis = [[myRsd objectForKey:@"apis"] allKeys];

        for (NSString* prc in protocols) {
            if ([apis indexOfObject:prc] == NSNotFound) {
                return NO;
            }
        }
    }
    else {
        return NO;
    }

    return YES;
}

- (void) serviceAssertionDone: (RequestData*)result
{
    // once we have the user assertion we can request the app token
    NSLog(@"second: get the app assertion");

    if ([[result status] integerValue] == 200) {
        
        // in the extension this point is only reached for app assertions
        [[self oauth] authorizeApp:[[self requestData] objectForKey:@"client_id"]
                         atService:[[result processedResult] objectForKey:@"redirect_uri"]
                      withCallback:@selector(appAssertionDone:)];
    }
    else {
        [self countDownAndComplete];
    }
}

- (void) appAssertionDone: (RequestData*)result
{
    // the app token should be in the local cache
    if ([[result status] integerValue] == 200) {
        NSLog(@"received assertion for %@", [[result input] objectForKey:@"client_id"]);
    }
    else {
        NSLog(@"received assertion for %ld", [[result status] integerValue]);
    }
    [self countDownAndComplete];
}

- (void) countDownAndComplete
{
    NSLog(@"countdown %ld", authAppCountDown);
    if (authAppCountDown > 0) {
        authAppCountDown = authAppCountDown - 1;
    }

    // store the app assertion to the result set

    if (authAppCountDown == 0) {
        NSLog(@"got all assertions");
        [self extensionDone];
    }
}


// Table view Controller

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_filteredServices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserService *us = [_filteredServices objectAtIndex:indexPath.row];

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
