//
//  ACECoreDataManagerSynctCase.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ACECoreDataManager.h"

#define kEntityNameTest         @"Test"

@interface ACECoreDataManagerSynctCase : XCTestCase<ACECoreDataDelegate>
@property (nonatomic, weak) NSManagedObjectContext *context;
@end

@implementation ACECoreDataManagerSynctCase

- (void)setUp
{
    [super setUp];
    
    // make sure the delegate is set
    [[ACECoreDataManager sharedManager] setDelegate:self];
    
    // quick link to the context
    self.context = [[ACECoreDataManager sharedManager] managedObjectContext];
}

- (void)tearDown
{
    // remove all the test objects
    [self.context deleteAllObjectsInEntityName:kEntityNameTest];
    [super tearDown];
}

- (void)testAddOneObject
{
    NSDictionary *testDictionary = [self dictionaryWithId:0];
    NSManagedObject *object = [self.context insertDictionary:testDictionary
                                                inEntityName:kEntityNameTest
                                                   formatter:nil];
    
    XCTAssertEqualObjects( [testDictionary valueForKey:@"uid"], [object valueForKey:@"uid"], @"Key doesn't match");
    XCTAssertEqualObjects( [testDictionary valueForKey:@"name"], [object valueForKey:@"name"], @"Name doesn't match");
}

- (void)testAddMultipleObjects
{
    NSArray *dictionaries = @[ [self dictionaryWithId:1], [self dictionaryWithId:2], [self dictionaryWithId:3] ];
    NSSet *objectSet = [self.context insertArrayOfDictionary:dictionaries
                                                inEntityName:kEntityNameTest
                                                   formatter:nil];
    
    XCTAssertEqual(dictionaries.count, objectSet.count, @"Object count mismatch");
}

- (void)testFetchOneObject
{
    NSArray *dictionaries = @[ [self dictionaryWithId:1], [self dictionaryWithId:2], [self dictionaryWithId:3] ];
    [[[ACECoreDataManager sharedManager] managedObjectContext] insertArrayOfDictionary:dictionaries
                                                                          inEntityName:kEntityNameTest
                                                                             formatter:nil];
    
    NSManagedObject *object = [self.context fetchObjectForEntityName:kEntityNameTest
                                                        withUniqueId:[@(2) stringValue]
                                                               error:nil];
    
    NSDictionary *testDictionary = dictionaries[1];
    XCTAssertEqualObjects( [testDictionary valueForKey:@"name"], [object valueForKey:@"name"], @"Name doesn't match");
}

- (void)testUpsertToEmptyData
{
    NSArray *dictionaries = @[ [self dictionaryWithId:1], [self dictionaryWithId:2], [self dictionaryWithId:3] ];
    [self.context upsertArrayOfDictionary:dictionaries
                             inEntityName:kEntityNameTest
                                formatter:nil];
    
    NSArray *objects = [self.context fetchAllObjectsForEntityName:kEntityNameTest
                                                   sortDescriptor:nil
                                                            error:nil];
    
    XCTAssertEqual(dictionaries.count, objects.count, @"Object count mismatch");
}

- (void)testUpsertFromEmptyData
{
    NSArray *dictionaries = @[ [self dictionaryWithId:1], [self dictionaryWithId:2], [self dictionaryWithId:3] ];
    [self.context insertArrayOfDictionary:dictionaries
                             inEntityName:kEntityNameTest
                                formatter:nil];
    
    NSArray *objects = [self.context fetchAllObjectsForEntityName:kEntityNameTest
                                                   sortDescriptor:nil
                                                            error:nil];
    
    XCTAssertEqual(dictionaries.count, objects.count, @"Insert count mismatch");
    
    
    [self.context upsertArrayOfDictionary:nil
                             inEntityName:kEntityNameTest
                                formatter:nil];
    
    objects = [self.context fetchAllObjectsForEntityName:kEntityNameTest
                                          sortDescriptor:nil
                                                   error:nil];
    
    XCTAssertEqual(0, objects.count, @"Final count mismatch");
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
