//
// JWT.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#ifndef JWT_h
#define JWT_h

#import <Foundation/Foundation.h>

@interface JWT : NSObject

@property NSDictionary *token;
@property (readonly) NSMutableDictionary *header;
@property (readonly) NSMutableDictionary *claims;
@property (readonly) NSString *signature;

+ (JWT*) jwt;
+ (JWT*) jwtWithToken:(NSDictionary*)ptoken;
+ (JWT*) jwtWithTokenString:(NSString*)ptoken;

- (JWT*) init;
- (JWT*) initWithToken:(NSDictionary*)ptoken;
- (JWT*) initWithTokenString:(NSString*)ptoken;

- (NSString*) compact; // compact representation
- (NSString*) json;    // json representation
- (NSString*) authHeader; // processes the token spec and returns the appropriate auth header

- (void) sign;

- (void) hardReset;
- (void) reset;
- (void) resetWithTokenString: (NSString*)stoken;

- (void) setClaim:(NSString*)claimName
        withValue:(NSObject*)claimValue;

- (void) setHeader:(NSString*)headerName
         withValue:(NSString*)headerValue;

- (void) setAudience:(NSString*)audience;
- (void) setExpiration:(NSNumber*)timestamp;
- (void) setId:(NSString*)tokenId;
- (void) setIssuedAt:(NSNumber*)timestamp;
- (void) setIssuer:(NSString*)issuer;
- (void) setNotBefore:(NSNumber*)timestamp;
- (void) setSubject:(NSString*)subject;

- (void) setKid:(NSString*)kid;

+ (NSString*) jsonEncode:(id)dict;
+ (id) jsonDecode:(NSString*)jsonString;

@end

#endif
