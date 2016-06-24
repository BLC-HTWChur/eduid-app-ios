//
//  Configuration+CoreDataProperties.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 24/06/16.
//  Copyright © 2016 SII. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EduidConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface EduidConfig (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *cfg_name;
@property (nullable, nonatomic, retain) NSString *cfg_value;

@end

NS_ASSUME_NONNULL_END
