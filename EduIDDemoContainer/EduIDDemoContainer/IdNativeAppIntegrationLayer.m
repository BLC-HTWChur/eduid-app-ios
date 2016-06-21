//
//  IdExtension.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 21/06/16.
//  Copyright © 2016 SII. All rights reserved.
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

@synthesize endpoints;

-(void)requestProtocols:(NSArray*)protocolList
              forObject:(id)object
           withSelector:(SEL)cbSelector
{

    if (protocolList != nil &&
        protocolList.count > 0) {

        callerObject = object;
        selector     = cbSelector;
        endpoints = [NSDictionary dictionary];

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

- (NSArray*) getAllEndpoints
{
    return [endpoints allKeys];
}

- (NSString*) getEndpointUrl:(NSString *)endpointName
                withProtocol:(NSString *)protocolName
{
    NSString *retval= @"";

    // get an object
    NSDictionary *epDict = [endpoints valueForKey:endpointName];
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

- (NSDictionary*) getEndpointToken:(NSString*)endpointName
{
    NSDictionary *dict = [NSDictionary dictionary];

    // get an object
    NSDictionary *epDict = [endpoints valueForKey:endpointName];
    if (epDict) {
        dict = [epDict valueForKey:@"token"];
    }

    return dict;
}

- (NSString*) getEndpointAuthorization:(NSString*) endpointName
                          withProtocol:(NSString*) protocolName
                            withClaims:(NSDictionary*) claims
{
    NSString *retval = @"";

    NSDictionary *token = [self getEndpointToken: endpointName];
    NSString     *url   = [self getEndpointUrl: endpointName
                                  withProtocol: protocolName];

    NSLog(@"%@", url);

    NSString *appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];

//    UIDevice *device = [UIDevice currentDevice];
//    NSString *deviceID = [[device identifierForVendor] UUIDString];

    NSNumber *ti = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
    NSLog(@"%@", ti);

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

    // generate the JWT
    // get the app id
    return retval;
}

-(void)extensionCompleted:activityType
        withItemsReturned:(NSArray*)returnedItems
{

        //I know there is only a single object in the returned items.
        //So I only get this single item (There could be more elements there)
        NSExtensionItem *item = returnedItems[0];
        //I know there is only a single attachment in the item
        //So I get this
        NSItemProvider *itemProvider = item.attachments[0];
        //I know the item I want to get is a string and is signed as a string
        //The completion handler is called when extraction of this string is completed
        [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
                                        options:nil
                              completionHandler:^(NSDictionary *epDict,
                                                  NSError *error)
         {
             if (error == nil) {
                 NSLog(@"got dictionary %@", [self jsonEncode:epDict]);

                 endpoints = epDict;
             }
             NSLog(@"complete authorization");
             [self completeAuthorization];
         }];
}

- (void)completeAuthorization
{
    // when we are done inform the calling object that it can now work with
    // the endpoints
    if (callerObject != nil && selector != nil) {
        IMP imp = [callerObject methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(callerObject, selector);
    }
}

- (NSString*)signData:(NSString*)strData
              withKey:(NSString*)strKey
        withAlgorithm:(NSString*)alg
{
    const char *cKey  = [strKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [strData cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];

    CCHmacAlgorithm ccalg = kCCHmacAlgSHA256;

    NSString *hash = @"";

    if ([alg hasPrefix:@"HS"]) {
        if ([alg isEqualToString: @"HS384"]) {
            ccalg = kCCHmacAlgSHA384;
        }
        else if ([alg isEqualToString:@"HS512"]) {
            ccalg = kCCHmacAlgSHA512;
        }


        CCHmac(ccalg, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

        NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                              length:sizeof(cHMAC)];

        hash = [HMAC base64EncodedStringWithOptions:0];

        NSCharacterSet *equalSet = [NSCharacterSet characterSetWithCharactersInString:@"="];
        hash  = [hash stringByTrimmingCharactersInSet: equalSet];
    }
    // TODO RSA signing (RS*)
    // TODO DSA signing (ES*)

    return hash;
}

- (NSString*)jsonEncode:(NSDictionary*) dict
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                     options:0
                                                       error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSString*)base64url:(NSString*)payload
{
    NSString *retval;
    NSCharacterSet *equalSet = [NSCharacterSet characterSetWithCharactersInString:@"="];

    retval = [[payload dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    retval  = [retval stringByTrimmingCharactersInSet: equalSet];

    return retval;
}

@end