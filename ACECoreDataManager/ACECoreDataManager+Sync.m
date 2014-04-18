// ACECoreDataManager+Sync.m
//
// Copyright (c) 2014 Stefano Acerbetti
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ACECoreDataManager+Sync.h"
#import "ACECoreDataManager+Operation.h"

@implementation ACECoreDataManager (Sync)

#pragma mark - Insert Array

- (NSSet *)insertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    [self beginUpdates];
    
    NSMutableSet *set = [NSMutableSet set];
    for (NSDictionary *dictionary in dataArray) {
        [set addObject:[self insertDictionary:dictionary inEntityName:entityName]];
    }
    
    [self endUpdates];
    
    return [set copy];
}


#pragma mark - Upsert Array

- (NSSet *)upsertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    // get the entity, and the index
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSString *indexName = [[self indexedAttributeForEntity:entity] name];
    
    // call the main upserter
    return [self upsertArrayOfSortedDictionary:[self sortArray:dataArray withIndex:indexName]
                       andSortedObjects:[self sortManagedObjectsForEntityName:entityName withIndex:indexName]
                           inEntityName:entityName];
}

- (NSSet *)upsertArrayOfDictionary:(NSArray *)dataArray withObjects:(NSSet *)objects inEntityName:(NSString *)entityName
{
    // get the entity, and the index
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSString *indexName = [[self indexedAttributeForEntity:entity] name];
    
    // call the main upserter
    return [self upsertArrayOfSortedDictionary:[self sortArray:dataArray withIndex:indexName]
                       andSortedObjects:[objects sortedArrayUsingDescriptors:@[ [self sortDescriptorForKey:indexName] ]]
                                                                inEntityName:entityName];
}

- (NSSet *)upsertArrayOfSortedDictionary:(NSArray *)sortedArray andSortedObjects:(NSArray *)sortedObjects inEntityName:(NSString *)entityName
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSMutableSet *set = [NSMutableSet set];
    
    [self beginUpdates];
    
    NSUInteger dataIndex = 0, arrayCount = sortedArray.count;
    for (NSManagedObject *object in sortedObjects) {
        
        if (dataIndex < arrayCount) {
            dataIndex++;
            
        } else {
            [context deleteObject:object];
        }
    }
    
    // add the rest of the pack to core data
    for ( ; dataIndex < arrayCount; ++dataIndex) {
        NSDictionary *dataDict = sortedArray[dataIndex];
        [set addObject:[self insertDictionary:dataDict inEntityName:entityName]];
    }
    
    [self endUpdates];
    
    return [set copy];
}


#pragma mark - Helpers

- (NSSortDescriptor *)sortDescriptorForKey:(NSString *)indexName
{
    return [NSSortDescriptor sortDescriptorWithKey:indexName ascending:YES];
}

- (NSArray *)sortArray:(NSArray *)dataArray withIndex:(NSString *)indexName
{
    return [dataArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        id key1 = [obj1 valueForKey:indexName];
        id key2 = [obj2 valueForKey:indexName];
        return [key1 compare:key2];
    }];
}

- (NSArray *)sortManagedObjectsForEntityName:(NSString *)entityName withIndex:(NSString *)indexName
{
    return [self fetchAllObjectsForInEntity:entityName
                             sortDescriptor:[self sortDescriptorForKey:indexName]];
}

@end
