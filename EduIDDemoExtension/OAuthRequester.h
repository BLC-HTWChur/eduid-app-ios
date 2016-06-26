//
//  OAuthRequester.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

@import Foundation;

#import "SharedDataStore.h"
#import "Tokens.h"

@interface OAuthRequester : NSObject

@property (retain, nonatomic) NSURL *url;
@property (retain, nonatomic) NSString *deviceToken;
@property (retain, setter=setRawClientToken:) NSString *clientToken;
@property (retain, setter=setRawAccessToken:) NSString *accessToken;

@property (retain, nonatomic) NSString *clientID; //

@property (readonly, retain) NSNumber *status;
@property (readonly, retain) NSString *result;

@property (retain, setter=setRawDataStore:) SharedDataStore *dataStore;

@property (retain, nonatomic) Tokens *clientData;
@property (retain, nonatomic)Tokens *accessData;


+ (OAuthRequester*) oauth;
+ (OAuthRequester*) oauthWithUrl:(NSURL*)turl;
+ (OAuthRequester*) oauthWithUrlString:(NSString*)turl;

- (OAuthRequester*) init;
- (OAuthRequester*) initWithUrl:(NSURL*)turl;
- (OAuthRequester*) initWithUrlString:(NSString*)turl;

- (void) setDataStore:(SharedDataStore *)dataStore;

- (void) registerReceiver:(id)receiver withSelector:(SEL)selector;

// client authorization
- (void) postClientCredentials;
// user authorization
- (void) postPassword:(NSString*)password forUser:(NSString*)username;

// user information
- (void) getUserProfile;

// service information
- (void) postProtocolList: (NSArray*) protocolList;

- (void) authorize;  // allows the caller to request or trigger authorization 
- (void) logout;

- (void) loadTokens;
- (void) storeTokens;

- (BOOL) retry;
- (BOOL) invalid;

@end
