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

@property (retain, nonatomic) NSString *clientId; //

@property (retain, setter=setRawDataStore:) SharedDataStore *dataStore;

@property (retain, nonatomic) Tokens *clientData;
@property (retain, nonatomic) Tokens *accessData;


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

// revoke authorization
- (void) logout;

// user information
- (void) getUserProfile;

// service information
- (void) postProtocolList: (NSArray*) protocolList;

// service assertion
- (void) retrieveServiceAssertion:(NSString*) targetServiceUrl;

- (void) authorizeWithService:(NSString*) targetServiceUrl
        withAuthorizationCode:(NSString*) assertionToken
                   withCaller: (id) caller
                 withSelector: (SEL)selector;

// app assertion
- (void) authorizeApp:(NSString*) appClientId
            atService:(NSString*) targetService;

- (NSString*) serviceUrl:(nonnull NSDictionary*)rsd
             forProtocol:(nonnull NSString*)protocol;

- (nullable NSString*) serviceUrl:(nonnull NSDictionary*)rsd
             forProtocol:(nonnull NSString*)protocol
             forEndpoint:(nullable NSString*) endpoint;

// app specific functions
- (void) verifyAuthorization;  // allows the caller to request or trigger authorization

- (void) loadTokens;
- (void) storeTokens;

- (BOOL) retry;
- (BOOL) invalid;

@end
