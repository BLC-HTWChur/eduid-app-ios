//
//  PersistentStore.h
//  eduID
//
//  Created by SII on 26.04.16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This class manages all data needed to be kept persistent */
@interface PersistentStore : NSObject

///user name for authentication
@property (strong, nonatomic, readwrite) NSString* eduIdUserName;

///the authentication server
@property (strong, nonatomic, readwrite) NSURL* eduIdServerURL;

///the last main token
@property (strong, nonatomic, readwrite) NSString* eduIdLastMainToken;

/** save the properties of this object to the default settings of the app*/
-(void)saveDefaults;

/** load the properties of this object from the default settings of the app. If properties are not found they are initialised as empty. */
-(void)restoreDefaults;

//override
-(id) init;
@end
