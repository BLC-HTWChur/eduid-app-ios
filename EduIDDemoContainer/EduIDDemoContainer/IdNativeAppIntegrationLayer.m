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
@synthesize view;

-(void)requestProtocols:(NSArray*)protocolList
              forObject:(id)object
           withSelector:(SEL)cbSelector
{

    if (protocolList != nil &&
        protocolList.count > 0) {

        callerObject = object;
        selector     = cbSelector;
        services = [NSDictionary dictionary];

        UIDevice *device = [UIDevice currentDevice];
        NSBundle *bundle   = [NSBundle mainBundle];

        NSDictionary *request = @{
            @"protocols": protocolList,
            @"app_id":    [bundle bundleIdentifier],
            @"client_id": [[device identifierForVendor] UUIDString],
            @"app_name":  [[bundle infoDictionary] objectForKey:(id)kCFBundleExecutableKey]
        };

        // The NSItemProvider is the hook for passing objects securely between
        // apps
        NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:request
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
                [returnedItems count] > 0) {

                // NSLog(@"Return from Extension with success");

                // normal app extensions always complete on return.
                [self extensionCompleted:activityType
                       withItemsReturned:returnedItems];
            }
            else if (activityError != nil) {
                // NSLog(@"Activity failed to complete");
                [self completeAuthorization];
            }
        };

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            NSLog(@"iPad");
            if (self.view) {
                activityExtension.popoverPresentationController.sourceView = self.view;
            }
            else {
                NSLog(@"no view set");
            }
        }

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

- (NSString*) getEndpointUrl:(NSString *)serviceName
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

- (NSString*) getNameForService:(NSString *)serviceName
{
    NSString *retval = @"";
    
    NSDictionary *epDict = [services objectForKey:serviceName];
    if (epDict) {
        retval = [epDict objectForKey:@"engineName"];
    }
    
    return retval;
}

- (NSString*) getTokenId:(NSString *)serviceName
{
    NSString *retval = @"";
    
    NSDictionary *epDict = [services objectForKey:serviceName];
    
    if (epDict) {
        NSDictionary *tDict = [epDict objectForKey:@"token"];
        if (tDict) {

            // the key id might be a number rather than a string, so be extra carefull.
            // I spent 3h identifying that a random segfault had its roots here.
            id kidObj = [tDict objectForKey:@"kid"];
            if (kidObj != nil) {
                if ([[tDict objectForKey:@"kid"] isKindOfClass:[NSString class]]) {
                    retval = kidObj;
                }
                else if ([[tDict objectForKey:@"kid"] isKindOfClass:[NSNumber class]]) {
                    retval = [NSString stringWithFormat:@"%@", kidObj];
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

    NSDictionary *token = [self getServiceToken: serviceName];
    NSString     *url   = [self getEndpointUrl: serviceName
                                  forProtocol: protocolName];

    if ([url length] > 0) {
        // NSLog(@"%@", url);

        NSString *appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];

        // UIDevice *device = [UIDevice currentDevice];
        // NSString *deviceID = [[device identifierForVendor] UUIDString];

        NSNumber *ti = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

        // by default we use the access token.
        retval = [token objectForKey: @"access_token"];

        // we MUST use the access_token if there is confirmation key

        // FIXME: Conform to RFC 7800
        if ([[token allKeys] indexOfObject:@"kid"] != NSNotFound) {
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
             // NSLog(@"got dictionary %@", [self jsonEncode:epDict]);

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

        // NSLog(@"complete authorization");

        IMP imp = [callerObject methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        dispatch_async(dispatch_get_main_queue(), ^{
            func(callerObject, selector);
        });

    }
}

/**
 * extracts the authorzation token for a given service.
 */

- (NSDictionary*) getServiceToken:(NSString*)serviceName
{
    NSDictionary *dict = @{};

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
    }

    hash = [self urlTrim:hash];

    //NSLog(@"%@", hash);

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
- (NSString*)urlTrim:(NSString*)encodedString
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