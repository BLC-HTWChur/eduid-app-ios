//
//  UserService+CoreDataProperties.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 24/06/16.
//  Copyright © 2016 SII. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "UserService.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserService (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *rsd;
@property (nullable, nonatomic, retain) NSString *baseurl;

@end

NS_ASSUME_NONNULL_END
