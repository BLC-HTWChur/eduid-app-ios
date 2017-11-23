//
//  Asn1Item.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 01/02/17.
//  Copyright © 2017 SII. All rights reserved.
//

#import "Asn1Item.h"

@implementation Asn1Item {
    NSNumber *dtype;
    NSData *content;
}

+ (Asn1Item*) createWithType:(NSInteger)type
{
    Asn1Item *item = [[Asn1Item alloc] init];

    return item;
}
+ (Asn1Item*) createWithData:(NSData*)data withType:(NSInteger)type
{
    return nil;
}
+ (Asn1Item*) createWithBase64:(NSString*)encodedString withType:(NSInteger)type
{
    return nil;
}

- (Asn1Item*) init
{
    return self;
}

- (Asn1Item*) initWithType:(NSInteger)coretype
{
    dtype = [[NSNumber alloc] initWithInteger: coretype];
    return self;
}


- (NSData*) getContent
{
    uint8_t tp = [dtype unsignedShortValue];

    NSLog(@"%02x", tp);



    return content;
}


@end
