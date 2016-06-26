//
//  AppDelegate.h
//  EduIDDemoContainer
//
//  Created by SII on 26.05.16.
//  Copyright © 2016  HTW Chur. All rights reserved.
//

@import UIKit;

#import "IdNativeAppIntegrationLayer.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IdNativeAppIntegrationLayer *nail;


@end

