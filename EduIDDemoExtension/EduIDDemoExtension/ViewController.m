//
//  ViewController.m
//  EduIDDemoExtension
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "../OAuthRequester.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *serverURLText;

@property (weak, nonatomic) IBOutlet UIButton *setServerURL;

@property (readonly) OAuthRequester *req;

@end

@implementation ViewController {
    NSInteger cntUserAuth;
}

@synthesize req;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    req = [OAuthRequester oauthWithUrlString:@"https://eduid.htwchur.ch/eduid/eduid.php/token"];

    NSString *tString =@"{\"kid\":\"1234test-14\",\"mac_key\":\"helloWorld\",\"mac_algorithm\":\"HS256\",\"client_id\":\"ch.htwchur.eduid.ios.0\",\"access_token\":\"acf5acfaa58665e6e74f9d03e504b7dce7bc9568\"}";

    cntUserAuth = 0;
    [req setDeviceToken:tString];

    [req registerReceiver:self withSelector:@selector(requestDone)];
    [req postClientCredentials];
}

- (void) requestDone
{
    NSLog(@"Oauth request completed with %@", [req status]);

    if ([req result])
        NSLog(@"request result %@", [req result]);

    if ([req deviceToken])
        NSLog(@"device token %@", [req deviceToken]);
    if ([req clientToken])
        NSLog(@"client token %@", [req clientToken]);
    if ([req userToken])
        NSLog(@"user token %@", [req userToken]);

    if ([[req status]  isEqual: @200] &&
        [req clientToken] &&
        cntUserAuth == 0) {
        NSLog(@"try to authenticate");
        cntUserAuth = cntUserAuth + 1;
        [req postPassword:@"test1234" forUser:@"cgl@htwchur.ch"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** action to button to set the server URL
 */
- (IBAction)setServerURL:(id)sender {
    
    //create json string of server url to command extension for permannt storage
    NSString *serverUrlText = _serverURLText.text;
    NSDictionary *serverDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          serverUrlText, CMD_SET_SERVER_URL, nil];
    NSData *serverJSON=[NSJSONSerialization dataWithJSONObject:serverDict
                                                       options:0
                                                         error:nil];
    NSString *serverJSONText=[[NSString alloc] initWithData:serverJSON encoding:NSUTF8StringEncoding];
    NSLog(@"%s%s%@", __FILE__, __FUNCTION__, serverJSONText);
    
    //put the data to be sent into an array
    NSArray *dataToShare = @[serverJSON];
    //create object to access extension
    UIActivityViewController *activityExtension = [[UIActivityViewController alloc] initWithActivityItems:dataToShare                                                                             applicationActivities:nil];
    
    //define activities when the extension is finished
    activityExtension.completionWithItemsHandler=^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
    {//delegate to method for code clarity
        [self extensionCompleted:activityType
                     isCompleted:completed
               withItemsReturned:returnedItems
                        hasError:activityError];
    };
    //hand over to iOS to handle the extension
    [self presentViewController:activityExtension
                       animated:YES
                     completion:nil];
}

//This method is called by the completion handler (when the extension is finished)
//It unpacks the data sent by the extension.
-(void)extensionCompleted:activityType
              isCompleted:(BOOL)completed
        withItemsReturned:(NSArray*)returnedItems
                 hasError:(NSError*)activityError
{
    //Let's have a look at what comes back
    NSExtensionItem *item = returnedItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    NSLog(@"presentViewController end handler called");
    {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeData
                                        options:nil
                              completionHandler:^(NSData *receivedData, NSError *error)
         {//handler to be performed when data receiving is finished
             //delegated for code clarity
             [self completionLoadItemForTypeIdentifier:receivedData
                                             withError:error];
         }];
        
    }
}

//This is called by the completion handler (when data unpacking of the data sent by the extension is finished)
-(void) completionLoadItemForTypeIdentifier:(NSData *) receivedData
withError:(NSError *) error
    {
        if (nil != receivedData)
        {
            //We expect to find a command in the dictionery. It will be stored here
            NSString *cmdContent;
            //parse received data to dictionary
            NSDictionary* receivedDataJson = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
            //search for command CMD_SET_SERVER_URL
            NSLog(@"%s, %s: process received data", __FILE__, __func__);
            //search for command CMD_SET_SERVER_URL
            cmdContent=receivedDataJson[CMD_SET_SERVER_URL];
            cmdContent=[NSString stringWithFormat:@"Return: %@", cmdContent];
            if (nil != cmdContent)
            {//command was found
                _serverURLText.text=cmdContent;
            }
        }
        else
        {
            NSLog(@"%s, %s: No content received", __FILE__, __func__);
        }
}



@end
