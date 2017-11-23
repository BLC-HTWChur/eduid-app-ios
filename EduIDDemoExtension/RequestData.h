//
//  RequestData.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 06/07/16.
//  Copyright © 2016 SII. All rights reserved.
//


@import Foundation;

#import "SharedDataStore.h"
#import "Tokens.h"

@interface RequestData : NSObject <NSURLSessionDataDelegate>

@property (retain, nonatomic) NSString *type; // refers to the step of the interaction
@property (retain, nonatomic) NSURL *url;

@property (retain, strong) NSNumber *status;
@property (retain, strong) NSString *result;

@property (retain, strong) id data;  // parsed result
@property (retain, strong) id input; // parsed input data

@property (retain, nonatomic) id cbHandler;
@property (nonatomic) SEL cbFunction;
@property (strong, nonatomic) RequestData* parent; // need a strong variable

@property () BOOL retryProp;
@property () BOOL invalidDevice;

// @property (retain, strong) NSMutableDictionary *authorizations;
@property (retain, setter=setRawDataStore:) SharedDataStore *dataStore;

+ (RequestData*) request;
+ (RequestData*) requestWithObject:(id)handler;
+ (RequestData*) requestWithObject:(id)handler withCallback: (SEL)callback;

+ (RequestData*) requestWithDataStore: (SharedDataStore*) datastore;
+ (RequestData*) requestWithObject:(id)handler withDataStore: (SharedDataStore*)datastore;
+ (RequestData*) requestWithObject:(id)handler withCallback: (SEL)callback withDataStore: (SharedDataStore*)datastore;

+ (RequestData*) cloneRequest:(RequestData*)request;
+ (RequestData*) cloneRequest:(RequestData*)request withCallback:(SEL)callback;

+ (RequestData*) subRequest:(RequestData*)parentRequest;
+ (RequestData*) subRequest:(RequestData*)parentRequest withHandler:(id)newHandler;
+ (RequestData*) subRequest:(RequestData*)parentRequest withHandler:(id)newHandler withCallback:(SEL)callback;

- (RequestData*) init;
- (RequestData*) initWithObject:(id)handler;
- (RequestData*) initWithObject:(id)handler withCallback:(SEL)callback;
- (RequestData*) initWithObject:(id)handler withCallback:(SEL)callback withDataStore:(SharedDataStore*)datastore;

- (RequestData*) initWithRequest:(RequestData*)request;
- (RequestData*) initWithRequest:(RequestData*)request withCallback:(SEL)callback;

- (NSString*) absoluteURL;

-(void) retry;
-(BOOL) shouldRetry;

- (void) invalidate;
- (BOOL) isInvalid;

- (id) processedResult;   // allows to access JSON data directly
- (NSData*) inputData;

- (void) complete;      // calls the callback
- (void) complete:(NSNumber*)cStatus;
- (void) complete:(NSNumber*)cStatus withResult:(NSString*) cResult;      // calls the callback

- (NSURL*) processedUrl;

- (RequestData*) cloneRequest;
- (RequestData*) cloneRequest:(SEL)callback;
- (RequestData*) subRequestFor:(id)subHandler withCallback:(SEL)subCallback;


@end
