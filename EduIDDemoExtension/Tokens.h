//
//  Tokens.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 23/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tokens : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *subject;

@end

NS_ASSUME_NONNULL_END

#import "Tokens+CoreDataProperties.h"
