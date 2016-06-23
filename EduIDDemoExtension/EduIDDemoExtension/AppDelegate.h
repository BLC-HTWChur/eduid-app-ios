//
//  AppDelegate.h
//  EduIDDemoExtension
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

@import UIKit;

#import "../SharedDataStore.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain, readonly) SharedDataStore *eduIdDS;

@end

