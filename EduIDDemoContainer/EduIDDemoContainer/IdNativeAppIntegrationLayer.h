//
//  IdExtension.h
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 21/06/16.
//  Copyright © 2016 BLC. All rights reserved.
//

#ifndef IdNativeAppIntegrationLayer_h
#define IdNativeAppIntegrationLayer_h

@import CoreData;
@import Foundation;

@interface IdNativeAppIntegrationLayer : NSObject

@property (readonly, retain) NSDictionary *endpoints;

/**
 * requestProtocols: @[protocolList] forObject: caller withSelector: selector
 *
 * Main NAIL interface. The app uses this to obtain an accesstoken for one or 
 * more service endpoints. 
 *
 * This method is normally called via the ViewController.
 *
 * Example:
 * [idNAIL requestProtocols: @[@"org.imsglobal.qti", @"gov.adlnet.xapi"]
 *                forObject: self
 *             withSelector: @selector(myCallbackMethod)];
 * 
 * The callback method MUST NOT expect any parameters. Instead it should 
 * access the protocols property accessors.
 */
- (void) requestProtocols:(NSArray*)protocolList
                forObject:(id)object
             withSelector:(SEL)selector;

- (NSArray*) getAllEndpoints;

- (NSString*) getEndpointUrl:(NSString*) endpointName
                withProtocol:(NSString*) protocolName;

- (NSDictionary*) getEndpointToken:(NSString*) endpointName;

/**
 * generates a JWT for the request authorization for
 */
- (NSString*) getEndpointAuthorization:(NSString*) endpointName
                          withProtocol:(NSString*) protocolName
                            withClaims:(NSDictionary*) claims;

@end


#endif /* IdExtension_h */
