//
//  ACECoreDataManagerSynctCase.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ACECoreDataManager+Operation.h"
#import "ACECoreDataManager+Sync.h"

#define kEntityNameTest         @"Test"

@interface ACECoreDataManagerSynctCase : XCTestCase<ACECoreDataDelegate>

@end

@implementation ACECoreDataManagerSynctCase

- (void)setUp
{
    [super setUp];
    
    // make sure the delegate is set
    [[ACECoreDataManager sharedManager] setDelegate:self];
}

- (void)tearDown
{
    // remove all the test objects
    [[ACECoreDataManager sharedManager] removeAllFromEntityName:kEntityNameTest];
    [super tearDown];
}

- (void)testAddOneObject
{
    NSDictionary *testDictionary = [self dictionaryWithId:0];
    NSManagedObject *object = [[ACECoreDataManager sharedManager] insertDictionary:testDictionary inEntityName:kEntityNameTest];
    
    XCTAssertEqualObjects( [testDictionary valueForKey:@"uid"], [object valueForKey:@"uid"], @"Key doesn't match");
    XCTAssertEqualObjects( [testDictionary valueForKey:@"name"], [object valueForKey:@"name"], @"Name doesn't match");
}

- (void)testAddMultipleObjects
{
    NSArray *dictionaries = @[ [self dictionaryWithId:1], [self dictionaryWithId:2], [self dictionaryWithId:3] ];
    [[ACECoreDataManager sharedManager] insertArrayOfDictionary:dictionaries inEntityName:kEntityNameTest];
    
    NSArray *objects = [[ACECoreDataManager sharedManager] fetchAllObjectsForInEntity:kEntityNameTest
                                                                       sortDescriptor:nil];
    
    XCTAssertEqual(dictionaries.count, objects.count, @"Object count mismatch");
}


#pragma mark - Helpers

- (NSDictionary *)dictionaryWithId:(NSInteger)integer
{
    return @{ @"uid": [@(integer) stringValue], @"name": [NSString stringWithFormat:@"Object-%d", integer] };
}


#pragma mark - Core Data Delegate

- (NSURL *)modelURLForManager:(ACECoreDataManager *)manager
{
    return [[NSBundle mainBundle] URLForResource:@"ACECoreDataManagerDemo" withExtension:@"momd"];
}

- (NSURL *)storeURLForManager:(ACECoreDataManager *)manager
{
    NSURL *documentFolder = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentFolder URLByAppendingPathComponent:@"TestDB.sqlite"];
}

@end
