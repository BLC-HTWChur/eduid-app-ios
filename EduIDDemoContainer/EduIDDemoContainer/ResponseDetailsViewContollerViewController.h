//
//  ResponseDetailsViewContollerViewController.h
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 16/07/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResponseDetailsViewContollerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (atomic, strong) NSString *serviceName;

@end
