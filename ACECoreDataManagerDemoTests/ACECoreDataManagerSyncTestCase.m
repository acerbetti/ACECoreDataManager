//
//  ACECoreDataManagerSyncTestCase.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ACECoreDataManager+Sync.h"

@interface ACECoreDataManagerSyncTestCase : XCTestCase<ACECoreDataDelegate>

@end

@implementation ACECoreDataManagerSyncTestCase

- (void)setUp
{
    [super setUp];
    
    // make sure the delegate is set
    [[ACECoreDataManager sharedManager] setDelegate:self];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


#pragma mark - Core Data Delegate

- (NSURL *)modelURLForManager:(ACECoreDataManager *)manager
{
    return [[NSBundle mainBundle] URLForResource:@"TestModel" withExtension:@"momd"];
}

- (NSURL *)storeURLForManager:(ACECoreDataManager *)manager
{
    NSURL *documentFolder = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentFolder URLByAppendingPathComponent:@"TestDB.sqlite"];
}

@end
