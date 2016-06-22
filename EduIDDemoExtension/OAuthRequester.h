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
@property NSString *deviceToken;
@property NSString *clientToken;
@property NSString *userToken;

@property NSString *clientID; //

@property (readonly) NSNumber *status;
@property (readonly) NSString *result;

+ (OAuthRequester*) oauth;
+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl;
+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl;

- (OAuthRequester*) init;
- (OAuthRequester*) initWithUrl:(NSURL*)turl;
- (OAuthRequester*) initWithUrlString:(NSString*)turl;

- (void) registerReceiver:(id)receiver withSelector:(SEL)selector;

- (void) GET;
- (void) postClientCredentials;
- (void) postPassword:(NSString*)password forUser:(NSString*)username;

@end
