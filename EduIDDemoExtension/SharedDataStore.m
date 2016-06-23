//
//  SharedDataStrore.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 23/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "SharedDataStore.h"

@interface SharedDataStore ()

@end

@implementation SharedDataStore

@synthesize managedObjectContext       = _moctxt;
@synthesize managedObjectModel         = _mom;
@synthesize persistentStoreCoordinator = _psc;

NSString *SHARED_GROUP_CONTEXT = @"group.mobinaut.test";

- (id) init
{
    self = [super init];
    
    if (!self) return nil;
    
    [self setupCoreData];
    
    return self;
}

- (NSURL*) dataDirectory
{
    NSURL *retval =[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:SHARED_GROUP_CONTEXT];
    return retval;
}

- (void) setupCoreData
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EduidData"
                                              withExtension:@"momd"];
    
    _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_mom];
    
    _moctxt = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_moctxt setPersistentStoreCoordinator:_psc];
    
    NSURL *storeURL = [[self dataDirectory] URLByAppendingPathComponent:@"EduidData.sqlite"];

    if (storeURL != nil) {
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSError *error = nil;
            
            NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
            
            NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                         configuration:nil
                                                                   URL:storeURL
                                                               options:nil
                                                                 error:&error];
            
            NSAssert(store != nil, @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
        });
        
    }
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    if (_moctxt != nil) {
        NSError *error = nil;
        if ([_moctxt hasChanges] && [_moctxt save:&error]) {
            NSLog(@"data stored");
        }
    }
}

@end
