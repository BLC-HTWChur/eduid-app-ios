//
//  ResponseViewController.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 25/06/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "ResponseViewController.h"
#import "AppDelegate.h"
#import "IdNativeAppIntegrationLayer.h"
#import "ServiceTableViewCell.h"

@interface ResponseViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IdNativeAppIntegrationLayer *nail;

@end

@implementation ResponseViewController

@synthesize tableView;
@synthesize nail;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    nail = [main nail];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (NSInteger)tableView:(UITableView *)ptableView numberOfRowsInSection:(NSInteger)section
{
    return [[nail serviceNames] count];
}

- (UITableViewCell *)tableView:(UITableView *)ptableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"get cell at index %@", indexPath);
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    ServiceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[ServiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:simpleTableIdentifier];
    }
    NSString *serviceId =(NSString*)[[nail serviceNames] objectAtIndex:indexPath.row];
    [cell setServiceId:serviceId];
    [cell setTokenId:[nail getTokenId:serviceId]];
    [cell setServiceName:[nail getNameForService:serviceId]];
    
    return cell;
}



@end
