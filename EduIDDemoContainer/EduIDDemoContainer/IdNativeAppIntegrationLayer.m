//
//  IdNativeAppIntegrationLayer.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 21/06/16.
//  Copyright © 2016 HTW Chur. All rights reserved.
//

@import Foundation;
@import UIKit;

#include <CommonCrypto/CommonHMAC.h>

#include "../common/constants.h"

#include "IdNativeAppIntegrationLayer.h"

// IOS Extension Hooks

// Use a fake URN, because there is no official URN for the differen OAUTH endpoints
// at the device level.
#define EDUID_EXTENSION_TYPE @"urn:ietf:params:oauth:assertion" // name for the app protocol
#define EDUID_EXTENSION_TITLE @"Protocol Endpoints"


@implementation IdNativeAppIntegrationLayer {
    id callerObject;
    SEL selector;
}

@synthesize services;

-(void)requestProtocols:(NSArray*)protocolList
              forObject:(id)object
           withSelector:(SEL)cbSelector
{

    if (protocolList != nil &&
        protocolList.count > 0) {

        callerObject = object;
        selector     = cbSelector;
        services = [NSDictionary dictionary];

        // The NSItemProvider is the hook for passing objects securely between
        // apps
        NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:protocolList
                                                             typeIdentifier:EDUID_EXTENSION_TYPE];

        // The NSExtensionItem is a container for explicitly passing information
        // between extensions and containers
        NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
        extensionItem.attachments      = @[ itemProvider ];

        //create object to access extension
        UIActivityViewController *activityExtension = [[UIActivityViewController alloc] initWithActivityItems:@[extensionItem]
                                                                                        applicationActivities:nil];

        //define activities when the extension is finished
        activityExtension.completionWithItemsHandler=^(NSString *activityType,
                                                       BOOL completed,
                                                       NSArray *returnedItems,
                                                       NSError *activityError) {
            if (activityError == nil &&
                returnedItems.count > 0) {

                NSLog(@"Return from Extension with success");

                // normal app extensions always complete on return.
                [self extensionCompleted:activityType
                       withItemsReturned:returnedItems];
            }
            else if (activityError != nil) {
                NSLog(@"Activity failed to complete");
                [self completeAuthorization];
            }
        };

        //hand over to iOS to handle the extension
        [object presentViewController:activityExtension
                           animated:YES
                         completion:nil];
    }
}

- (NSArray*) serviceNames
{
    return [services allKeys];
}

- (NSString*) getServiceUrl:(NSString *)serviceName
                forProtocol:(NSString *)protocolName
{
    NSString *retval= @"";

    // get an object
    NSDictionary *epDict = [services valueForKey:serviceName];
    if (epDict) {
        NSDictionary *apiDict = [epDict valueForKey: @"apis"];
        if (apiDict) {
            NSDictionary *pDict   = [apiDict valueForKey:protocolName];

            NSString *hpLink  = [epDict valueForKey:@"homePageLink"];
            NSString *enLink  = [epDict valueForKey:@"engineLink"];
            NSString *apiLink = [pDict valueForKey:@"apiLink"];

            NSCharacterSet *slashSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];

            hpLink  = [hpLink stringByTrimmingCharactersInSet: slashSet];
            enLink  = [enLink stringByTrimmingCharactersInSet: slashSet];
            apiLink = [apiLink stringByTrimmingCharactersInSet: slashSet];

            if ([apiLink hasPrefix:@"https://"] ||
                [apiLink hasPrefix: @"http://"]) {
                retval = apiLink;
            }
            else if ([enLink hasPrefix: @"https://"] || [enLink hasPrefix: @"http://"]) {
                retval = [@[enLink, apiLink] componentsJoinedByString: @"/"];
            }
            else {
                if ([enLink length] > 0) {
                    retval = [@[hpLink, enLink, apiLink] componentsJoinedByString: @"/"];
                }
                else {
                    retval = [@[hpLink, apiLink] componentsJoinedByString: @"/"];
                }

            }
        }
    }

    return retval;
}

- (NSString*) getServiceAuthorization:(NSString*) serviceName
                          forProtocol:(NSString*) protocolName
{
    return [self getServiceAuthorization:serviceName
                             forProtocol:protocolName
                              withClaims:nil];
}

- (NSString*) getServiceAuthorization:(NSString*) serviceName
                          forProtocol:(NSString*) protocolName
                           withClaims:(NSDictionary*) claims
{
    NSString *retval = nil;

    NSDictionary *token = [self getEndpointToken: serviceName];
    NSString     *url   = [self getEndpointUrl: serviceName
                                  withProtocol: protocolName];

    if ([url length] > 0) {
        NSLog(@"%@", url);

        NSString *appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];

        // UIDevice *device = [UIDevice currentDevice];
        // NSString *deviceID = [[device identifierForVendor] UUIDString];

        NSNumber *ti = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
        NSLog(@"%@", ti);

        retval = [token objectForKey: @"access_key"];

        // if the token has a refresh token, the client MUST authenticate using
        // the access_token. Otherwise the client MUST authenticate using JWT.

        if ([[token allKeys] indexOfObject:@"refresh_token"] == NSNotFound) {
            // sha256 the deviceID, so we don't have to expose information unnecessarily

            // create a header
            NSDictionary *header  = [NSDictionary dictionaryWithObjectsAndKeys:@"JWT", @"typ",
                                     [token objectForKey:@"kid"], @"kid",
                                     [token objectForKey:@"mac_algorithm"], @"alg", nil];
            NSDictionary *tclaims = [NSDictionary dictionaryWithObjectsAndKeys: url, @"aud",
                                     appID, @"iss",
                                     ti, @"iat",
                                     [token objectForKey:@"client_id"], @"sub",nil];
            NSString *hstr = [self jsonEncode:header];
            NSString *cstr = [self jsonEncode:tclaims];
            NSString *estr = [@[[self base64url:hstr],[self base64url:cstr]] componentsJoinedByString: @"."];

            NSString *sign = [self signData:estr
                                    withKey:[token objectForKey:@"mac_key"]
                              withAlgorithm:[token objectForKey:@"mac_algorithm"]];

            retval = [@[estr, sign] componentsJoinedByString: @"."];
            
            //    NSLog(@"%@", hstr);
            NSLog(@"%@",cstr);
            //    NSLog(@"%@",estr);
            //    NSLog(@"%@",sign);
            //    NSLog(@"%@",retval);
        }
    }
    // generate the JWT
    // get the app id
    return retval;
}

- (NSString*) serialize
{
    return [self jsonEncode: services];
}

- (void) parse:(NSString *)serviceSpec
{
    NSDictionary *tdict = [self jsonDecode:serviceSpec];

    if (tdict != nil) {
        // TODO: Sanity checks, if we are looking at our own data
        services = tdict;
    }
}

/** ************************************************************************
 *  Private methods
 */

/**
 * completion handling after the authorization extension completed.
 */
-(void)extensionCompleted:activityType
        withItemsReturned:(NSArray*)returnedItems
{

    //I know there is only a single object in the returned items.
    //So I get the single item (There couldn't be more elements up to iOS10)
    NSExtensionItem *item = returnedItems[0];
    //I know there is only a single attachment in the item
    //So I get it
    NSItemProvider *itemProvider = item.attachments[0];

    // The extension protocol requires that the attached item is of type
    // 'urn:ietf:params:oauth:assertion'. All other attachments are
    // ignored.
    [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
                                    options:nil
                          completionHandler:^(NSDictionary *epDict,
                                              NSError *error)
     {
         // ensure that the attached item is properly loaded
         if (error == nil) {
             NSLog(@"got dictionary %@", [self jsonEncode:epDict]);

             // store it in the client.
             services = epDict;
         }

         [self completeAuthorization];
     }];
}

/**
 * Signals the calling object that the request has completed.
 */
- (void)completeAuthorization
{
    // when we are done inform the calling object that it can now work with
    // the services

    if (callerObject != nil &&
        selector != nil) {

        NSLog(@"complete authorization");

        IMP imp = [callerObject methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(callerObject, selector);
    }
}

/**
 * extracts the authorzation token for a given service.
 */

- (NSDictionary*) getServiceToken:(NSString*)serviceName
{
    NSDictionary *dict = [NSDictionary dictionary];

    // get an object
    NSDictionary *epDict = [services valueForKey:serviceName];
    if (epDict) {
        dict = [epDict valueForKey:@"token"];
    }

    return dict;
}

/**
 * signs a JWT token accordingly
 *
 * presently only JWS HS256, HS384, and HS512 signatures are permitted
 */
- (NSString*)signData:(NSString*)strData
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

        hash = [self urlTrim:hash];
    }
    // TODO RSA signing (RS*)
    // TODO EC signing (ES*)

    return hash;
}

/**
 * JSON encodes a dictionary
 */
- (NSString*)jsonEncode:(NSDictionary*) dict
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
- (NSDictionary*)jsonDecode:(NSString*) jsonString
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
- (NSString*)base64url:(NSString*)payload
{
    NSString *retval;

    retval = [[payload dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    retval  = [self urlTrim:retval];

    return retval;
}

/**
 * trims equal signs from the ends of a string. 
 *
 * JWT requires that all equal signs are eliminated from the end of strings.
 */
- (NSString*)urlTrim:(NSString)encodedString
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