//
//  OAuthRequester.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAuthRequester : NSObject

@property NSURL *url;
@property (readonly) NSString *token;
@property (readonly) NSNumber *status;


+ (OAuthRequester*) oauth;
+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl;
+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl withToken:(NSString*)tokenString;
+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl;
+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl withToken:(NSString*)tokenString;

- (OAuthRequester*) init;
- (OAuthRequester*) initWithUrl:(NSURL*)turl;
- (OAuthRequester*) initWithUrl:(NSURL*)turl withToken:(NSString*)tokenString;
- (OAuthRequester*) initWithUrlString:(NSString*)turl;
- (OAuthRequester*) initWithUrlString:(NSString*)turl withToken:(NSString*)tokenString;

- (void) setToken:(NSString *)ttoken;

- (void) registerReceiver:(id)receiver withSelector:(SEL)selector;

- (void) GET;
- (void) postClientCredentials;
- (void) postPassword:(NSString*)password forUser:(NSString*)username;

@end
