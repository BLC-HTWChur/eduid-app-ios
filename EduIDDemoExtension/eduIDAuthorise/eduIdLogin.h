//
//  eduIdLogin.h
//  eduID
//
//  Created by SII on 28.04.16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EduIdLogin : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic,readonly) NSMutableData *loginResponse;

/** logs in to the eduID server and tries to fetch the authorisation token.
 @return the fetched token or nil when failed */
-(NSString*) login;

@end
