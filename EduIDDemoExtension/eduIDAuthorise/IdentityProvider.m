//
//  IdentityProvider.m
//  eduID
//
//  Created by SII on 26.04.16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "IdentityProvider.h"
#import "eduIdLogin.h"

@interface IdentityProvider()

/** manages the preparation and request tasks */
@property (strong,nonatomic) EduIdLogin *eduIdLogin;

@end

@implementation IdentityProvider

-(id) init
{
    _eduIdLogin=[[EduIdLogin alloc] init];
    return [super init];
}

-(BOOL) login
{
    NSString *token = [_eduIdLogin login];
    
    //check if valid
    if (nil == token)
    {
        return NO;
    }
    
    //@TODO save token
    
    return YES;
}

@end
