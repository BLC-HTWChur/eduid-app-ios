//
//  ActionViewController.m
//  eduIDAuthorise
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#include "../common/constants.h" //common values for the whole project

#import "ActionViewController.h"
#import "PersistentStore.h"
#import "IdentityProvider.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController ()

@property (weak, nonatomic) IBOutlet UITextField *eduIdLoginName;

@property (weak, nonatomic) IBOutlet UITextField *eduIdPassword;

@property (weak, nonatomic) IBOutlet UILabel *serverURL;

@property (weak, nonatomic) IBOutlet UIButton *buttonLogIn;

@property (weak, nonatomic) IBOutlet UIView *canvas;

@property (strong, nonatomic) PersistentStore *persistentStore;

@property (strong, nonatomic) IdentityProvider *identityProvider;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _identityProvider=[[IdentityProvider alloc] init];
    //I know there is only a simple text object in the array of data which was given to the extension.
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    if(nil == _persistentStore)
    {
        self.persistentStore=[[PersistentStore alloc] init];
    }
    [itemProvider loadItemForTypeIdentifier: EDUID_EXTENSION_TYPE
                                    options:nil
                          completionHandler:^(NSData *receivedJson, NSError *error)
     {//handler to be performed when data receiving is finished
         //delegated for code clarity
         [self completionLoadItemForTypeIdentifier:receivedJson
                                         withError:error];
     }];

}

//This is called by the completion handler (when data unpacking of the data sent by the extension is finished)
-(void) completionLoadItemForTypeIdentifier:(NSData *) receivedData
                                  withError:(NSError *) error
{
    //We expect to find a command in the dictionery. It will be stored here
    NSString *cmdContent;
    //parse received data to dictionary
    NSDictionary* receivedDataJson = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
    //search for command CMD_SET_SERVER_URL
    cmdContent=receivedDataJson[CMD_SET_SERVER_URL];
    if (nil != cmdContent)
    {//command was found
        [self setServerUrl:cmdContent];
        [self setUiCalledFromExtensionShell];
        //[self extensionDone]; //seems not to work from here (Why ever)
        return;
    }
    //all shell possibilities are exhausted -> we were called by a container
    [self setUiCalledFromContainer];
    //search for command CMD_SET_USER_NAME
    cmdContent=receivedDataJson[CMD_SET_USER_NAME];
    if (nil != cmdContent)
    {//command was found
        [self setUserName:cmdContent];
    }
    //search for command CMD_SET_USER_PW
    cmdContent=receivedDataJson[CMD_SET_USER_PW];
    if (nil != cmdContent)
    {//command was found
        [self setUserPw:cmdContent];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Button reaction -> log in
- (IBAction)logIn:(id)sender {
    [self authoriseAtEduIdService];
}

//button to finish extension was pressed
- (IBAction)done {
    //we are finished
    [self extensionDone];
}

-(void) setServerUrl:(NSString *) serverURL
{
    _serverURL.text=serverURL;
    _persistentStore.eduIdServerURL=[NSURL URLWithString:serverURL];
    [_persistentStore saveDefaults];
}

-(void) setUserName:(NSString *) userName
{
    _eduIdLoginName.text=userName;
    _persistentStore.eduIdUserName=userName;
    [_persistentStore saveDefaults];
}

-(void) setUserPw:(NSString *) userPw
{
    _eduIdPassword.text=userPw;
}

//When we were called from the shell of the extension, we only want to display the server URL
-(void) setUiCalledFromExtensionShell
{
    [_eduIdLoginName setEnabled:NO];
    [_eduIdPassword setEnabled:NO];
    [_buttonLogIn setEnabled:NO];
}

-(void) setUiCalledFromContainer
{
    [_eduIdLoginName setEnabled:YES];
    [_eduIdPassword setEnabled:YES];
    [_buttonLogIn setEnabled:YES];
}

/** 
 * starts the process of authorisation at the eduID service
 */
-(void) authoriseAtEduIdService
{
    //This is all dumyy code to simulate authorisation and to learn how to program properly ...
    [self viewEnableGUI:NO];
    _canvas.backgroundColor=[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.5];
    [_identityProvider login];
    if([_eduIdLoginName.text caseInsensitiveCompare:@"OK"] == NSOrderedSame)
    {
        _canvas.backgroundColor=[UIColor colorWithRed:0.2 green:0.82 blue:0.2 alpha:0.5];
    }
    else
    {
        _canvas.backgroundColor=[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.5];
    }
    [self viewEnableGUI:YES];
}

/** enable or disable the whole GUI
 @param inEnable: YES: enable GUI, NO: disabl GUI */
-(void)viewEnableGUI:(BOOL) inEnable
{
    [_eduIdLoginName setEnabled:inEnable];
    [_eduIdLoginName setEnabled:inEnable];
    [_eduIdPassword setEnabled:inEnable];
    [_buttonLogIn setEnabled:inEnable];
}

//we are done with the extension, return to caller
-(void) extensionDone
{
    //create json string of server url to command extension for permanent storage
    NSString *serverUrlText = _serverURL.text;
    NSDictionary *serverDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                serverUrlText, CMD_SET_SERVER_URL, nil];

    //create structure to return data to the calling app
    NSExtensionItem* extensionItem = [[NSExtensionItem alloc] init];
    //Place the data in the transfer data structure.

    [extensionItem setAttributedTitle:[[NSAttributedString alloc] initWithString:EDUID_EXTENSION_TITLE]];

    [extensionItem setAttachments:@[[[NSItemProvider alloc] initWithItem:serverDict
                                                          typeIdentifier:EDUID_EXTENSION_TYPE]]];

    // call directly because the extension terminates after returning the data.
    [self.extensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
}

@end
