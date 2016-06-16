//
//  PersistentStore.m
//  eduID
//
//  Created by SII on 26.04.16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "PersistentStore.h"

///the key name for the persistent user name
NSString *const keyUserName = @"userName";

///the key name for the persistent user name
NSString *const keyEduIdServerURL = @"authEduIdServerURL";

///the key name for the persistent last token used at the eduId server
NSString *const keyLastEduIdToken = @"eduIdToken";

@interface PersistentStore()

@end

@implementation PersistentStore

//smoke test passed
-(void)saveDefaults
{
    //get defaults object
    NSUserDefaults *defaultSettings = [[NSUserDefaults alloc] initWithSuiteName:@"EduIdDemo"];    
    //set values
    [defaultSettings setObject:_eduIdUserName forKey:keyUserName];
    [defaultSettings setObject:[_eduIdServerURL absoluteString] forKey:keyEduIdServerURL];
    [defaultSettings setObject:_eduIdLastMainToken forKey:keyLastEduIdToken];
    
    //save defaults
    [defaultSettings synchronize];
}

//smoke test passed
-(void)restoreDefaults
{
    //get defaults object
    NSUserDefaults *defaultSettings = [[NSUserDefaults alloc] initWithSuiteName:@"EduIdDemo"];
    
    //get values or init when not found
    _eduIdUserName = [defaultSettings objectForKey:keyUserName];
    if (nil==_eduIdUserName)
    {//fetching failed -> init
        _eduIdUserName=[NSString new];
    }
    _eduIdServerURL = [NSURL URLWithString:[defaultSettings objectForKey:keyEduIdServerURL]];
    if (nil==_eduIdServerURL)
    {//fetching failed -> init
        _eduIdServerURL=[NSURL new];
    }
    _eduIdLastMainToken = [defaultSettings objectForKey:keyLastEduIdToken];
    if (nil==_eduIdLastMainToken)
    {//fetching failed -> init
        _eduIdLastMainToken=[NSString new];
    }
}

//synchronise on creation
-(id) init
{
    [self restoreDefaults];
    return self;
}

@end
