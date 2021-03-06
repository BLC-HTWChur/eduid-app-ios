//
//  Tokens+CoreDataProperties.m
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 23/06/16.
//  Copyright © 2016 SII. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Tokens+CoreDataProperties.h"

@implementation Tokens (CoreDataProperties)

@dynamic token;     // the token object (JSON)
@dynamic type;      // the type (client, access, service or app)
@dynamic target;    // the target (service for the token)
@dynamic subject;   // the subject (the app for which the token has been issued, ch.eduid.app for ourselves).

@end
