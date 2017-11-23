//
//  Asn1Item.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 01/02/17.
//  Copyright © 2017 SII. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Asn1Item : NSObject

+ (Asn1Item*) createWithType:(NSInteger)type;
+ (Asn1Item*) createWithData:(NSData*)data withType:(NSInteger)type;
+ (Asn1Item*) createWithBase64:(NSString*)encodedString withType:(NSInteger)type;

- (NSData*) getContent; // returns ASN1 String (type, len, content)
@end
