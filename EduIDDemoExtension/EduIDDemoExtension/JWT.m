//
//  JWT.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 22/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "JWT.h"
#include <CommonCrypto/CommonHMAC.h>

@implementation JWT

@synthesize token;
@synthesize header;
@synthesize claims;
@synthesize signature;

+ (JWT*) jwt
{
    return [[JWT alloc] init];
}

+ (JWT*) jwtWithToken:(NSDictionary*)ptoken
{
    return [[JWT alloc] initWithToken:ptoken];

}

+ (JWT*) jwtWithTokenString:(NSString *)ptoken
{
    return [[JWT alloc] initWithTokenString:ptoken];
}

- (JWT*) init
{
    [self hardReset];
    return self;
}

- (JWT*) initWithToken:(NSDictionary*)ptoken
{
    self = [self init];

    token = ptoken;

    return self;
}

- (JWT*) initWithTokenString:(NSString*)ptoken
{
    NSDictionary *dToken = [JWT jsonDecode:ptoken];

    return [self initWithToken:dToken];
}

- (void) hardReset
{
    [self reset];
    token = nil;
}

- (void) reset
{
    header = [NSMutableDictionary dictionaryWithDictionary:@{@"typ": @"JWT"}];
    claims = [NSMutableDictionary dictionary];
    signature = nil;
}

- (void) resetWithTokenString:(NSString *)stoken
{
    [self reset];
    token = [JWT jsonDecode:stoken];
}

- (NSString*) compact
{
    NSArray *strList;

    if (signature == nil) {
        [self sign];
    }

    if (signature != nil) {
        strList = @[[JWT base64url:[JWT jsonEncode:header]],
                    [JWT base64url:[JWT jsonEncode:claims]],
                    signature];
    }
    else {
        strList = @[[JWT base64url:[JWT jsonEncode:header]],
                    [JWT base64url:[JWT jsonEncode:claims]],
                    @""];

    }

    return [strList componentsJoinedByString:@"."];
}

- (NSString*) json
{
    if (signature == nil) {
        [self sign];
    }

    NSString *pstr = [JWT base64url:[JWT jsonEncode:header]];
    NSString *cstr = [JWT base64url:[JWT jsonEncode:claims]];
    NSString *hstr = [JWT jsonEncode:[NSDictionary dictionary]];

    NSDictionary *result;
    if (signature != nil) {
        result = @{@"header":hstr,
                   @"protected":pstr,
                   @"payload":cstr,
                   @"signature":signature};
    }
    else {
        result = @{@"header":[JWT jsonEncode:header],
                   @"protected":pstr,
                   @"payload":cstr,
                   @"signature":signature};
    }
    return [JWT jsonEncode:result];
}

- (void) sign
{
    if (token != nil) {
        NSString *kid = [token objectForKey: @"kid"];
        NSString *key = [token objectForKey: @"mac_key"];
        NSString *alg = [token objectForKey: @"mac_algorithm"];

        if (!alg) {
            alg = [token objectForKey:@"algorithm"];
        }
        if (!key) {
            key = [token objectForKey:@"sign_key"];
        }

        if ([token objectForKey:@"client_id"])
            [self setIssuer:[token objectForKey: @"client_id"]];
        
        [self setHeader:@"alg" withValue:alg];
        [self setHeader:@"kid" withValue:kid];

        NSString *hstr =[JWT base64url:[JWT jsonEncode:header]];
        NSString *cstr =[JWT base64url:[JWT jsonEncode:claims]];

        NSString *estr = [@[hstr,cstr] componentsJoinedByString: @"."];

        signature = [JWT signData:estr
                          withKey:key
                    withAlgorithm:alg];
    }
    else {
        [self setHeader:@"alg"
              withValue:@"none"];
    }
}

- (void) setClaim:(NSString *)claimName
        withValue:(NSObject *)claimValue
{
    if (claimName != nil &&
        [claimName length] > 0 &&
        claimValue != nil) {
        [claims setObject:claimValue forKey:claimName];
    }
}

- (void) setHeader:(NSString *)headerName
         withValue:(NSString *)headerValue
{
    if (headerName != nil &&
        [headerName length] > 0 &&
        headerValue != nil) {
        [header setObject:headerValue forKey:headerName];
    }
}

- (void) setKid:(NSString *)kid
{
    if (kid != nil &&
        [kid length] > 0) {
        [self setHeader:@"kid" withValue:kid];
    }
}

- (void) setAudience:(NSString *)audience
{
    if (audience != nil &&
        [audience length] > 0) {
        [self setClaim:@"aud" withValue:audience];
    }
}

- (void) setId:(NSString *)tokenId
{
    if (tokenId != nil &&
        [tokenId length] > 0) {
        [self setClaim:@"jti" withValue:tokenId];
    }
}

- (void) setIssuer:(NSString *)issuer
{
    if (issuer != nil &&
        [issuer length] > 0) {
        [self setClaim:@"iss" withValue:issuer];
    }
}

- (void) setSubject:(NSString *)subject
{
    if (subject != nil &&
        [subject length] > 0) {
        [self setClaim:@"sub" withValue:subject];
    }
}

- (void) setIssuedAt:(NSNumber *)timestamp
{
    if (timestamp != nil &&
        timestamp > 0) {
        [self setClaim:@"iat" withValue:timestamp];
    }
}

- (void) setNotBefore:(NSNumber *)timestamp
{
    if (timestamp != nil &&
        timestamp > 0) {
        [self setClaim:@"nbf" withValue:timestamp];
    }
}

- (void) setExpiration:(NSNumber *)timestamp
{
    if (timestamp != nil &&
        timestamp > 0) {
        [self setClaim:@"exp" withValue:timestamp];
    }
}

/**
 * signs a JWT token accordingly
 *
 * presently only JWS HS256, HS384, and HS512 signatures are permitted
 */
+ (NSString*)signData:(NSString*)strData
              withKey:(NSString*)strKey
        withAlgorithm:(NSString*)alg
{
    CCHmacAlgorithm ccalg = kCCHmacAlgSHA256;

    NSString *hash = @"";

    if ([alg hasPrefix:@"HS"]) {
        NSData *keyData = [strKey dataUsingEncoding:NSUTF8StringEncoding];
        //NSLog(@"keyData Length: %lu, Data: %@", keyData.length, keyData);

        NSData *inData = [strData dataUsingEncoding:NSUTF8StringEncoding];
        //NSLog(@"inData Length: %lu, Data: %@", inData.length, inData);

        NSMutableData *HMACdata = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];

        if ([alg isEqualToString: @"HS384"]) {
            ccalg = kCCHmacAlgSHA384;
             HMACdata = [NSMutableData dataWithLength:CC_SHA384_DIGEST_LENGTH];
        }
        else if ([alg isEqualToString:@"HS512"]) {
            ccalg = kCCHmacAlgSHA512;
            HMACdata = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
        }

        CCHmac(ccalg,
               keyData.bytes,
               keyData.length,
               inData.bytes,
               inData.length,
               (void *)HMACdata.bytes);

        // NSLog(@"Hash Mac data generated: %@", HMACdata);

        hash = [HMACdata base64EncodedStringWithOptions:0];
        //NSLog(@"Hash Mac generated: %@", hash);
        hash = [JWT urlTrim:hash];
    }
    // TODO RSA signing (RS*)
    // TODO EC signing (ES*)

    return hash;
}

/**
 * JSON encodes a dictionary
 */
+ (NSString*)jsonEncode:(id)dict
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    return jsonString;
}

/**
 * JSON decodes a string into a dictionary.
 */
+ (id)jsonDecode:(NSString*) jsonString
{
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:jsonData
                                           options:0
                                             error:nil];
}

/**
 * Base64URL encodes a string as defined for JWT.
 */
+ (NSString*)base64url:(NSString*)payload
{
    NSString *retval;

    retval = [[payload dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    retval  = [JWT urlTrim:retval];

    return retval;
}

/**
 * trims equal signs from the ends of a string.
 *
 * JWT requires that all equal signs are eliminated from the end of strings.
 */
+ (NSString*)urlTrim:(NSString*)encodedString
{

    NSString *retval = @"";
    NSCharacterSet *equalSet = [NSCharacterSet characterSetWithCharactersInString:@"="];

    if (encodedString != nil &&
        [encodedString length]) {
        retval  = [encodedString stringByTrimmingCharactersInSet:equalSet];
    }
    return retval;
    
}

@end
