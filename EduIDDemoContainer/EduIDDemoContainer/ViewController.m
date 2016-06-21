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
    NSArray *protocols = @[@"gov.adlnet.xapi", @"org.imsglobal.qti"];

    NSData *serverJSON=[NSJSONSerialization dataWithJSONObject:protocols
                                                       options:0
                                                         error:nil];

    NSString *serverJSONText=[[NSString alloc] initWithData:serverJSON encoding:NSUTF8StringEncoding];
    NSLog(@"%@", serverJSONText);

    // The NSItemProvider is the hook for passing objects securely between apps
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:protocols
                                                         typeIdentifier:EDUID_EXTENSION_TYPE];

    // The NSExtensionItem is a container for explicitly passing information
    // between extensions and containers
    NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
    extensionItem.attachments = @[ itemProvider ];

    //create object to access extension
    UIActivityViewController *activityExtension = [[UIActivityViewController alloc] initWithActivityItems:@[extensionItem]
                                                                                    applicationActivities:nil];
    
    //define activities when the extension is finished
    activityExtension.completionWithItemsHandler=^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
    {
        if (returnedItems.count > 0) {
            // hand down to member function
            [self extensionCompleted:activityType
                         isCompleted:completed
                   withItemsReturned:returnedItems
                            hasError:activityError];
        }
        // No need to do anything because nothing has been received 
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
        [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
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
