//
//  CourseDetailsTableViewCell.h
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 16/07/16.
//  Copyright © 2016 SII. All rights reserved.
//

@import UIKit;

@interface CourseDetailsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortNameLabel;

- (void) setCourse: (NSDictionary*)courseDict;

@end
