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
    for (NSDictionary *dictionary in dataArray) {
        [self insertDictionary:dictionary inEntityName:entityName];
    }
}

- (void)upsertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    // get the entity, and the index
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSAttributeDescription *index = [self indexedAttributeForEntity:entity];
    
    // sort the data array based on the index
    NSString *indexName = index.name;
    NSArray *sortedArray = [self sortArray:dataArray withIndex:indexName];
    NSArray *sortedObjects = [self sortManagedObjectsForEntity:entity withIndex:indexName];
    
    NSInteger dataIndex = 0;
    NSMutableSet *objectToDelete = [NSMutableSet set];
    
    id value1, value2;
    for (NSManagedObject *object in sortedObjects) {
        value1 = [object valueForKey:indexName];
        
        NSInteger copyIndex = dataIndex;
        do {
            value2 = sortedArray[dataIndex++];
        }
        while (value1);
    }
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

- (NSArray *)sortManagedObjectsForEntity:(NSEntityDescription *)entity withIndex:(NSString *)indexName
{
    // sort the existing object by the index
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:indexName ascending:YES]]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil) {
        return fetchedObjects;
    }
    return nil;
}

@end
