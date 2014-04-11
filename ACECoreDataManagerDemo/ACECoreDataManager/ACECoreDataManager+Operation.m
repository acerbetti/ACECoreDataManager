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


#pragma mark - Fetch

- (NSArray *)fetchAllObjectsForInEntity:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)sortDescriptor
{
    return [self fetchAllObjectsForInEntity:entityName sortDescriptors:(sortDescriptor) ? @[sortDescriptor] : nil];
}

- (NSArray *)fetchAllObjectsForInEntity:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
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
