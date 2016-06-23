//
//  OAuthRequester.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "OAuthRequester.h"
#import "EduIDDemoExtension/JWT.h"

@import Foundation;
@import UIKit;

@implementation OAuthRequester {
    id callerObject;
    SEL callerSelector;
    JWT *jwt;

    NSInteger targetToken;
    NSString *deviceId;
    NSString *deviceName;
    NSString *clientId;
    
    NSManagedObjectContext *context;
}

@synthesize url;
@synthesize deviceToken;
@synthesize clientToken = _clientToken;
@synthesize accessToken = _accessToken;

@synthesize clientData;
@synthesize accessData;

@synthesize status;
@synthesize result;

@synthesize dataStore = _DS;

NSInteger const DEVICE_TOKEN = 1;
NSInteger const CLIENT_TOKEN = 2;
NSInteger const ACCESS_TOKEN = 3;

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

// persistent token management
// Fetch the tokens from the local data store

- (void) setDataStore:(SharedDataStore *)dataStore
{
    _DS = dataStore;
    [self loadTokens];
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
    [self prepareDeviceToken];

    NSDictionary *reqdata = @{@"grant_type": @"client_credentials"};


    [self postJSONData:reqdata forTokenType:CLIENT_TOKEN];
}

- (void) postPassword:(NSString*)password forUser:(NSString*)username
{
    [self prepareToken:CLIENT_TOKEN];
    NSDictionary *reqdata = @{
                              @"grant_type": @"password",
                              @"username": username,
                              @"password": password
                              };

    [self postJSONData:reqdata forTokenType:ACCESS_TOKEN];
}

- (void) postJSONData: (NSDictionary*)dict forTokenType:(NSInteger)tokenType
{
    NSData *data = [[JWT jsonEncode:dict] dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    [self setAuthHeader:sessionConfiguration];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:@"POST"];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:[self getResponseCallbackForToken:tokenType]];
    [task resume];
}


- (void) completeRequest {
    if (callerObject != nil &&
        callerSelector != nil) {

        // NSLog(@"complete authorization");

        IMP imp = [callerObject methodForSelector:callerSelector];
        void (*func)(id, SEL) = (void *)imp;
        func(callerObject, callerSelector);
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

    switch (tokenId) {
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

        [jwt setIssuer: deviceId];
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
        NSLog(@"%@", deviceId);
        NSLog(@"%@", deviceName);

        [jwt setSubject:deviceId];
        [jwt setAudience:[url absoluteString]];

        clientId = [[jwt token] objectForKey:@"client_id"];

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

    return ^(NSData *data,
             NSURLResponse *response,
             NSError *error) {

        if (!error) {

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            status = [NSNumber numberWithInteger:httpResponse.statusCode];
            NSLog(@"status %ld", [status integerValue]);

            if (data &&
                [data length]) {
                result = [[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding];
                NSLog(@"result %@", result);

                if ([status isEqual: @200]) {
                    NSLog(@"status %ld", tokenId);
                    switch (tokenId) {
                        case CLIENT_TOKEN:
                            NSLog(@"assign client token");
                            [self setClientToken:result];
                            break;
                        case ACCESS_TOKEN:
                            NSLog(@"assign access token");
                            [self setAccessToken:result];
                            break;
                        default:
                            break;
                    }
                }

            }
        }
        [self completeRequest];
    };
}

@end
