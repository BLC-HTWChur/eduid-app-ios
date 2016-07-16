//
//  CourseDetailsTableViewCell.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 16/07/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "CourseDetailsTableViewCell.h"

@implementation CourseDetailsTableViewCell

@synthesize displayNameLabel;
@synthesize shortNameLabel;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setCourse: (NSDictionary*)courseDict
{
    if (courseDict) {
        displayNameLabel.text = [courseDict objectForKey:@"display_name"];
        shortNameLabel.text  = [courseDict objectForKey:@"short_name"];
    }
}

@end
