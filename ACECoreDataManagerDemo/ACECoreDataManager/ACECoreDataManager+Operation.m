// ACECoreDataManager+Operation.m
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

#import "ACECoreDataManager+Operation.h"

@implementation ACECoreDataManager (Operation)

#pragma mark - Insert

- (NSManagedObject *)insertObjectInEntity:(NSString *)entityName withDataBlock:(DataBlock)block
{
    // create a new object
    __block NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                            inManagedObjectContext:self.managedObjectContext];
    
    
    if (block != nil) {
        // populate the object
        NSDictionary *attributes = [[self entityWithName:entityName] attributesByName];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
            id value = block(key, attribute.attributeType);
            [object setValue:value forKey:key];
        }];
    }
    
    return object;
}

- (NSManagedObject *)insertDictionary:(NSDictionary *)dictionary inEntityName:(NSString *)entityName
{
    return [self insertObjectInEntity:entityName
                        withDataBlock:^id(NSString *key, NSAttributeType attributeType) {
                            // very simple basic case
                            return [dictionary objectForKey:key];
                        }];
}


#pragma mark - Fetch

- (NSArray *)fetchAllObjectsForInEntity:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)sortDescriptor
{
    return [self fetchAllObjectsForInEntity:entityName sortDescriptors:(sortDescriptor) ? @[sortDescriptor] : nil];
}

- (NSArray *)fetchAllObjectsForInEntity:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors
{
    return [self fetchAllObjectsForInEntity:entityName withPredicate:nil sortDescriptors:sortDescriptors];
}

- (NSManagedObject *)fetchObjectInEntity:(NSString *)entityName withUniqueId:(id)uniqueId
{
    // find the index name
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSString *indexName = [[self indexedAttributeForEntity:entity] name];
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", indexName];
    
    // build the predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, uniqueId];
    NSArray *results = [self fetchAllObjectsForInEntity:entityName withPredicate:predicate sortDescriptors:nil];
    if (results.count == 1) {
        return [results lastObject];
    }
    return nil;
}


#pragma mark - Fetch Helper

- (NSArray *)fetchAllObjectsForInEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        [self handleError:error];
    }
    return objects;
}


#pragma mark - Remove

- (void)removeAllFromEntityName:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    // I want to delete all the objects together, disabling auto save
    BOOL oldAutoSave = self.autoSave;
    self.autoSave = NO;
    
    NSError *error;
    NSManagedObjectContext *context = self.managedObjectContext;
    NSArray *objects = [context executeFetchRequest:fetchRequest error:&error];
    if (error == nil) {
        for (NSManagedObject *object in objects) {
            [context deleteObject:object];
        }        
    } else {
        [self handleError:error];
    }
    
    // restore the previous mode and force a save
    self.autoSave = oldAutoSave;
    [self saveContext];
}

@end
