//
//  ACECoreDataManager+Operation.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

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

- (void)insertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName
{
    for (NSDictionary *dictionary in dataArray) {
        [self insertDictionary:dictionary inEntityName:entityName];
    }
}


#pragma mark - Remove

- (void)removeAllFromEntityName:(NSString *)entityName error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    // I want to delete all the objects together, disabling auto save
    BOOL oldAutoSave = self.autoSave;
    self.autoSave = NO;
    
    NSManagedObjectContext *context = self.managedObjectContext;
    NSArray *objects = [context executeFetchRequest:fetchRequest error:error];
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    
    // restore the previous mode and force a save
    self.autoSave = oldAutoSave;
    [self saveContext];
}

@end
