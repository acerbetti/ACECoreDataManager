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

#pragma mark - Insert

- (NSManagedObject *)insertObjectInEntity:(NSString *)entityName
                      withAttributesBlock:(AttributesBlock)attributesBlock
                    andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{
    // create a new object
    __block NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                    inManagedObjectContext:self];
    
    // get the entity
    NSEntityDescription *entity = [self entityWithName:entityName];
    
    // populate the attributes
    if (attributesBlock != nil) {
        NSDictionary *attributes = [entity attributesByName];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
            
            id value = attributesBlock(key, attribute.attributeType);
            [object setValue:value forKey:key];
        }];
    }
    
    // populate the relationships
    if (relationshipsBlock != nil) {
        NSDictionary *relationships = [entity relationshipsByName];
        [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
            relationshipsBlock(key, object, relationship.destinationEntity, relationship.isToMany);
        }];
    }
    
    return object;
}


#pragma mark - Update

- (NSManagedObject *)updateObject:(NSManagedObject *)object
              withAttributesBlock:(AttributesBlock)attributesBlock
            andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{
    // make sure we are using the object in the same context
    object = [self safeObjectFromObject:object];
    if (object != nil) {
        
        // populate the attributes
        if (attributesBlock != nil) {
            NSDictionary *attributes = [object.entity attributesByName];
            [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
                
                id value = attributesBlock(key, attribute.attributeType);
                [object setValue:value forKey:key];
            }];
        }
        
        // populate the relationships
        if (relationshipsBlock != nil) {
            NSDictionary *relationships = [object.entity relationshipsByName];
            [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
                relationshipsBlock(key, object, relationship.destinationEntity, relationship.isToMany);
            }];
        }
    }
    return object;
}


#pragma mark - Upsert

- (NSManagedObject *)upsertObjectInEntity:(NSString *)entityName
                      withAttributesBlock:(AttributesBlock)attributesBlock
                    andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock
{
    if (attributesBlock != nil) {
        // get the object id
        NSAttributeDescription *index = [self indexedAttributeForEntityName:entityName];
        id objectId = attributesBlock(index.name, index.attributeType);
        
        // get the object to update
        NSManagedObject *object = [self fetchObjectForEntityName:entityName withUniqueId:objectId error:nil];
        if (object != nil) {
            return [self updateObject:object
                  withAttributesBlock:attributesBlock
                andRelationshipsBlock:relationshipsBlock];
            
        } else {
            return [self insertObjectInEntity:entityName
                          withAttributesBlock:attributesBlock
                        andRelationshipsBlock:relationshipsBlock];
        }
    }
    return nil;
}


#pragma mark - Delete

- (void)deleteObjectWithId:(id)objectId inEntityName:(NSString *)entityName
{
    NSManagedObject *managedObject = [self fetchObjectForEntityName:entityName withUniqueId:objectId error:nil];
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
