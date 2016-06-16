//
//  ViewController.m
//  EduIDDemoContainer
//
//  Created by SII on 26.05.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *eduIdLoginName;

@property (weak, nonatomic) IBOutlet UITextField *eduIdPassword;

@property (weak, nonatomic) IBOutlet UILabel *token;

@property (weak, nonatomic) IBOutlet UIButton *buttonAuthorise;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)authorButtonPressed:(id)sender
{
    //create json strings from text fields to command extension for permannt storage
    NSString *eduIdLoginNameText = _eduIdLoginName.text;
    NSString *eduIdPasswordText = _eduIdPassword.text;
    NSDictionary *serverDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                eduIdLoginNameText, CMD_SET_USER_NAME,
                                eduIdPasswordText, CMD_SET_USER_PW,
                                nil];
    NSData *serverJSON=[NSJSONSerialization dataWithJSONObject:serverDict
                                                       options:0
                                                         error:nil];
    NSString *serverJSONText=[[NSString alloc] initWithData:serverJSON encoding:NSUTF8StringEncoding];
    NSLog(@"%@", serverJSONText);
    
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
    NSLog(@"presentViewController end handler called");
    {
        //I know there is only a single object in the returned items.
        //So I only get this single item (There could be more elements there)
        NSExtensionItem *item = returnedItems[0];
        //I know there is only a single attachment in the item
        //So I get this
        NSItemProvider *itemProvider = item.attachments[0];
        //I know the item I want to get is a string and is signed as a string
        //The completion handler is called when extraction of this string is completed
        [itemProvider loadItemForTypeIdentifier:@"NSString"
                                        options:nil
                              completionHandler:^(NSString *returnText, NSError *error)
         {//delegate for code clarity
             [self completionLoadItemForTypeIdentifier:returnText
                                             withError:error];
         }];
    }
}

//handler to be performed when a string was loaded from returned extension data
//It is called by the completion handler (when data unpacking of the data sent by the extension is finished)
-(void) completionLoadItemForTypeIdentifier:(NSString *) returnText
                                  withError:(NSError *) error
{
    //This is the simplest way to set the UI element, no error checking whatsoever.
    //[self.textFromExtension setText:returnText];
    //I do not know why it is recommended to use a callback to set UI elements while being in a callback
    //This essentially makes an asynchronous call inside a asynchronous call...
    if (returnText)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
         {//set UI item asynchronously as we are in a callback
             NSLog(@"%s%s%@", __FILE__, __func__, returnText);
         }];
     }
    
}

@end
