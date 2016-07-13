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
#import "RequestData.h"

@import Foundation;
@import UIKit;

@interface OAuthRequester ()

@property (nonatomic) RequestData *requestData;

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

        [moc reset];
        moc.retainsRegisteredObjects = NO; // ensure that nothing is reused
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EduidConfiguration"];

        // the next statement forces CoreData to load from the store.
        request.returnsObjectsAsFaults = NO;

        [request setPredicate:[NSPredicate predicateWithFormat:@"cfg_name == %@", @"client_id"]];
        
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];
        if (results && [results count]) {
            NSLog(@"use cached client id (got %ld config)", [results count]);
            for (EduidConfig *cfg in results) {
                clientId = [cfg cfg_value];
                break;
            }
            NSLog(@"cached client id is %@", clientId);
        }
        else {
            if (error) {
                NSLog(@"loading triggered error: %@", error);
            }
            else if (results){
                NSLog(@"no errors detected, just no results. Am I running the first time?");
            }
            else {
                NSLog(@"results nil? a race problem? ");
            }
        }

        if (!clientId) {
            NSLog(@"use real client id");
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

            RequestData *res = [_requestData cloneRequest];

            [res setType: @"load_tokens"];
            [res complete:@0];
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
{
    _requestData = [RequestData requestWithObject:receiver];
}

- (void) registerReceiver:(id)receiver withCallback:(SEL)callback
{
    _requestData = [RequestData requestWithObject:receiver withCallback:callback];
}


- (void) verifyAuthorization:(SEL)callback
{
    NSLog(@"verify authorization");
    // if we have no client token we try to request one
    if (!_clientToken) {
        // TODO verify that we have network access

        [self postClientCredentials:callback];
    }
    else {

        RequestData *res = [_requestData cloneRequest:callback];

        [res setType: @"verify_authorization"];

        [res complete:@0];
    }
}


// helper to test the service availability
- (void) GET
{
    NSLog(@"call GET");

    RequestData *res = [_requestData cloneRequest];
    RequestData *req= [res subRequestFor:self
                            withCallback:@selector(verifyCoreService:)];
    [req setUrl:[url absoluteString]];

    [self      fetch: req
           withToken: nil];
}

// send the client_credentials request
- (void) postClientCredentials:(SEL)callback
{
    NSLog(@"postClientCredentials");

    RequestData *res = [_requestData cloneRequest:callback];

    [self postClientCredentialsRequest:res];
}

- (void) postClientCredentialsRequest:(RequestData*)resObj
{
    RequestData *req = [resObj subRequestFor:self
                                withCallback:@selector(handleClientAuthorization:)];
 
    [req setType: @"post_user_password"];
    [req setStatus:@-400];
    [req setUrl:[self extendUrl:@"/token"]];
    
    [req setInput: @{@"grant_type": @"client_credentials"}];
    
    [self    post: req
        withToken:[self prepareToken:DEVICE_TOKEN]];
}

- (void) postPassword:(NSString*)password
              forUser:(NSString*)username
         withCallback:(SEL)callback
{
    NSLog(@"postPassword:forUser:");

    RequestData *res = [_requestData cloneRequest:callback];

    [res setType: @"post_user_password"];
    [res setStatus:@-400];
    [res setUrl:[self extendUrl:@"/token"]];

    RequestData *reqData = [res subRequestFor:self
                                 withCallback:@selector(handleUserAuthorization:)];

    [reqData setInput: @{
                     @"grant_type": @"password",
                     @"username": username,
                     @"password": password
                     }];
    
    if (_clientToken) {

        [self   post:reqData
           withToken:[self prepareToken:CLIENT_TOKEN]];
    }
    else {
        // need to get the client token first
        
        RequestData *subRequest = [reqData subRequestFor:self
                                            withCallback:@selector(handleClientAuthForUserAuth:)];
        
        [self postClientCredentialsRequest:subRequest];
    }
}

- (void) getUserProfile:(SEL)callback
{
    NSLog(@"getUserProfile");

    RequestData *res = [_requestData cloneRequest:callback];

    [res setType: @"get_user_profile"];
    [res setStatus:@-400];
    [res setUrl:[self extendUrl:@"/user-profile"]];

    if (_accessToken) {
        RequestData *fetchReq = [res subRequestFor:self
                                   withCallback:@selector(handleUserProfile:)];


        [self      fetch: fetchReq
               withToken:[self prepareToken:ACCESS_TOKEN]];
    }
    else {
        NSLog(@"No access token present");

        [res complete];
    }
}

- (void) postProtocolList:(NSArray *)protocolList withCallback:(SEL)callback
{
    NSLog(@"postProtocolList:");

    RequestData *res = [_requestData cloneRequest:callback];
    RequestData *reqData = [res subRequestFor:self
                                 withCallback:@selector(handleProtocolServices:)];

    [reqData setType: @"get_user_profile"];
    [reqData setStatus:@-400];
    [reqData setUrl:[self extendUrl:@"/protocol-discovery/protocol"]];
    [reqData setInput: protocolList];

    [self   post: reqData
       withToken:[self prepareToken:ACCESS_TOKEN]];
}

- (void) logout:(SEL)callback
{
    // delete accessToken
    NSLog(@"requested logout");

    RequestData *res = [_requestData cloneRequest:callback];

    [res setType: @"logout"];
    [res setStatus:@0];
    [res setUrl:[self extendUrl:@"/revoke"]];

    if (_accessToken &&
        accessData &&
        _DS) {
        // invalidate token at the IDP
        // TODO implement token invalidation based on RFC 7009
        // interestingly, OAuth does not define any token revokation mechnism
        
        // if necessary, revoke ALL access tokens with the resource services.

        // authorize itself using JWT-Bearer to revoke
        // send access_token value as token to revoke (will revoke the related refresh token)
        // Alternatively send refresh token to revoke
        
        [[_DS managedObjectContext] deleteObject: accessData];
        [_DS saveContext];

        accessData = nil;
        _accessToken = nil;

    }
    [res complete];
}

- (void) retrieveServiceAssertion:(NSString*)targetServiceUrl
                     withCallback:(SEL)callback
{
    NSLog(@"retrieveServiceAssertion:");

    // we visit the authorization code endpoint
    // verify if we have an access token!!!

    RequestData *res = [_requestData cloneRequest:callback];
    [res setType: @"service_assertion"];
    [res setUrl: [self extendUrl: @"/authorization"]];

    RequestData *reqData = [res subRequestFor:self
                                 withCallback:@selector(handleServiceAssertion:)];
    [reqData setStatus:@-400];
    if (_accessToken &&
        accessData) {
        [reqData setInput: @{
                             @"request_type": @"code",
                             @"redirect_uri": targetServiceUrl,
                             @"client_id": clientId
                             }];

        [self   post: reqData
           withToken:[self prepareToken:ACCESS_TOKEN]];
    }
    else {
        NSLog(@"no access token stop assertion request");
        [res complete];
    }
}

- (void) forwardAssertion: (RequestData*)targetReq
    withAuthorizationCode:(NSString*)assertionToken
{
    [targetReq setType:@"service_authorization"];

    RequestData *reqData = [targetReq subRequestFor:self
                                       withCallback:@selector(handleServiceAuthorization:)];

    [reqData setStatus:@-400];

    if (assertionToken && [assertionToken length]) {
        [reqData setInput: @{
                         @"grant_type": @"urn:ietf:param:oauth:grant-type:jwt-bearer",
                         @"assertion": assertionToken
                         }];

        [self   post:reqData
           withToken: nil];
    }
    else {
        NSLog(@"missing assertion token");
        [targetReq complete];
    }
}

- (void) authorizeApp:(NSString*) appClientId
           atService:(NSString*)  targetServiceUrl
         withCallback:(SEL)callback
{
    NSLog(@"authorizeApp:atService:");
    NSLog(@"app: %@", appClientId);
    NSLog(@"service: %@", targetServiceUrl);

    RequestData *rData = [_requestData cloneRequest:callback];

    [rData setType: @"app_authorization"];
    [rData setUrl:targetServiceUrl];

    RequestData *reqData = [rData subRequestFor:self
                                   withCallback:@selector(handleAppAssertion:)];

    [reqData setStatus:@-400];

    // build authorization token

    NSLog(@"service URL: %@", targetServiceUrl);

    NSString *serviceToken = [self loadServiceToken:targetServiceUrl];
    if (serviceToken) {
        NSLog(@"service Token: %ld %@", [serviceToken length], serviceToken);
        JWT *webToken = [JWT jwtWithTokenString:serviceToken];

        // create the authorization token for myself
        [webToken setIssuer:clientId];
        [webToken setAudience:targetServiceUrl];
        [webToken setSubject:appClientId];

        // create a second token for the app
        JWT *authCode = [JWT jwtWithTokenString:serviceToken];

        [authCode setIssuer:clientId ];
        [authCode setSubject:appClientId];
        [authCode setAudience:targetServiceUrl];

        [reqData setInput: @{
                             @"grant_type": @"authorization_code",
                             @"authorization_code": [authCode compact],
                             @"client_id": appClientId
                             }];
        [self     post:reqData
             withToken:webToken];
    }
    else {
        NSLog(@"service token missing");
        [rData setStatus: @-1];
        [rData complete];
    }
    // collect the auth token for the final result
}

- (NSString*) extendUrl:(NSString*)suffix
{
    NSString *u = [url absoluteString];

    if (suffix && [suffix length]) {
        u = [u stringByAppendingString:suffix];
    }

    return u;
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


- (void)    post: (RequestData*) requestData
       withToken: (JWT*) token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[requestData processedUrl]];

    [request setHTTPMethod: @"POST"];
    [request addValue: @"application/json" forHTTPHeaderField:@"Content-Type"];

    NSLog(@"post body %@", [requestData input]);
    [request setHTTPBody: [requestData inputData]];

    [self executeHttpRequest:request
             withRequestData:requestData
                   withToken:token];
}

- (void) fetch:(RequestData*)requestData
     withToken:(JWT*)token
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[requestData processedUrl]];

    [self executeHttpRequest:urlRequest
             withRequestData:requestData
                   withToken:token];
}

- (void) executeHttpRequest:(NSURLRequest*)urlRequest
            withRequestData:(RequestData*)requestData
                  withToken:(JWT*)token
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    [self setAuthHeader: sessionConfiguration
              withToken: token];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                            completionHandler:[self useRequestData:requestData]];
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
            NSLog(@"use device token");

            jwt = [self prepareDeviceToken];
            break;
        case CLIENT_TOKEN:
 
            NSLog(@"use client token");
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

- (void (^)(NSData*, NSURLResponse*, NSError*)) useRequestData:(nonnull RequestData*)requestData
{
    // reset the status and the result.

    // get Local references for the call back
    RequestData *cResult = requestData;

    return ^(NSData *data,
             NSURLResponse *response,
             NSError *error) {

        [cResult setStatus:@-1];

        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            [cResult setStatus:[NSNumber numberWithInteger:httpResponse.statusCode]];

            if (data &&
                [data length]) {
                [cResult setResult:[[NSString alloc] initWithData:data
                                                         encoding:NSUTF8StringEncoding]];
            }

            if (httpResponse.statusCode == 500) {
                NSLog(@"Server Error for %@", [cResult url]);
            }
        }
        else {
            NSLog(@"error!? %@", error);
        }

        [cResult complete];
    };
}

- (void) verifyCoreService: (RequestData*)reqResult
{
    [[reqResult parent] complete];
}

- (void) handleClientAuthorization: (RequestData*)reqResult
{
    NSLog(@"client authorization done");
    if ([[reqResult status] integerValue] == 200) {
        [self setClientToken:[reqResult result]];
    }
    
    NSLog(@"request status %@", [reqResult status]);
    NSLog(@"input %@", [reqResult input]);
    
    [[reqResult parent] complete];
}

- (void) handleClientAuthForUserAuth: (RequestData*)reqResult
{
    NSLog(@"missing client auth done");
    if ([[reqResult status] integerValue] == 200) {
        NSLog(@"client auth OK");
        
        [self setClientToken:[reqResult result]];
        
        NSLog(@"forward authorization for %@", [[reqResult parent] input]);
        [self   post:[reqResult parent]
           withToken:[self prepareToken:CLIENT_TOKEN]];
    }
    else {
        NSLog(@"errror status %@", [reqResult status]);
        NSLog(@"input %@", [reqResult input]);
        NSLog(@"url   %@", [reqResult url]);
        [[[reqResult parent] parent] complete];
    }
}

- (void) handleUserAuthorization: (RequestData*) reqResult
{
    NSLog(@"user authorization done");
    if ([[reqResult status] integerValue] == 200) {
        [self setAccessToken:[reqResult result]];
    }
    else {
        NSLog(@"error status %@", [reqResult status]);
    }
    
    [[reqResult parent] complete];
}

- (void) handleUserProfile: (RequestData*)reqResult
{
    NSLog(@"handle user profile");
    [[reqResult parent] complete];
}

- (void) handleServiceAssertion: (RequestData*) reqResult
{

    if ([[reqResult status] integerValue] == 200) {
        NSDictionary *dict = [reqResult processedResult];

        NSString *code        = (NSString*)[dict objectForKey:@"code"];
        NSString *redirectUri = (NSString*)[dict objectForKey:@"redirect_uri"];

        // hand down
        RequestData *useAssertionReq = [reqResult cloneRequest];
        [useAssertionReq setUrl:redirectUri];

        // authorize with service
        [[reqResult parent] setUrl:redirectUri];

        NSLog(@"code %@", code);
        NSLog(@"uri %@", redirectUri);

        [self      forwardAssertion:[reqResult parent]
              withAuthorizationCode:code];
    }
    else {
        NSLog(@"assertion request failed %@",[reqResult status]);
        
        [[reqResult parent] complete];
    }
}

- (void) handleServiceAuthorization: (RequestData*) reqResult
{
    if ([[reqResult status] integerValue] == 200) {
        Tokens *serviceToken = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                             inManagedObjectContext:[_DS managedObjectContext]];
        [serviceToken setTarget:  [reqResult url]];     // store the endpoint
        [serviceToken setSubject: @"ch.eduid.app"];     // for myself
        [serviceToken setType:    @"service"];
        [serviceToken setToken:   [reqResult result]];  // remember the token

        [self storeTokens];
    }

    [[reqResult parent] complete];
}


- (void) handleAppAssertion: (RequestData*) reqResult
{
    if ([[reqResult status] integerValue] == 200) {
        // store app assertion so we can kill it later
        Tokens *appToken = [NSEntityDescription insertNewObjectForEntityForName:@"Tokens"
                                                         inManagedObjectContext:[_DS managedObjectContext]];

        NSDictionary *input = [reqResult input];
        NSString *appClientId = [input objectForKey:@"client_id"];

        // we should get the client id
        [appToken setTarget:  [reqResult url]];     // store the endpoint
        [appToken setSubject: appClientId];         // for myself: FIXME: FOR THE APP
                                                    // FIXME: relate app clientIds to app ids
        [appToken setType:    @"app"];
        [appToken setToken:   [reqResult result]];  // store the token

        [self storeTokens];
    }
    
    [[reqResult parent] complete];
}

- (void) handleProtocolServices: (RequestData*) reqResult
{
    if ([[reqResult status] integerValue] == 200) {

        // we expect a list of services
        NSArray *services = [reqResult processedResult];

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

    [[reqResult parent] complete];
}

- (void) invalidateToken:(NSInteger)tokenType
             withRequest: (RequestData*)request
{
    switch (tokenType) {
        case DEVICE_TOKEN:
            // TODO: expose this information so we can display error messages
            // NSLog(@"FATAL: The Version has been invalidated!");
            [request invalidate];
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
            [request retry];
            [request complete:@403 withResult:@""];

            // try to get a new token
            // reuse the callback
            [self postClientCredentials:nil];
            break;
        case ACCESS_TOKEN:
            if (accessData) {
                // NSLog(@"invalidate access token");
                [[_DS managedObjectContext] deleteObject: accessData];
            }
            accessData = nil;
            _accessToken = nil;
            [request retry];
            break;
        default:
            [request retry];
            break;
    }
    [_DS saveContext];
}

@end
