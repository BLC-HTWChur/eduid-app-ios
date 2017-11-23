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

@synthesize dataStore = _DS;

// @synthesize authorizations;

+ (RequestData*) request
{
    return [[RequestData alloc] init];
}

+ (RequestData*) requestWithDataStore: (SharedDataStore*) datastore
{
    return [[RequestData alloc] initWithDataStore:datastore];
}

+ (RequestData*) requestWithObject:(id)handler
{
    return [[RequestData alloc] initWithObject:handler];
}

+ (RequestData*) requestWithObject:(id)handler
                     withDataStore: (SharedDataStore*)datastore
{
    return [[RequestData alloc] initWithObject:handler];
}

+ (RequestData*) requestWithObject:(id)handler
                      withCallback: (SEL)callback
{
    return [[RequestData alloc] initWithObject:handler
                                  withCallback:callback];
}

+ (RequestData*) requestWithObject:(id)handler
                      withCallback: (SEL)callback
                     withDataStore: (SharedDataStore*)datastore
{
    return [[RequestData alloc] initWithObject:handler
                                  withCallback:callback
                                 withDataStore:datastore];
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

- (RequestData*) initWithDataStore: (SharedDataStore*) datastore
{
    self = [self init];

    _DS = datastore;

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

- (RequestData*) initWithObject:(id)handler
                   withCallback:(SEL)callback
                  withDataStore:(SharedDataStore*)datastore
{
    self = [self init];
    cbHandler = handler;
    cbFunction = callback;
    _DS = datastore;
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

- (NSString*) absoluteURL
{
    return [url absoluteString];
}

- (void) copyData: (RequestData*)req
{
    if (![req type])
        [req setType:type];
    if (![req url])
        [req setUrl:url];

    [req setStatus:status];
    [req setResult:result];
    [req setData:[self processedResult]];

    if (![req input]) {
        [req setInput:input];
    }

    if ([self shouldRetry]) {
        [req retry];
    }
    
    if ([self isInvalid]) {
        [req invalidate];
    }

    [req setRawDataStore: _DS];
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
    return url;
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
    if (input) {
        return [[JWT jsonEncode:input] dataUsingEncoding:NSUTF8StringEncoding];
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

/**
 * URL Session Delegat Functions
 */

// this function adds the Authorization header if we have an authorization for a host.
// The host authorizations MUST be set at the beginnen of the request. This method does not dynamically
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{

    url = request.URL;

    NSMutableURLRequest *newRequest = [[NSMutableURLRequest alloc] initWithURL:url
                                                                   cachePolicy:request.cachePolicy
                                                               timeoutInterval:request.timeoutInterval];

    NSString *authString = [self loadToken];
    
    if (authString && [authString length]) {
        [newRequest setValue:authString forHTTPHeaderField:@"Authorization"];
    }

    completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)reqdata
{

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)dataTask.response;

    [self setStatus:[NSNumber numberWithInteger:httpResponse.statusCode]];

    if (reqdata &&
        [reqdata length]) {
        [self setResult:[[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding]];
    }

    if (httpResponse.statusCode == 500) {
        NSLog(@"Server Error for %@", [self absoluteURL]);
    }

    [self complete];
}

- (NSString*) loadToken
{
    NSString *targetHost = url.host;
    NSString *retToken = nil;

    if (_DS != nil) {
        NSManagedObjectContext *moc = [_DS managedObjectContext];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tokens"];

        [request setPredicate:[NSPredicate predicateWithFormat:@"target == %@", targetHost]];

        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:request error:&error];

        NSString *token = nil;
        if (results) {
            for (Tokens *t in results)
            {
                if ([[t subject] isEqual: @"ch.eduid.app"]) {
                    token = [t token];
                }
            }

            if (token != nil) {
                // process token
                JWT *jwt = [JWT jwtWithTokenString:token];

                [jwt setAudience:url.absoluteURL];

                // any additional requirements MUST be defined in the auth jwk?

                retToken = [jwt authHeader];
            }
        }
    }

    return retToken;
}


@end
