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

- (void)insertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    [self beginUpdates];
    
    for (NSDictionary *dictionary in dataArray) {
        [self insertDictionary:dictionary inEntityName:entityName];
    }
    
    [self endUpdates];
}

- (void)upsertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    [self beginUpdates];
    
    // get the entity, and the index
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSString *indexName = [[self indexedAttributeForEntity:entity] name];
    
    // sort the data array based on the index
    NSArray *sortedArray = [self sortArray:dataArray withIndex:indexName];
    NSArray *sortedObjects = [self sortManagedObjectsForEntityName:entityName withIndex:indexName];
    
    NSManagedObjectContext *context = self.managedObjectContext;
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
        [self insertDictionary:dataDict inEntityName:entityName];
    }
    
    [self endUpdates];
}


#pragma mark - Helpers

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
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:indexName ascending:YES];
    return [self fetchAllObjectsForInEntity:entityName sortDescriptor:sortDescriptor];
}

@end
