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
    token = nil;
    header = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"JWT", @"typ", nil];
    claims = [NSMutableDictionary dictionary];

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


- (NSString*) compact
{
    NSArray *tstr;
    if (signature == nil) {
        [self sign];
    }

    if (signature != nil) {
        tstr = @[[JWT base64url:[JWT jsonEncode:header]],
                 [JWT base64url:[JWT jsonEncode:claims]],
                 signature];
    }
    else {
        tstr = @[[JWT base64url:[JWT jsonEncode:header]],
                 [JWT base64url:[JWT jsonEncode:claims]],
                 @""];

    }

    return [tstr componentsJoinedByString:@"."];
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
        result = [NSDictionary dictionaryWithObjectsAndKeys:
                  hstr, @"header",
                  pstr, @"protected",
                  cstr, @"payload",
                  signature, @"signature",
                  nil];
    }
    else {
        result = [NSDictionary dictionaryWithObjectsAndKeys:
                  [JWT jsonEncode:header], @"header",
                  pstr, @"protected",
                  cstr, @"payload",
                  nil];

    }
    return [JWT jsonEncode:result];
}

- (void) sign
{
    if (token != nil) {
        NSString *kid = [token objectForKey: @"kid"];
        NSString *key = [token objectForKey: @"mac_key"];
        NSString *alg = [token objectForKey: @"mac_algorithm"];

        NSString *hstr =[JWT base64url:[JWT jsonEncode:header]];
        NSString *cstr =[JWT base64url:[JWT jsonEncode:claims]];

        NSString *estr = [@[[JWT base64url:hstr],[JWT base64url:cstr]] componentsJoinedByString: @"."];

        [self setHeader:@"alg" withValue:alg];
        [self setHeader:@"kid" withValue:kid];

        signature = [JWT signData:estr
                          withKey:key
                    withAlgorithm:alg];
    }
    else {
        [self setHeader:@"alg" withValue:@"none"];
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
    const char *cKey  = [strKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [strData cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char *cHMAC;
    unsigned char c256HMAC[CC_SHA256_DIGEST_LENGTH];
    unsigned char c384HMAC[CC_SHA384_DIGEST_LENGTH];
    unsigned char c512HMAC[CC_SHA512_DIGEST_LENGTH];

    CCHmacAlgorithm ccalg = kCCHmacAlgSHA256;
    cHMAC = c256HMAC;

    NSString *hash = @"";

    if ([alg hasPrefix:@"HS"]) {
        if ([alg isEqualToString: @"HS384"]) {
            ccalg = kCCHmacAlgSHA384;
            cHMAC = c384HMAC;
        }
        else if ([alg isEqualToString:@"HS512"]) {
            ccalg = kCCHmacAlgSHA512;
            cHMAC = c512HMAC;
        }

        CCHmac(ccalg, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

        NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                              length:sizeof(cHMAC)];

        hash = [HMAC base64EncodedStringWithOptions:0];

        hash = [JWT urlTrim:hash];
    }
    // TODO RSA signing (RS*)
    // TODO EC signing (ES*)

    return hash;
}

/**
 * JSON encodes a dictionary
 */
+ (NSString*)jsonEncode:(NSDictionary*) dict
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
+ (NSDictionary*)jsonDecode:(NSString*) jsonString
{
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:0
                                                           error:nil];
    return dict;
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
        retval  = [encodedString stringByTrimmingCharactersInSet: equalSet];
    }
    return retval;
    
}

@end
