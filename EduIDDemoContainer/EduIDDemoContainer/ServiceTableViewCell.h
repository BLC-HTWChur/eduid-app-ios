//
//  ServiceTableViewCell.h
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 26/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceTableViewCell : UITableViewCell

@property (retain, nonatomic) NSString *serviceId;
@property (retain, nonatomic) NSString *serviceName;
@property (retain, nonatomic) NSString *tokenId;

@end
