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
}

@synthesize url;
@synthesize token;
@synthesize status;

+ (OAuthRequester*) oauth
{
    return [[OAuthRequester alloc] init];
}

+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl
{
    return [[OAuthRequester alloc] initWithUrl:turl];
}

+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl
                       withToken:(NSString*)tokenString
{
    return [[OAuthRequester alloc] initWithUrl:turl withToken:tokenString];
}

+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl
{
    return [[OAuthRequester alloc] initWithUrlString:turl];
}

+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl
                             withToken:(NSString*)tokenString
{
    return [[OAuthRequester alloc] initWithUrlString:turl
                                           withToken:tokenString];
}

- (OAuthRequester*) init
{
    return self;

    url = nil;
    token = nil;
    jwt = nil;
}

- (OAuthRequester*) initWithUrl:(NSURL*)turl
{
    self = [self init];

    url = turl;

    return self;
}
- (OAuthRequester*) initWithUrl:(NSURL*)turl
                      withToken:(NSString*)tokenString
{
    self = [self initWithUrl:turl];

    token = tokenString;

    jwt = [JWT jwtWithTokenString:token];

    return self;
}
- (OAuthRequester*) initWithUrlString:(NSString*)turl
{
    return [self initWithUrl:[NSURL URLWithString:turl]];
}

- (OAuthRequester*) initWithUrlString:(NSString*)turl
                            withToken:(NSString*)tokenString
{
    return [self initWithUrl:[NSURL URLWithString:turl]
                   withToken:tokenString];
}

- (void) setToken:(NSString *)ttoken
{
    token = ttoken;
    if (jwt != nil) {
        [jwt setToken: [JWT jsonDecode:ttoken]];
    }
    else {
        jwt = [JWT jwtWithTokenString:token];
    }
}

- (void) registerReceiver:(id)receiver
             withSelector:(SEL)selector
{
    callerObject = receiver;
    callerSelector = selector;
}

- (void) GET
{
    NSString *authValue = @"";

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    if (jwt != nil) {
        authValue = [@[@"Bearer", [jwt compact]] componentsJoinedByString:@" "];
        if ([authValue length] > 0) {
            NSLog(@"%@", authValue);
            sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authValue};
        }
    }

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data,
                                                                NSURLResponse *response,
                                                                NSError *error) {

        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            status = [NSNumber numberWithInteger:httpResponse.statusCode];

            NSLog(@"%ld", httpResponse.statusCode);
            if (data && [data length]) {
                NSLog(@"%@", [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding]);
            }
            else {
                NSLog(@"received no data");
            }

            [self completeRequest];
//
//            if (httpResponse.statusCode == 200){
//                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:nil];
//
//                //Process the data
//            }
        }
        
    }];
    [task resume];
}

- (void) postClientCredentials
{
    NSString *authValue = @"";

    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceID = [[device identifierForVendor] UUIDString];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    if (jwt != nil) {
        [jwt setSubject:deviceID];
        [jwt setAudience:[url absoluteString]];
        [jwt setClaim:@"name" withValue:[device name]];


        authValue = [@[@"Bearer", [jwt compact]] componentsJoinedByString:@" "];
        if ([authValue length] > 0) {
            NSLog(@"%@", authValue);
            sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authValue};
        }
    }

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:@"POST"];

    NSDictionary *reqdata = [NSDictionary dictionaryWithObjectsAndKeys:@"client_credentials", @"grant_type", nil];
    NSData *data = [[JWT jsonEncode:reqdata] dataUsingEncoding:NSUTF8StringEncoding];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            status = [NSNumber numberWithInteger:httpResponse.statusCode];

            NSLog(@"%ld", httpResponse.statusCode);
            if (data && [data length]) {
                NSLog(@"%@", [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding]);
            }
            else {
                NSLog(@"received no data");
            }

            [self completeRequest];
        }
        
    }];
    [task resume];
}

- (void) postPassword:(NSString*)password forUser:(NSString*)username
{
    [self completeRequest];
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

@end
