//
//  SharedDataStrore.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 23/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

@import Foundation;
@import CoreData;

@interface SharedDataStore : NSObject

@property (readonly, strong, nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (id) init;
- (void)saveContext;

@end
