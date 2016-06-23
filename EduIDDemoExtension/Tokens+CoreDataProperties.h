//
//  Tokens+CoreDataProperties.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 23/06/16.
//  Copyright © 2016 SII. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Tokens.h"

NS_ASSUME_NONNULL_BEGIN

@interface Tokens (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *token;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSString *target;
@property (nullable, nonatomic, retain) NSString *subject;

@end

NS_ASSUME_NONNULL_END
