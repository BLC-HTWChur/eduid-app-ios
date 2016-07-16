//
//  ServiceTableViewCell.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 26/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "ServiceTableViewCell.h"

@interface ServiceTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *serviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *tokenIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *serviceIdLabel;

@end

@implementation ServiceTableViewCell

@synthesize serviceName = _serviceName;
@synthesize serviceId = _serviceId;
@synthesize tokenId = _tokenId;

- (ServiceTableViewCell*) init
{
    self = [super init];
    _serviceNameLabel.text = @"hello";
    _tokenIdLabel.text = @"world";
    return self;
}

- (void) setServiceId:(NSString *)serviceId
{
    _serviceName = serviceId;
    _serviceIdLabel.text = serviceId;
}

- (void) setServiceName:(NSString *)serviceName
{
    _serviceName = serviceName;
    _serviceNameLabel.text = serviceName;
}

- (void) setTokenId:(NSString *)tokenId
{
    if (tokenId && [tokenId length]) {
        _tokenId = tokenId;
    }
    else {
        _tokenId = @"simple bearer token";
    }
    _tokenIdLabel.text = _tokenId;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
