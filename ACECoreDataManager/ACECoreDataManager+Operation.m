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
#import "ACECoreDataManager+Sync.h"

@implementation ACECoreDataManager (Operation)

#pragma mark - Insert

- (NSManagedObject *)insertObjectInEntity:(NSString *)entityName
                       withAttibutesBlock:(AttributesBlock)attibutesBlock
                    andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{
    // create a new object
    __block NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                            inManagedObjectContext:self.managedObjectContext];
    
    // get the entity
    NSEntityDescription *entity = [self entityWithName:entityName];
    
    // populate the attributes
    if (attibutesBlock != nil) {
        NSDictionary *attributes = [entity attributesByName];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
            id value = attibutesBlock(key, attribute.attributeType);
            [object setValue:value forKey:key];
        }];
    }
    
    // populate the relationships
    if (relationshipsBlock != nil) {
        NSDictionary *relationships = [entity relationshipsByName];
        [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
            
            // I care only about the to many relationship, since core data will fix the inverse
            if (relationship.isToMany) {
                relationshipsBlock(key, object, relationship.destinationEntity);
            }
        }];
    }
    
    return object;
}

- (NSManagedObject *)insertDictionary:(NSDictionary *)dictionary inEntityName:(NSString *)entityName
{
    return [self insertObjectInEntity:entityName
            withAttibutesBlock:^id(NSString *key, NSAttributeType attributeType) {
                
                // very simple basic case
                return [dictionary objectForKey:key];
                
            } andRelationshipsBlock:^(NSString *key, NSManagedObject *parentObject, NSEntityDescription *destinationEntity) {
                
                // I'm assuming everything is new here, go with the default insert
                NSSet *set = [self insertArrayOfDictionary:[dictionary objectForKey:key]
                                              inEntityName:destinationEntity.name];
                
                // update the parent object
                [parentObject setValue:set forKey:key];
            }];
}


#pragma mark - Update

- (NSManagedObject *)updateObject:(NSManagedObject *)object
               withAttibutesBlock:(AttributesBlock)attibutesBlock
            andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{    
    // populate the attributes
    if (attibutesBlock != nil) {
        NSDictionary *attributes = [object.entity attributesByName];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
            id value = attibutesBlock(key, attribute.attributeType);
            [object setValue:value forKey:key];
        }];
    }
    
    // populate the relationships
    if (relationshipsBlock != nil) {
        NSDictionary *relationships = [object.entity relationshipsByName];
        [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
            
            // I care only about the to many relationship, since core data will fix the inverse
            if (relationship.isToMany) {
                relationshipsBlock(key, object, relationship.destinationEntity);
            }
        }];
    }

    return object;
}

- (NSManagedObject *)updateObject:(NSManagedObject *)object withDictionary:(NSDictionary *)dictionary
{
    return [self updateObject:object
           withAttibutesBlock:^id(NSString *key, NSAttributeType attributeType) {
               
               // update only the existing keys
               id value = [dictionary objectForKey:key];
               if (value != nil) {
                   return value;
                   
               } else {
                   // the key is not part of the dictionary, pass the old value
                   return [object valueForKey:key];
               }
               
           } andRelationshipsBlock:^(NSString *key, NSManagedObject *parentObject, NSEntityDescription *destinationEntity) {
               
               // go for the default upsert on the destination's entity
               NSSet *set = [self upsertArrayOfDictionary:[dictionary objectForKey:key]
                                              withObjects:[object valueForKey:key]
                                             inEntityName:destinationEntity.name];
               
               // update the parent object
               [parentObject setValue:set forKey:key];
           }];
}

- (NSManagedObject *)upsertEntityName:(NSString *)entityName withDictionary:(NSDictionary *)dictionary
{
    // get the entity and the index
    NSEntityDescription *entity = [self entityWithName:entityName];
    NSString *indexName = [[self indexedAttributeForEntity:entity] name];
    
    // get the object to update
    NSManagedObject *object = [self fetchObjectInEntity:entityName withUniqueId:dictionary[indexName]];
    if (object != nil) {
        return [self updateObject:object withDictionary:dictionary];
        
    } else {
        return [self insertDictionary:dictionary inEntityName:entityName];
    }
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
    
    // I want to delete all the objects together
    [self beginUpdates];
    
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
    
    [self endUpdates];
}

@end
