//
//  ResponseDetailsViewContollerViewController.m
//  EduIDDemoContainer
//
//  Created by Christian Glahn on 16/07/16.
//  Copyright © 2016 SII. All rights reserved.
//

#import "ResponseDetailsViewContollerViewController.h"

#import "AppDelegate.h"
#import "IdNativeAppIntegrationLayer.h"
#import "CourseDetailsTableViewCell.h"

@interface ResponseDetailsViewContollerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *courseListTable;
@property (weak, nonatomic) IdNativeAppIntegrationLayer *nail;

@property (strong, atomic) NSArray *courseList;
@property (strong, atomic) NSNumber *status;
@property (strong, atomic) NSString *result;


@end


@implementation ResponseDetailsViewContollerViewController

@synthesize status;
@synthesize result;
@synthesize serviceName;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate *main = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    _nail = [main nail];

    // load user courses for the given name
    [self loadCourseListFromService];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) loadCourseListFromService
{
    NSString *url = [_nail getEndpointUrl:serviceName forProtocol:@"powertla.content.courselist"];
    NSString *authToken = [_nail getServiceAuthorization:serviceName forProtocol:@"powertla.content.courselist"];

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    if ([authToken length]) {
        sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", authToken]};
    }

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                            completionHandler:[self completeRequestHandler]];
    [task resume];

}

- (void (^)(NSData*, NSURLResponse*, NSError*)) completeRequestHandler
{
    return ^(NSData *data,
             NSURLResponse *response,
             NSError *error) {


        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            [self setStatus:[NSNumber numberWithInteger:httpResponse.statusCode]];

            if (data &&
                [data length]) {
                [self setResult:[[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding]];
            }

            if (httpResponse.statusCode == 500) {
                NSLog(@"Server Error");
            }
        }
        else {
            NSLog(@"other error!? %@", error);
        }
        
        [self loadingFromServiceCompleted];
    };
}

- (void) loadingFromServiceCompleted
{
    if (result) {
        NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
        _courseList = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:0
                                                        error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [_courseListTable reloadData];
        });
    }
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
    NSLog(@"%ld", [_courseList count]);
    return [_courseList count];
}

- (UITableViewCell *)tableView:(UITableView *)ptableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"get cell at index %ld", indexPath.row);
    static NSString *cellIdentifier = @"CourseDetailsCell";

    CourseDetailsTableViewCell *cell = [_courseListTable dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[CourseDetailsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:cellIdentifier];
    }

    [cell setCourse:[_courseList objectAtIndex: indexPath.row]];

    return cell;
}


@end
