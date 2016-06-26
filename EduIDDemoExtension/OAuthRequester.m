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

@import Foundation;
@import UIKit;

@interface OAuthRequester ()

@property (retain, nonatomic) NSString *clientId;
@property (retain) NSURL *nextUrl;

@end

@implementation OAuthRequester {
    id callerObject;
    SEL callerSelector;
    JWT *jwt;

    NSInteger targetToken;
    NSString *deviceId;
    NSString *deviceName;

    BOOL retryRequest;
    BOOL invalidDevice;
    
    NSManagedObjectContext *context;
}

@synthesize url;
@synthesize nextUrl;

@synthesize deviceToken;
@synthesize clientToken = _clientToken;
@synthesize accessToken = _accessToken;

@synthesize clientData;
@synthesize accessData;

@synthesize status;
@synthesize result;

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
    
    jwt = nil;
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

- (void) selectToken: (NSString*)token
{
    if (jwt != nil) {
        [jwt resetWithTokenString:token];
    }
    else {
        jwt = [JWT jwtWithTokenString:token];
    }
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

- (void) loadTokens
{
    if (_DS != nil) {
        NSManagedObjectContext *moc = [_DS managedObjectContext];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];
        
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];
        if (results) {
            for (Tokens *t in results)
            {
                if ([[t subject] isEqual: @"ch.eduid.app"] &&
                    [[t target] isEqual: @"eduid.htwchur.ch"]) {
                    
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
            [self completeRequest];
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

- (void) selectDeviceToken
{
    if (deviceToken != nil) {
        [self selectToken:deviceToken];
    }
    else if (jwt != nil) {
        [jwt hardReset];
    }
}

- (void) selectClientToken
{
    if (_clientToken != nil) {
        [self selectToken:_clientToken];
    }
    else if (jwt != nil) {
        [jwt hardReset];
    }
}

- (void) selectUserToken
{
    if (_accessToken != nil) {
        [self selectToken:_accessToken];
    }
    else if (jwt != nil) {
        [jwt hardReset];
    }
}

- (void) registerReceiver:(id)receiver
             withSelector:(SEL)selector
{
    callerObject   = receiver;
    callerSelector = selector;
}

// helper to test the service availability
- (void) GET
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    [self setAuthHeader:sessionConfiguration];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:[self getResponseCallback]];
    [task resume];
}

// send the client_credentials request
- (void) postClientCredentials
{
    NSLog(@"client registration");
    NSString *u = [url absoluteString];
    u= [u stringByAppendingString:@"/token"];
    nextUrl = [NSURL URLWithString:u];
    
    NSDictionary *reqdata = @{@"grant_type": @"client_credentials"};

    [self postJSONData:reqdata forTokenType:CLIENT_TOKEN];
}

- (void) postPassword:(NSString*)password forUser:(NSString*)username
{
    NSLog(@"authenticate");
    NSString *u = [url absoluteString];
    u= [u stringByAppendingString:@"/token"];
    nextUrl = [NSURL URLWithString:u];
    
    NSDictionary *reqdata = @{
                              @"grant_type": @"password",
                              @"username": username,
                              @"password": password
                              };

    [self postJSONData:reqdata forTokenType:ACCESS_TOKEN];
}

- (void) getUserProfile {
    if (_accessToken) {
        NSString *u = [url absoluteString];
        u= [u stringByAppendingString:@"/user-profile"];
        
        nextUrl = [NSURL URLWithString:u];
        [self fetchDataWithToken:ACCESS_TOKEN];
    }
    else {
        NSLog(@"No access token present");
        
        status = @-400;
        [self completeRequest];
    }
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
        
        NSString *u = [url absoluteString];
        u= [u stringByAppendingString:@"/revoke"];
        nextUrl = [NSURL URLWithString:u];
        
        // authorize itself using JWT-Bearer to revoke
        // send access_token value as token to revoke (will revoke the related refresh token)
        // Alternatively send refresh token to revoke
        
        [[_DS managedObjectContext] deleteObject: accessData];
        [_DS saveContext];

        accessData = nil;
        _accessToken = nil;
        
        [self completeRequest];
    }
    else {
        [self completeRequest];
    }
}

- (void) authorize
{
    NSLog(@"verify authorization");
    // if we have no client token we try to request one
    if (!_clientToken) {
        // TODO verify that we have network access
        [self postClientCredentials];
    }
    else {
        [self completeRequest];
    }
}

- (void) postJSONData: (NSDictionary*)dict forTokenType:(NSInteger)tokenType
{

    [self prepareToken:tokenType - 1];

    NSData *data = [[JWT jsonEncode:dict] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    [self setAuthHeader:sessionConfiguration];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nextUrl];

    [request setHTTPMethod:@"POST"];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:[self getResponseCallbackForToken:tokenType]];
    [task resume];
}

- (void) fetchDataWithToken:(NSInteger)tokenType
{
    [self prepareToken:tokenType];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [self setAuthHeader:sessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLRequest *request = [NSURLRequest requestWithURL:nextUrl];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:[self getResponseCallback]];
    [task resume];

}

- (void) completeRequest {
    if (callerObject != nil &&
        callerSelector != nil) {

        // NSLog(@"complete authorization");

        IMP imp = [callerObject methodForSelector:callerSelector];
        void (*func)(id, SEL) = (void *)imp;
        
        // because our objects operate on the main thread, we signal them there
        dispatch_async(dispatch_get_main_queue(), ^{
            func(callerObject, callerSelector);
        });
    }
}

- (void) setAuthHeader:(NSURLSessionConfiguration*)config
{
    if (jwt != nil) {
        NSString *authValue = [@[@"Bearer", [jwt compact]] componentsJoinedByString:@" "];

        if ([authValue length] > 0) {
            config.HTTPAdditionalHeaders = @{@"Authorization": authValue};
        }
    }
    else {
        NSLog(@"no jwt present?");
    }
}

- (void) prepareToken:(NSInteger)tokenId
{
    UIDevice *device = [UIDevice currentDevice];
    deviceId = [[device identifierForVendor] UUIDString];

    NSString *issuer = deviceId;

    switch (tokenId) {
        case DEVICE_TOKEN:
            [self prepareDeviceToken];
            if (jwt) {
                issuer = [[jwt token] objectForKey:@"client_id"];
            }
            break;
        case CLIENT_TOKEN:
            [self selectClientToken];
            break;
        case ACCESS_TOKEN:
            [self selectUserToken];
            break;
        default:
            break;
    }

    if (jwt != nil) {

        [jwt setIssuer: issuer];
        [jwt setAudience:[url absoluteString]];
    }
}

- (void) prepareDeviceToken
{
    UIDevice *device = [UIDevice currentDevice];
    deviceId = [[device identifierForVendor] UUIDString];
    deviceName = [device name];

    [self selectDeviceToken];

    if (jwt != nil) {
        NSLog(@"%@", clientId);
        NSLog(@"%@", deviceName);

        [jwt setSubject:clientId];
        [jwt setClaim:@"name"
            withValue:deviceName];
    }
}

// call back factory
- (void (^)(NSData*, NSURLResponse*, NSError*)) getResponseCallback
{
    return [self getResponseCallbackForToken:0];
}

- (void (^)(NSData*, NSURLResponse*, NSError*)) getResponseCallbackForToken:(NSInteger)tokenId
{
    // reset the status and the result.
    result = @"";
    status = [NSNumber numberWithInteger:-1];
    retryRequest = NO; // reset retry marker

    return ^(NSData *data,
             NSURLResponse *response,
             NSError *error) {

        if (!error) {

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            status = [NSNumber numberWithInteger:httpResponse.statusCode];

            if (data &&
                [data length]) {
                result = [[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding];
                if ([status isEqual: @200]) {
                    NSLog(@"status %ld", tokenId);
                    switch (tokenId) {
                        case CLIENT_TOKEN:
                            NSLog(@"assign client token %@", result);
                            [self setClientToken:result];
                            break;
                        case ACCESS_TOKEN:
                            NSLog(@"assign access token %@", result);
                            [self setAccessToken:result];
                            break;
                        default:
                            break;
                    }
                }
                else if ([status isEqual: @400] &&
                    [result isEqual: @"malformed header detected!"]) {
                    // this means our token has expired
                    if (tokenId > 2) {
                        NSLog(@"huston, we have a problem. invalidate token");
                        [self invalidateToken: (tokenId - 1)];
                    }
                    else {
                        NSLog(@"server problem ");
                    }
                }
                else {
                    NSLog(@"different status %@", status);
                    NSLog(@"service message: %@", result);
                }
            }
        }
        [self completeRequest];
    };
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
                [_DS saveContext];
            }
            clientData = nil;
            _clientToken = nil;
            // complete the old request before starting a new one
            [self completeRequest];

            // try to get a new token
            [self postClientCredentials];
            break;
        case ACCESS_TOKEN:
            if (accessData) {
                // NSLog(@"invalidate access token");
                [[_DS managedObjectContext] deleteObject: accessData];
                [_DS saveContext];
            }
            accessData = nil;
            _accessToken = nil;
            break;
        default:
            break;
    }
}

@end
