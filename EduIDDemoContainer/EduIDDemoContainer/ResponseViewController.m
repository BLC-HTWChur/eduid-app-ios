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

#import "ResponseDetailsViewContollerViewController.h"

@interface ResponseViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableViewOut;
@property (weak, nonatomic) IdNativeAppIntegrationLayer *nail;
@property (strong, atomic) NSString *targetServiceId;

@end

@implementation ResponseViewController

@synthesize tableViewOut;
@synthesize nail;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    nail = [main nail];
    // NSLog(@"Service list view (ResponseViewController) loaded");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if ([[segue identifier] isEqualToString:@"toCourseList"]) {
        ResponseDetailsViewContollerViewController *vc = [segue destinationViewController];

        // Pass any objects to the view controller here, like...
        [vc setServiceName: _targetServiceId];
    }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)ptableView numberOfRowsInSection:(NSInteger)section
{
    // NSLog(@"# service names %lu", [[nail serviceNames] count]);
    return [[nail serviceNames] count];
}

- (UITableViewCell *)tableView:(UITableView *)ptableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSLog(@"get cell at index %ld", indexPath.row);
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    ServiceTableViewCell *cell = [tableViewOut dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[ServiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:simpleTableIdentifier];
    }

    NSString *serviceId =(NSString*)[[nail serviceNames] objectAtIndex:indexPath.row];
//    NSLog(@"service id %@", serviceId);
    [cell setServiceId:serviceId];
    [cell setTokenId:[nail getTokenId:serviceId]];
    [cell setServiceName:[nail getNameForService:serviceId]];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSLog(@"select cell at index %ld", indexPath.row);

    _targetServiceId = (NSString*)[[nail serviceNames] objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"toCourseList" sender:self];
}


@end
