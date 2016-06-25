//
//  ExtensionController.h
//  EduIDDemoExtension
//
//  Created by Christian Glahn on 25/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

@import UIKit;

#import "../SharedDataStore.h"
#import "../OAuthRequester.h"

@interface ExtensionController : UIViewController

@property (retain, atomic) NSExtensionContext *origContext;

@property (atomic, retain) SharedDataStore *eduIdDS;
@property (atomic, retain) OAuthRequester *oauth;

@property (atomic, retain) NSArray *requestData;

- (void) requestDone;

@end
