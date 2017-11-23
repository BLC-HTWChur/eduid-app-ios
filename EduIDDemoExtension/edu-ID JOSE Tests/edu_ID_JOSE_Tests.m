//
//  edu_ID_JOSE_Tests.m
//  edu-ID JOSE Tests
//
//  Created by Christian Glahn on 01/02/17.
//  Copyright © 2017 SII. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../Asn1Item.h"

@interface edu_ID_JOSE_Tests : XCTestCase

@end

@implementation edu_ID_JOSE_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    Asn1Item *item = [Asn1Item createWithType:2];
    [item getContent];

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
