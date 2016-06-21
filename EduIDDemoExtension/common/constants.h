//
//  constants.h
//  EduIDDemoExtension
//
//  Created by SII on 12.06.16.
//  Copyright © 2016 SII. All rights reserved.
//

#ifndef constants_h
#define constants_h

//commands
#define CMD_SET_SERVER_URL @"CMD_SET_SERVER_URL" //command to set the server URL
#define CMD_SET_USER_NAME @"CMD_SET_USER_NAME" //command to set the user name
#define CMD_SET_USER_PW @"CMD_SET_USER_PW" //command to set the user name

// IOS Extension Hooks

// Use a fake URN, because there is no official URN for the differen OAUTH endpoints
// at the device level.
#define EDUID_EXTENSION_TYPE @"urn:ietf:params:oauth:assertion" // device level protocol
#define EDUID_EXTENSION_TITLE @"Protocol Endpoints"

#endif /* constants_h */
