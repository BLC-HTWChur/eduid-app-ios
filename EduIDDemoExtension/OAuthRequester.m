//
//  OAuthRequester.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "OAuthRequester.h"
#import "EduIDDemoExtension/JWT.h"
#import "EduidConfig.h"
#import "UserService.h"
#import "Protocols.h"

@import Foundation;
@import UIKit;

@interface OAuthRequester ()

@end

@implementation OAuthRequester {
    id callerObject;
    SEL callerSelector;
    // JWT *jwt;

    NSInteger targetToken;
    NSString *deviceId;
    NSString *deviceName;

    BOOL retryRequest;
    BOOL invalidDevice;
    
    NSManagedObjectContext *context;
}

@synthesize url;

@synthesize deviceToken;
@synthesize clientToken = _clientToken;
@synthesize accessToken = _accessToken;

@synthesize clientData;
@synthesize accessData;

@synthesize dataStore = _DS;

@synthesize clientId;

NSInteger const DEVICE_TOKEN  = 1;
NSInteger const CLIENT_TOKEN  = 2;
NSInteger const ACCESS_TOKEN  = 3;
NSInteger const SERVICE_TOKEN = 4;

+ (OAuthRequester*) oauth
{
    return [[OAuthRequester alloc] init];
}

+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl
{
    return [[OAuthRequester alloc] initWithUrl:turl];
}

+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl
{
    return [[OAuthRequester alloc] initWithUrlString:turl];
}

- (OAuthRequester*) init
{
    return self;

    url = nil;
    deviceToken = nil;
    _clientToken = nil;
    _accessToken = nil;
    
    clientData = nil;
    accessData = nil;

    retryRequest = NO;
    invalidDevice = NO;
    
    // jwt = nil;
}

- (OAuthRequester*) initWithUrl:(NSURL*)turl
{
    self = [self init];

    url = turl;

    return self;
}

- (OAuthRequester*) initWithUrlString:(NSString*)turl
{
    return [self initWithUrl:[NSURL URLWithString:turl]];
}

- (JWT*) selectToken: (NSString*)token
{
    return [JWT jwtWithTokenString:token];
}

- (BOOL) retry
{
    return retryRequest;
}

- (BOOL) invalid
{
    return invalidDevice;
}

// persistent token management
// Fetch the tokens from the local data store

- (void) setDataStore:(SharedDataStore *)dataStore
{
    _DS = dataStore;
    [self loadClientId];
    [self loadTokens];
}

- (void) loadClientId
{
    if (_DS != nil) {
        NSManagedObjectContext *moc = [_DS managedObjectContext];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EduidConfiguration"];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"cfg_name == %@", @"client_id"]];
        
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];
        if (results) {
            for (EduidConfig *cfg in results) {
                clientId = [cfg cfg_value];
                break;
            }
        }
        
        if (!clientId) {
            UIDevice *device = [UIDevice currentDevice];
            clientId = [[device identifierForVendor] UUIDString];
            EduidConfig *tConfig = [NSEntityDescription insertNewObjectForEntityForName:@"EduidConfiguration"
                                                                 inManagedObjectContext:[_DS managedObjectContext]];
            [tConfig setCfg_name:@"client_id"];
            [tConfig setCfg_value:clientId];
        }
        
        NSLog(@"client id is now %@", clientId);
    }
}

- (NSString*) loadServiceToken: (NSString*) targetUrl
{
    NSString *serviceTokenJSON = nil;

    if (_DS != nil) {
        NSManagedObjectContext *moc = [_DS managedObjectContext];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];

        NSPredicate *stPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
                                                                                       [NSPredicate predicateWithFormat:@"target == %@", targetUrl],
                                                                                       [NSPredicate predicateWithFormat:@"type == %@", @"service"]
                                                                                       ]];
        [request setPredicate:stPredicate];

        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];
        if (results) {
            for (UserService *srv in results)
            {
                serviceTokenJSON = [srv token];
            }
        }
    }

    return serviceTokenJSON;
}

- (void) loadTokens
{
    if (_DS != nil) {
        NSManagedObjectContext *moc = [_DS managedObjectContext];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];

        [request setPredicate:[NSPredicate predicateWithFormat:@"target == %@", @"eduid.htwchur.ch"]];
        
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];

        if (results) {
            for (Tokens *t in results)
            {
                if ([[t subject] isEqual: @"ch.eduid.app"]) {
                    
                    if ([[t type] isEqual: @"client"]) {
                        clientData = t;
                        _clientToken = [t token];
                        NSLog(@"client token: %@", _clientToken);
                    }
                    else if ([[t type] isEqual: @"access"]) {
                        accessData = t;
                        _accessToken = [t token];
                        NSLog(@"access token: %@", _accessToken);
                    }
                }
            }
            [self completeRequest: @0 withResult: @"" withCaller:callerObject withSelector:callerSelector];
        }
    }
}

-(void) storeTokens
{
    if (_DS != nil) [_DS saveContext];
}

// request management

- (void) setClientToken:(NSString *)clientToken
{
    _clientToken = clientToken;
    
    if (_DS != nil) {
        if (clientData == nil) {
            clientData = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                       inManagedObjectContext:[_DS managedObjectContext]];
            [clientData setTarget:@"eduid.htwchur.ch"];
            [clientData setSubject:@"ch.eduid.app"];
            [clientData setType:@"client"];
        }
        
        [clientData setToken:clientToken];
        [_DS saveContext];
    }
}

- (void) setAccessToken:(NSString *)accessToken
{
    _accessToken = accessToken;
    
    if (_DS != nil) {
        if (accessData == nil) {
            accessData = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                       inManagedObjectContext:[_DS managedObjectContext]];
            [accessData setTarget:@"eduid.htwchur.ch"];
            [accessData setSubject:@"ch.eduid.app"];
            [accessData setType:@"access"];
        }
        
        [accessData setToken:accessToken];
        [_DS saveContext];
    }
}

- (JWT*) selectDeviceToken
{
    JWT * tJWT = nil;
    if (deviceToken != nil) {
        tJWT = [self selectToken:deviceToken];
    }

    return tJWT;
}

- (JWT*) selectClientToken
{
    JWT * tJWT = nil;

    if (_clientToken != nil) {
        tJWT = [self selectToken:_clientToken];
    }

    return tJWT;
}

- (JWT*) selectAccessToken
{
    JWT * tJWT = nil;

    if (_accessToken != nil) {
        tJWT = [self selectToken:_accessToken];
    }

    return tJWT;
}

- (void) registerReceiver:(id)receiver
             withSelector:(SEL)selector
{
    callerObject   = receiver;
    callerSelector = selector;
}

- (void) verifyAuthorization
{
    NSLog(@"verify authorization");
    // if we have no client token we try to request one
    if (!_clientToken) {
        // TODO verify that we have network access
        [self postClientCredentials];
    }
    else {
        //
        [self completeRequest: @0 withResult: @"" withCaller:callerObject withSelector:callerSelector];
    }
}


// helper to test the service availability
- (void) GET
{
    NSLog(@"call GET");

    [self      fetchFromUrl: url
                  withToken: nil
         useResponseHandler: @selector(verifyCoreService:withStatus:fromUrl:withCaller:withSelector:)];
}

// send the client_credentials request
- (void) postClientCredentials
{
    NSLog(@"postClientCredentials");

    NSDictionary *reqdata = @{@"grant_type": @"client_credentials"};

    [self           postToUrl: [self extendUrl:@"/token"]
                     withJSON:reqdata
                   withToken:[self prepareToken:DEVICE_TOKEN]
          useResponseHandler:@selector(handleClientAuthorization:withStatus:fromUrl:withCaller:withSelector:)];
}

- (void) postPassword:(NSString*)password forUser:(NSString*)username
{
    NSLog(@"postPassword:forUser:");

    NSDictionary *reqdata = @{
                              @"grant_type": @"password",
                              @"username": username,
                              @"password": password
                              };


    [self           postToUrl: [self extendUrl:@"/token"]
                     withJSON:reqdata
                   withToken:[self prepareToken:CLIENT_TOKEN]
          useResponseHandler:@selector(handleUserAuthorization:withStatus:fromUrl:withCaller:withSelector:)];
}

- (void) getUserProfile {

    NSLog(@"getUserProfile");

    if (_accessToken) {
        [self      fetchFromUrl:[self extendUrl:@"/user-profile"]
                      withToken:[self prepareToken:ACCESS_TOKEN]
             useResponseHandler:@selector(handleUserProfile:withStatus:fromUrl:withCaller:withSelector:)];
    }
    else {
        NSLog(@"No access token present");

        [self completeRequest: @-400 withResult:@"" withCaller:callerObject withSelector:callerSelector];
    }
}

- (void) postProtocolList:(NSArray *)protocolList
{
    NSLog(@"postProtocolList:");

    [self           postToUrl: [self extendUrl:@"/protocol-discovery/protocol"]
                     withJSON: protocolList
                    withToken: [self prepareToken:ACCESS_TOKEN]
           useResponseHandler: @selector(handleProtocolServices:withStatus:fromUrl:withCaller:withSelector:)];
}

- (void) logout{
    // delete accessToken
    NSLog(@"requested logout");
    if (_accessToken &&
        accessData &&
        _DS) {
        // invalidate token at the IDP
        // TODO implement token invalidation based on RFC 7009
        // interestingly, OAuth does not define any token revokation mechnism
        
        // if necessary, revoke ALL access tokens with the resource services.

        [self extendUrl:@"/revoke"];
        
        // authorize itself using JWT-Bearer to revoke
        // send access_token value as token to revoke (will revoke the related refresh token)
        // Alternatively send refresh token to revoke
        
        [[_DS managedObjectContext] deleteObject: accessData];
        [_DS saveContext];

        accessData = nil;
        _accessToken = nil;
        
        [self completeRequest: @0 withResult: @"" withCaller:callerObject withSelector:callerSelector];
    }
    else {
        [self completeRequest: @0 withResult: @"" withCaller:callerObject withSelector:callerSelector];
    }
}

- (void) retrieveServiceAssertion:(NSString*) targetServiceUrl
{
    NSLog(@"retrieveServiceAssertion:");

    // we visit the authorization code endpoint
    // verify if we have an access token!!!
    if (_accessToken &&
        accessData) {
        NSDictionary *reqdata = @{
                                  @"request_type": @"code",
                                  @"redirect_uri": targetServiceUrl,
                                  @"password": clientId
                                  };


        [self           postToUrl: [self extendUrl:@"/authorization"]
                         withJSON: reqdata
                        withToken:[self prepareToken:ACCESS_TOKEN]
               useResponseHandler:@selector(handleServiceAssertion:withStatus:fromUrl:withCaller:withSelector:)];
    }
    else {
        [self completeRequest: @-2 withResult: @"" withCaller:callerObject withSelector:callerSelector];
    }
}

- (void) authorizeWithService: (NSString*)targetServiceUrl
        withAuthorizationCode: (NSString*)assertionToken
                   withCaller: (id)caller
                 withSelector: (SEL)selector
{
    NSLog(@"authorizeWithService:withAuthorizationCode:");

    if (assertionToken && [assertionToken length]) {
    NSDictionary *reqdata = @{
                              @"grant_type": @"urn:ietf:param:oauth:grant-type:jwt-bearer",
                              @"assertion": assertionToken
                              };

    [self           postToUrl: [NSURL URLWithString: targetServiceUrl]
                     withJSON: reqdata
                    withToken: nil
           useResponseHandler:@selector(handleServiceAuthorization:withStatus:fromUrl:withCaller:withSelector:)];
    }
    else {
        [self completeRequest: @-1 withResult: @"" withCaller:caller withSelector:selector];
    }
}

- (void) authorizeApp:(NSString*) appClientId
           atService:(NSString*)  targetServiceUrl
{
    NSLog(@"authorizeApp:atService:");

    // build authorization token

    NSString *serviceToken = [self loadServiceToken:targetServiceUrl];
    if (serviceToken) {
        JWT *webToken = [JWT jwtWithTokenString:serviceToken];

        [webToken setIssuer: clientId];
        [webToken setAudience: targetServiceUrl];
        [webToken setSubject: appClientId];

        NSDictionary *reqdata = @{
                                  @"grant_type": @"authorization_code",
                                  @"authorization_code": webToken,
                                  @"client_id": appClientId
                                  };

        [self         postToUrl: [NSURL URLWithString:targetServiceUrl]
                       withJSON: reqdata
                       withToken: webToken
             useResponseHandler: @selector(handleAppAssertion:withStatus:fromUrl:withCaller:withSelector:)];
    }
    // collect the auth token for the final result
}

- (NSURL*) extendUrl:(NSString*)suffix
{
    NSString *u = [url absoluteString];
    if (suffix && [suffix length]) {
        u = [u stringByAppendingString:suffix];
    }
    return [NSURL URLWithString:u];
}

- (NSString*) serviceUrl:(nonnull NSDictionary*)rsd
             forProtocol:(nonnull NSString*)protocol
{
    return [self serviceUrl:rsd
                forProtocol:protocol
                forEndpoint:nil];
}

- (nullable NSString*) serviceUrl:(nonnull NSDictionary*)rsd
                      forProtocol:(nonnull NSString*)protocol
                      forEndpoint:(nullable NSString*) endpoint
{
    NSString *endpointUrl = nil;

    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"/"];

    NSString *hpLink = [(NSString*)[rsd objectForKey:@"homePageLink"] stringByTrimmingCharactersInSet:cset];
    NSString *enLink = [(NSString*)[rsd objectForKey:@"engineLink"] stringByTrimmingCharactersInSet:cset];

    NSDictionary *apiDict = [(NSDictionary*)[rsd objectForKey:@"apis"] objectForKey:protocol];

    NSString *apLink = [(NSString*)[apiDict objectForKey:@"apiLink"] stringByTrimmingCharactersInSet:cset];

    if (apLink && [apLink length]) {
        if (endpoint && [endpoint length]) {
            endpoint = [endpoint stringByTrimmingCharactersInSet:cset];

            if ([endpoint length]) {

                NSString *epName = [NSString stringWithFormat:@"%@.%@", protocol, endpoint];
                NSString *epLink = [(NSString*)[(NSDictionary*)[rsd objectForKey:@"apis"] objectForKey:epName] stringByTrimmingCharactersInSet:cset];

                if (epLink && [epLink length]) {
                    // the protocol endpoint is registered as a separate sub-service in the RSD.
                    // This is probably the normal case as protocol endpoints are often disconnected in system designs.
                    apLink = epLink;
                }
                else {
                    // the endpoint is a subordinate for the protocol URL.
                    // This would be proper service design, however, many protocols are designed for not having sub protocols.
                    apLink = [NSString stringWithFormat:@"%@/%@", apLink, endpoint];
                }
            }
        }

        if (!([apLink hasPrefix:@"https://"] || [apLink hasPrefix:@"http://"]) && [enLink length]) {
            apLink = [NSString stringWithFormat:@"%@/%@", enLink, apLink];
        }

        if (!([apLink hasPrefix:@"https://"] || [apLink hasPrefix:@"http://"]) && [hpLink length]) {
            apLink = [NSString stringWithFormat:@"%@/%@", hpLink, apLink];
        }
        
        if ([apLink hasPrefix:@"https://"] || [apLink hasPrefix:@"http://"]) {
            endpointUrl = apLink;
        }
    }
    return endpointUrl;
}

- (void)          postToUrl: (NSURL*) requrl
                   withJSON: (id) payload
                  withToken: (JWT*) token
         useResponseHandler: (SEL)responseHandler
{
    [self       postToUrl: requrl
                 withData: [[JWT jsonEncode:payload] dataUsingEncoding:NSUTF8StringEncoding]
                 andToken: token
       useResponseHandler: responseHandler];
}

- (void) postToUrl: (NSURL*) requrl
          withData: (NSData*) data
            andToken: (JWT *)token
   useResponseHandler: (SEL)responseHandler
{
    [self        postToUrl:requrl
                  withData:data
                  andToken:token
        useResponseHandler:responseHandler
                withCaller:callerObject
              withSelector:callerSelector];
}

- (void) postToUrl: (NSURL*) requrl
          withData: (NSData*) data
          andToken: (JWT *)token
useResponseHandler: (SEL)responseHandler
        withCaller: (id)caller
      withSelector: (SEL)myCallerSelector
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    [self setAuthHeader: sessionConfiguration
              withToken: token];

    NSURLSession *session        =  [NSURLSession sessionWithConfiguration:sessionConfiguration];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requrl];

    [request setHTTPMethod: @"POST"];

    [request addValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: data];

    NSURLSessionDataTask *task;

    task = [session dataTaskWithRequest:request
                      completionHandler:[self useResponseHandler:responseHandler
                                                          forUrl:requrl
                                                      withCaller:caller
                                                    withSelector:myCallerSelector]];
    [task resume];
}


- (void)     fetchFromUrl: (NSURL*) requrl
                withToken: (JWT*) token
       useResponseHandler:(nonnull SEL) responseHandler
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [self setAuthHeader: sessionConfiguration
              withToken: token];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLRequest *request = [NSURLRequest requestWithURL:requrl];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:[self useResponseHandler:responseHandler
                                                                                forUrl:requrl
                                                                            withCaller:callerObject
                                                                          withSelector:callerSelector
                                                               ]];
    [task resume];

}

- (void) setAuthHeader:(NSURLSessionConfiguration*)config
             withToken:(JWT*) token
{
    if (token != nil) {
        NSString *authValue = [@[@"Bearer", [token compact]] componentsJoinedByString:@" "];

        if ([authValue length] > 0) {
            NSLog(@"auth header: %@", authValue);
            config.HTTPAdditionalHeaders = @{@"Authorization": authValue};
        }
    }
    else {
        NSLog(@"no jwt present?");
    }
}

- (JWT*) prepareToken:(NSInteger)tokenId
{
    JWT *jwt = nil;

    NSString *issuer = clientId;
    if (!clientId) {
        UIDevice *device = [UIDevice currentDevice];
        deviceId = [[device identifierForVendor] UUIDString];

        [self setClientId:deviceId];
        issuer = clientId;
        // clientId = deviceId;
    }

    switch (tokenId) {
        case DEVICE_TOKEN:
            NSLog(@"use access token");

            jwt = [self prepareDeviceToken];
            break;
        case CLIENT_TOKEN:

            NSLog(@"use access token");
            jwt = [self selectClientToken];
            break;
        case ACCESS_TOKEN:
            NSLog(@"use access token %@", _accessToken);
            jwt = [self selectAccessToken];
            break;
        default:
            break;
    }

    if (jwt != nil) {

        [jwt setIssuer: issuer];
        [jwt setAudience:[url absoluteString]];
    }

    return jwt;
}

- (JWT*) prepareDeviceToken
{
    JWT *dToken = [JWT jwtWithTokenString: deviceToken];

    UIDevice *device = [UIDevice currentDevice];
    deviceId = [[device identifierForVendor] UUIDString];
    deviceName = [device name];

    [self selectDeviceToken];

    if (dToken != nil) {
        NSLog(@"%@", clientId);
        NSLog(@"%@", deviceName);

        [dToken setSubject:clientId];
        [dToken setClaim:@"name"
               withValue:deviceName];
    }

    return dToken;
}

// needs to be a little more complex because the user may change views and thus the callback
- (void) completeRequest: (NSNumber*)reqStatus
              withResult: (NSString*)reqResult
              withCaller: (id) callerObj
            withSelector: (SEL) methSelector
{
    if (callerObject != nil &&
        callerSelector != nil) {

        // NSLog(@"complete authorization");

        IMP imp = [callerObj methodForSelector:methSelector];
        void (*func)(id, SEL, NSNumber*, NSString*) = (void *)imp;

        // because our objects operate on the main thread, we signal them there
        dispatch_async(dispatch_get_main_queue(), ^{
            func(callerObj, methSelector, reqStatus, reqResult);
        });
    }
}

- (void (^)(NSData*, NSURLResponse*, NSError*)) useResponseHandler:(nonnull SEL)responseSelector
                                                            forUrl:(nonnull NSURL*)target
                                                        withCaller:(nonnull id)cbObj
                                                      withSelector: (SEL)cbSelector
{
    // reset the status and the result.
    retryRequest = NO; // reset retry marker

    // get Local references for the call back
    id cObj   = cbObj;
    SEL cMeth = cbSelector;

    return ^(NSData *data,
             NSURLResponse *response,
             NSError *error) {

        NSString *reqResult;
        NSNumber *reqStatus = @-1;

        IMP imp = [self methodForSelector:responseSelector];
        void (*completionHandler)(id, SEL, NSString*, NSNumber*, NSURL*, id, SEL) = (void *)imp;

        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            reqStatus = [NSNumber numberWithInteger:httpResponse.statusCode];
            reqResult = @"";

            if (data &&
                [data length]) {
                reqResult = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
            }
        }

        //
        completionHandler(self, responseSelector, reqResult, reqStatus, target, cObj, cMeth);
    };
}

- (void) verifyCoreService: (NSString*) reqResult
                withStatus: (NSNumber*) reqStatus
                   fromUrl: (NSURL*) targetURL
                withCaller: (id) myCaller
              withSelector: (SEL) mySelector
{
    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleClientAuthorization: (NSString*) reqResult
                        withStatus: (NSNumber*) reqStatus
                           fromUrl: (NSURL*) targetURL
                        withCaller: (id) myCaller
                      withSelector: (SEL) mySelector
{
    if ([reqStatus integerValue] == 200) {
        [self setClientToken:reqResult];
    }
    else {
        NSLog(@"different status %@", reqStatus);
        NSLog(@"service message: %@", reqResult);
    }

    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleUserAuthorization: (NSString*) reqResult
                      withStatus: (NSNumber*) reqStatus
                         fromUrl: (NSURL*) targetURL
                      withCaller: (id) myCaller
                    withSelector: (SEL) mySelector
{
    if ([reqStatus integerValue] == 200) {
        [self setAccessToken:reqResult];
    }
    else {
        NSLog(@"different status %@", reqStatus);
        NSLog(@"service message: %@", reqResult);
    }
    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleUserProfile: (NSString*) reqResult
                withStatus: (NSNumber*) reqStatus
                   fromUrl: (NSURL*) targetURL
                withCaller: (id) myCaller
              withSelector: (SEL) mySelector
{
    [self completeRequest:reqStatus withResult: reqResult withCaller:myCaller withSelector:mySelector];
}

- (void) handleServiceAssertion: (NSString*) reqResult
                     withStatus: (NSNumber*) reqStatus
                        fromUrl: (NSURL*) targetURL
                     withCaller: (id) myCaller
                   withSelector: (SEL) mySelector
{
    // we immediately pass on to service authorization
    if ([reqStatus integerValue] == 200) {
        NSDictionary *dict = [JWT jsonDecode:reqResult];

        NSString *code      = (NSString*)[dict objectForKey:@"code"];
        NSString *redirectUri = (NSString*)[dict objectForKey:@"redirect_uri"];

        [self authorizeWithService:redirectUri
             withAuthorizationCode:code
                        withCaller:myCaller
                      withSelector:mySelector];
    }
    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleServiceAuthorization: (NSString*) reqResult
                         withStatus: (NSNumber*) reqStatus
                            fromUrl: (NSURL*) targetURL
                         withCaller: (id) myCaller
                       withSelector: (SEL) mySelector
{
    if ([reqStatus integerValue] == 200) {
        // store token into the token database
        Tokens *serviceToken = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                             inManagedObjectContext:[_DS managedObjectContext]];
        [serviceToken setTarget:  [targetURL absoluteString]];     // store the endpoint
        [serviceToken setSubject: @"ch.eduid.app"];                // for myself
        [serviceToken setType:    @"service"];
        [serviceToken setToken:   reqResult];                      // store the token
        
        [self storeTokens];
    }
    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleAppAssertion: (NSString*) reqResult
                 withStatus: (NSNumber*) reqStatus
                    fromUrl: (NSURL*) targetURL
                 withCaller: (id) myCaller
               withSelector: (SEL) mySelector
{
    if ([reqStatus integerValue] == 200) {
        // store app assertion so we can kill it later
        Tokens *appToken = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                         inManagedObjectContext:[_DS managedObjectContext]];
        [appToken setTarget:  [targetURL absoluteString]];     // store the endpoint
        [appToken setSubject: @"ch.eduid.app"];                // for myself
        [appToken setType:    @"app"];
        [appToken setToken:   reqResult];                      // store the token
        
        [self storeTokens];
    }

    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) handleProtocolServices: (NSString*) reqResult
                     withStatus: (NSNumber*) reqStatus
                        fromUrl: (NSURL*) targetURL
                     withCaller: (id) myCaller
                   withSelector: (SEL) mySelector
{

    if ([reqStatus integerValue] == 200) {
        // we expect a list of services
        NSArray *services = [JWT jsonDecode:reqResult];

        UserService *us;
        Protocols   *proto;
        NSString    *hpLink;

        for (NSDictionary *srv in services) {
            hpLink = [srv objectForKey:@"homePageLink"];

            if (hpLink != nil) {
                // delete all references to this object
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"UserService"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"baseurl == %@", hpLink]];

                NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
                NSError *deleteError = nil;

                [[_DS persistentStoreCoordinator] executeRequest:delete
                                                     withContext:[_DS managedObjectContext]
                                                           error:&deleteError];

                [self storeTokens];
                // delete all references to this service's protocols


                request = [[NSFetchRequest alloc] initWithEntityName:@"Protocols"];

                [request setPredicate:[NSPredicate predicateWithFormat:@"baseurl == %@", hpLink]];
                delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];

                deleteError = nil;
                [[_DS persistentStoreCoordinator] executeRequest:delete
                                                     withContext:[_DS managedObjectContext]
                                                           error:&deleteError];

                // reset the managed object context.
                [[_DS managedObjectContext] reset]; // ensure that the objects are really gone!

                // now insert the new object

                us = [NSEntityDescription insertNewObjectForEntityForName:@"UserService"
                                                   inManagedObjectContext:[_DS managedObjectContext]];
                
                [us setName:    [srv objectForKey:@"engineName"]];
                [us setRsd:     [JWT jsonEncode:srv]];
                [us setBaseurl: hpLink];

                [us setToken_target: [self serviceUrl:srv
                                          forProtocol:@"org.ietf.oauth2"
                                          forEndpoint:@"token"]];

                [self storeTokens]; // CHECK move outside the loop

                NSDictionary *apis = [srv objectForKey:@"apis"];

                for (NSString *protocol in [apis allKeys]) {
                    proto = [NSEntityDescription insertNewObjectForEntityForName:@"Protocols"
                                                          inManagedObjectContext:[_DS managedObjectContext]];

                    [proto setBaseurl: hpLink];
                    [proto setProtocol_id: protocol];
                    [self storeTokens]; // CHECK move outside the loop
                }

            }

        }
        [self storeTokens];
    }

    [self completeRequest:reqStatus withResult: @"" withCaller:myCaller withSelector:mySelector];
}

- (void) invalidateToken:(NSInteger)tokenType
{
    retryRequest = YES;
    switch (tokenType) {
        case DEVICE_TOKEN:
            // TODO: expose this information so we can display error messages
            // NSLog(@"FATAL: The Version has been invalidated!");
            retryRequest = NO;
            invalidDevice = YES;
            break;
        case CLIENT_TOKEN:
            // NSLog(@"invalidate client token");
            if (clientData) {
                [[_DS managedObjectContext] deleteObject: clientData];
            }
            clientData = nil;
            _clientToken = nil;

            // if the client token is invalid, then the access token is too
            if (accessData) {
                [[_DS managedObjectContext] deleteObject: accessData];
            }

            accessData = nil;
            _accessToken = nil;
            
            // complete the old request before starting a new one

            [self completeRequest:@403 withResult: @"" withCaller:callerObject withSelector:callerSelector];

            // try to get a new token
            [self postClientCredentials];
            break;
        case ACCESS_TOKEN:
            if (accessData) {
                // NSLog(@"invalidate access token");
                [[_DS managedObjectContext] deleteObject: accessData];
            }
            accessData = nil;
            _accessToken = nil;
            break;
        default:
            break;
    }
    [_DS saveContext];
}

@end
