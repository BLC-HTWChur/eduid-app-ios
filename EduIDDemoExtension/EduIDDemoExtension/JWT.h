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

- (void) sign;

- (void) setClaim:(NSString*)claimName
        withValue:(NSObject*)claimValue;

- (void) setHeader:(NSString*)headerName
        withValue:(NSString*)headerValue;

- (void) setIssuer:(NSString*)issuer;
- (void) setSubject:(NSString*)subject;
- (void) setAudience:(NSString*)audience;
- (void) setIssuedAt:(NSNumber*)timestamp;
- (void) setNotBefore:(NSNumber*)timestamp;
- (void) setExpiration:(NSNumber*)timestamp;
- (void) setId:(NSString*)tokenId;

- (void) setKid:(NSString*)kid;

+ (NSString*) jsonEncode:(NSDictionary*)dict;
+ (NSDictionary*) jsonDecode:(NSString*)jsonString;

@end

#endif