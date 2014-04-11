//
//  ACECoreDataManager+Sync.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/10/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataManager+Sync.h"

@implementation ACECoreDataManager (Sync)

- (void)syncEntityName:(NSString *)entityName withDataFromArray:(NSArray *)dataArray
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
