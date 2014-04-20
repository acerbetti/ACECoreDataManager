// NSManagedObjectContext+CRUD.m
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

#import "NSManagedObjectContext+CRUD.h"

@implementation NSManagedObjectContext (CRUD)

#pragma mark - Entity

- (NSEntityDescription *)entityWithName:(NSString *)entityName
{
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
}

- (NSAttributeDescription *)indexedAttributeForEntityName:(NSString *)entityName
{
    // looking for the index attribute
    NSDictionary *destAttributes = [[self entityWithName:entityName] attributesByName];
    for (NSString *key in destAttributes) {
        
        NSAttributeDescription *destAttr = [destAttributes objectForKey:key];
        if (destAttr.isIndexed) {
            return destAttr;
        }
    }
    return nil;
}


#pragma mark - Insert

- (NSManagedObject *)insertObjectInEntity:(NSString *)entityName
                       withAttibutesBlock:(AttributesBlock)attibutesBlock
                    andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{
    // create a new object
    __block NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                    inManagedObjectContext:self];
    
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
               
               id value = [dictionary objectForKey:key];
               if (value != nil) {
                   // go for the default upsert on the destination's entity
                   NSSet *set = [self upsertArrayOfDictionary:[dictionary objectForKey:key]
                                                  withObjects:[object valueForKey:key]
                                                 inEntityName:destinationEntity.name];
                   
                   // update the parent object
                   [parentObject setValue:set forKey:key];
               }
           }];
}


#pragma mark - Upsert

- (NSManagedObject *)upsertEntityName:(NSString *)entityName withDictionary:(NSDictionary *)dictionary
{
    // get the entity and the index
    NSString *indexName = [[self indexedAttributeForEntityName:entityName] name];
    
    // get the object to update
    NSManagedObject *object = [self fetchObjectForEntityName:entityName withUniqueId:dictionary[indexName]];
    if (object != nil) {
        return [self updateObject:object withDictionary:dictionary];
        
    } else {
        return [self insertDictionary:dictionary inEntityName:entityName];
    }
}


#pragma mark - Delete

- (void)deleteObjectWithId:(id)objectId inEntityName:(NSString *)entityName
{
    NSManagedObject *managedObject = [self fetchObjectForEntityName:entityName withUniqueId:objectId];
    [self deleteObject:managedObject];
}

- (void)deleteAllObjectsInEntityName:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSArray *objects = [self executeFetchRequest:fetchRequest error:nil];
    for (NSManagedObject *object in objects) {
        [self deleteObject:object];
    }
}

@end
