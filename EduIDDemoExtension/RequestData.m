//
//  RequestData.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 06/07/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "RequestData.h"
#import "EduIDDemoExtension/JWT.h"

@implementation RequestData

@synthesize type;
@synthesize url;
@synthesize status;
@synthesize result;

@synthesize data;
@synthesize input;

@synthesize cbHandler;
@synthesize cbFunction;
@synthesize parent;


+ (RequestData*) request
{
    return [[RequestData alloc] init];
}

+ (RequestData*) requestWithObject:(id)handler
{
    return [[RequestData alloc] initWithObject:handler];
}

+ (RequestData*) requestWithObject:(id)handler
                      withCallback: (SEL)callback
{
    return [[RequestData alloc] initWithObject:handler
                                  withCallback:callback];
}

+ (RequestData*) cloneRequest:(RequestData*)request
{
    return [[RequestData alloc] initWithRequest:request];
}

+ (RequestData*) cloneRequest:(RequestData*)request
                 withCallback:(SEL)callback
{
    return [[RequestData alloc] initWithRequest:request
                                   withCallback:callback];
}

+ (RequestData*) subRequest:(RequestData*)parentRequest
{
    RequestData *newRequest = [RequestData request];

    [newRequest setParent:parentRequest];
    [parentRequest copyData:newRequest];

    return newRequest;
}


+ (RequestData*) subRequest:(RequestData*)parentRequest
                withHandler:(id)newHandler
{
    RequestData *newRequest = [RequestData subRequest:parentRequest];

    [newRequest setCbHandler:newHandler];

    return newRequest;
}


+ (RequestData*) subRequest:(RequestData*)parentRequest
                withHandler:(id)handler
               withCallback:(SEL)callback
{
    RequestData *newRequest = [RequestData subRequest:parentRequest];

    [newRequest setCbHandler:handler];
    [newRequest setCbFunction:callback];

    return newRequest;
}

- (RequestData*) init
{
    type = @"";
    status = @-1;
    result = @"";

    cbHandler = nil;
    parent = nil;

    data = nil;
    input = nil;

    _retryProp = NO;
    _invalidDevice = NO;

    return self;
}

- (RequestData*) initWithObject:(id)handler
{
    self = [self init];

    cbHandler = handler;

    return self;
}

- (RequestData*) initWithObject:(id)handler
                   withCallback:(SEL)callback
{
    self = [self init];
    cbHandler = handler;
    cbFunction = callback;
    return self;
}

- (RequestData*) initWithRequest:(RequestData*)request
{
    self = [self init];
    [request copyData:self];

    cbHandler = [request cbHandler];
    cbFunction = [request cbFunction];
    parent = [request parent];
    
    return self;
}

- (RequestData*) initWithRequest:(RequestData*)request
                    withCallback:(SEL)callback
{
    self = [self initWithRequest:request];
    if (callback) {
        cbFunction = callback;
    }
    return self;
}

- (void) copyData: (RequestData*)req
{
    [req setType:type];
    [req setUrl:url];

    [req setStatus:status];
    [req setResult:result];

    [req setInput:input];
    [req setData:[self processedResult]];

    if ([self shouldRetry]) {
        [req retry];
    }
    if ([self isInvalid]) {
        [req invalidate];
    }

}

- (void) complete // calls the callback
{
    if (parent) {
        [self copyData:parent];
    }

    if (cbHandler != nil) {
        IMP imp = [cbHandler methodForSelector:cbFunction];
        void (*func)(id, SEL, RequestData*) = (void *)imp;

        if (!parent) {
            // if there is no parent we hand back to the UI thread
            dispatch_async(dispatch_get_main_queue(), ^{
                func(cbHandler, cbFunction, self);
            });
        }
        else {
            // this is an internal handler.
            func(cbHandler, cbFunction, self);
        }
    }
}

- (void) complete:(NSNumber*)cStatus
{
    [self setStatus:cStatus];

    [self complete];
}

- (void) complete:(NSNumber*)cStatus
               withResult:(NSString*) cResult
{
    [self setStatus:cStatus];
    [self setResult:cResult];
    
    [self complete];
}

- (void) retry
{
    _retryProp = YES;
}

- (BOOL) shouldRetry
{
    return _retryProp;
}

- (BOOL) isInvalid
{
    return _invalidDevice;
}

- (void) invalidate
{
    _invalidDevice = YES;
}

- (NSURL*) processedUrl
{
    return [NSURL URLWithString:url];
}

- (id) processedResult
{
    if (!data) {
        data = [JWT jsonDecode:result];
    }
    return data;
}

- (NSData*) inputData
{
    if (data) {
        return [[JWT jsonEncode:data] dataUsingEncoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (RequestData*) cloneRequest
{
    return [RequestData cloneRequest:self];
}

- (RequestData*) cloneRequest:(SEL)callback
{
    return [RequestData cloneRequest:self withCallback:callback];
}

- (RequestData*) subRequestFor:(id)subHandler
                  withCallback:(SEL)subCallback
{
    return [RequestData subRequest:self
                       withHandler:subHandler
                      withCallback:subCallback];
}

@end
