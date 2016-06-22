//
//  IdNativeAppIntegrationLayer.h
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 21/06/16.
//  Copyright © 2016 HTW Chur. All rights reserved.
//

#ifndef IdNativeAppIntegrationLayer_h
#define IdNativeAppIntegrationLayer_h

@import CoreData;
@import Foundation;

@interface IdNativeAppIntegrationLayer : NSObject

@property (readonly) NSDictionary *services;

/**
 * Issue the device level request to the authorizing app.
 *
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

/**
 * Returns an NSArray containing all service names returned by the
 * authorizing app.
 * 
 * Use this method to get an overview of all services that the app is
 * authorized to access.
 * 
 * After receiving the completion of the authorization request, the client 
 * may use this method for identifying the authorized services. 
 * 
 * Each service in this list has an authorization token and the requested 
 * protocol endpoints. A client MUST use only the service names in this list
 * with the requested protocols.
 */
- (NSArray*) serviceNames;

/**
 * Returns the protocol endpoint URL.
 * 
 * This method implements the RSD2 endpoint discovery for a service.
 *
 * The client uses this method for getting the exact service endpoint for 
 * a given protocol. 
 * 
 * If the requested serviceName or the requested protocol are not available,
 * then this function returns an empty string.
 */
- (NSString*) getServiceUrl:(NSString*) serviceName
                forProtocol:(NSString*) protocolName;

/**
 * Generates a Bearer token string for the requested authorization for a service
 * endpoint.
 * 
 * The getServiceAuthorization-method generates an appropriate Bearer Token for 
 * the given service endpoint.
 * 
 * The NAIL detects the use of flat Bearer tokens and JWT-Bearer for secured
 * service endpoints.
 * 
 * The client is responsible for setting the Bearer token in the appropriate
 * field for the service request. For RESTfull webservices the client MUST set
 * a "Authorization: Bearer" header. SOAP webservices or services using a 
 * different transport layer may use the appropriate authorization field.
 *
 * For JWT Bearer tokens, the client may pass OPTIONAL claims to be
 * included into the token. For flat Bearer tokens, these claims are ignored.
 *
 * If the service name or the protocol are not maintained by the NAIL, then this 
 * method will return nil.
 */
- (NSString*) getServiceAuthorization:(NSString*) serviceName
                          forProtocol:(NSString*) protocolName;

- (NSString*) getServiceAuthorization:(NSString*) serviceName
                          forProtocol:(NSString*) protocolName
                           withClaims:(NSDictionary*) claims;

/**
 * Serialize the service information.
 * 
 * This method is used for creating a JSON encoded dictionary of the services 
 * for storing persistently on the device.
 * 
 * The client is responsible to store the service information issued to it 
 * by the authorization app. Fire and forget clients MAY ignore serialization 
 * of service information, but have to request the information every time from
 * the authorization app.
 */
- (NSString*) serialize;

/**
 * Parse client level service information provided in a JSON encoded string.
 *
 * This method is used for parsing a JSON object returned by the serialize 
 * method. 
 * 
 * The client MUST initialise the NAIL from persistent data if present.
 */
- (void) parse: (NSString*) serviceSpec;

@end


#endif /* IdExtension_h */
