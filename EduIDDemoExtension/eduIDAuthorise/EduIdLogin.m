//
//  eduIdLogin.m
//  eduID
//
//  Created by SII on 28.04.16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "EduIdLogin.h"
#import "PersistentStore.h"

@interface EduIdLogin()

@property (strong) NSURLSessionDataTask* eduLoginSessionTask;

@end

@implementation EduIdLogin

-(id) init
{
    if (self!=[super init])
    {
        return nil;
    }
    _eduLoginSessionTask=nil;
    return self;
}

//delegate methods NSURLSessionDelegate

//delegate methods NSURLSessionTaskDelegate

//delegate methods NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSLog([[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler{
    NSLog(@"%s",__func__);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error{
    NSLog(@"%s",__func__);
}

/** Session creation (singleton) */
- (NSURLSession *)getURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    //check if session is already valid
    if (nil != session)
    {//valid -> return session
        return session;
    }
    
    //create session only once (for sure)
    dispatch_once(&onceToken,
                  ^{
                      NSURLSessionConfiguration *configuration =
                      [NSURLSessionConfiguration defaultSessionConfiguration];
                      session = [NSURLSession sessionWithConfiguration:configuration
                                 delegate:self delegateQueue:nil];
                  });
    return session;
}

/**
 @brief Creates and prepares an URL object to be sent to an authentication
 server to acquire a auth token. The neccessary parameters are taken from the class properties.
 @return a newly created request object
 @TODO implementation is just a mockup yet
 */
-(NSMutableURLRequest*) prepareLoginRequest
{
/*
 //get persistent attributes
    PersistentStore *persistentStore = [PersistentStore new];
    
    //test if prerequisites are valid
    if (NULL==persistentStore.userName || 0 == [persistentStore.userName length]|| NULL==persistentStore.eduIdServerURL)
    {//invalid prerequisits -> do not generate request
        return NULL;
    }
    
    //create request object
    NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:persistentStore.eduIdServerURL];
    [authRequest setHTTPMethod:@"PUT"];
 */
    //create request object
    NSString *url=@"https://www.google.com";
    url=[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [authRequest setHTTPMethod:@"GET"];

    return authRequest;
}

-(NSString*) login
{
    NSMutableURLRequest *loginRequest=[self prepareLoginRequest];
    _eduLoginSessionTask = [[self getURLSession]
                        dataTaskWithRequest:loginRequest];
   NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:loginRequest
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        NSLog([[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    }
 
    [_eduLoginSessionTask resume];
    
    return @"We expect a token to be returned";
    
}
@end
