// NSManagedObjectContext+JSON.m
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

#import "NSManagedObjectContext+JSON.h"

@implementation NSManagedObjectContext (JSON)

- (id)insertDictionary:(NSDictionary *)dictionary
          inEntityName:(NSString *)entityName
             formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    return [self insertObjectInEntity:entityName
                  withAttributesBlock:^id(NSString *key, NSAttributeType attributeType) {
                      
                      id object = [dictionary objectForKey:key];
                      if ([object isKindOfClass:[NSNull class]]) {
                          return nil;
                          
                      } else if (formatter != nil) {
                          return [formatter valueForObject:object withType:attributeType];
                      }
                      
                      return object;
                      
                  } andRelationshipsBlock:^(NSString *key, NSManagedObject *parentObject, NSEntityDescription *destinationEntity, BOOL isToMany) {
                      
                      id object = [dictionary objectForKey:key];
                      if (object != nil && ![object isKindOfClass:[NSNull class]]) {
                          
                          // I'm assuming everything is new here, go with the default insert
                          if (isToMany) {
                              
                              // make sure we are dealing with an array
                              if (![object isKindOfClass:[NSArray class]]) {
                                  object = @[ object ];
                              }
                              
                              NSSet *set = [self insertArrayOfDictionary:object
                                                            inEntityName:destinationEntity.name
                                                               formatter:formatter];
                              
                              // update the parent object
                              [parentObject setValue:set forKey:key];
                              
                          } else {
                              // upsert the object
                              NSManagedObject *managedObject = [self upsertEntityName:destinationEntity.name
                                                                       withDictionary:object
                                                                            formatter:formatter];
                              
                              // connect to the parent object
                              [parentObject setValue:managedObject forKey:key];
                          }
                      }
                  }];
}



- (id)updateManagedObject:(NSManagedObject *)managedObject
           withDictionary:(NSDictionary *)dictionary
                formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    return [self updateManagedObject:managedObject
                 withAttributesBlock:^id(NSString *key, NSAttributeType attributeType) {
                     
                     // update only the existing keys
                     id object = [dictionary objectForKey:key];
                     if ([object isKindOfClass:[NSNull class]]) {
                         return nil;
                         
                     } else if (object != nil) {
                         
                         if (formatter != nil) {
                             return [formatter valueForObject:object withType:attributeType];
                         }
                         
                         return object;
                         
                     } else {
                         // the key is not part of the dictionary, pass the old value
                         return [managedObject valueForKey:key];
                     }
                     
                 } andRelationshipsBlock:^(NSString *key, NSManagedObject *parentObject, NSEntityDescription *destinationEntity, BOOL isToMany) {
                     
                     id object = [dictionary objectForKey:key];
                     if (object != nil) {
                         
                         if ([object isKindOfClass:[NSNull class]]) {
                             
                             // detect the NSNull case and remove the relationship
                             [parentObject setValue:nil forKey:key];
                             
                         } else {
                             if (isToMany) {
                                 // go for the default upsert on the destination's entity
                                 NSSet *set = [self compareArrayOfDictionary:object
                                                                 withObjects:[managedObject valueForKey:key]
                                                                inEntityName:destinationEntity.name
                                                                   formatter:formatter];
                                 
                                 // update the parent object
                                 [parentObject setValue:set forKey:key];
                                 
                             } else {
                                 // check if the object exists to avoid a query
                                 NSManagedObject *managedObject = [parentObject valueForKey:key];
                                 if (managedObject != nil) {
                                     
                                     // TODO: check if the ID is the same
                                     managedObject = [self updateManagedObject:managedObject
                                                                withDictionary:object
                                                                     formatter:formatter];
                                     
                                 } else {
                                     // upsert the object
                                     managedObject = [self upsertEntityName:destinationEntity.name
                                                             withDictionary:object
                                                                  formatter:formatter];
                                 }
                                 
                                 // connect to the parent object
                                 [parentObject setValue:managedObject forKey:key];
                             }
                         }
                     }
                 }];
}


- (id)upsertEntityName:(NSString *)entityName
        withDictionary:(NSDictionary *)dictionary
             formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    // get the entity and the index
    NSString *indexName = [[self indexedAttributeForEntityName:entityName] name];
    if (indexName.length > 0) {
        
        // get the object to update
        NSManagedObject *object = [self fetchObjectForEntityName:entityName withUniqueId:dictionary[indexName] error:nil];
        if (object != nil) {
            return [self updateManagedObject:object withDictionary:dictionary formatter:formatter];
        }
    }
    
    // object not found, insert a new one
    return [self insertDictionary:dictionary inEntityName:entityName formatter:formatter];
}

#pragma mark - Insert Array

- (NSSet *)insertArrayOfDictionary:(NSArray *)dataArray
                      inEntityName:(NSString *)entityName
                         formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    NSMutableSet *set = [NSMutableSet set];
    for (NSDictionary *dictionary in dataArray) {
        [set addObject:[self insertDictionary:dictionary inEntityName:entityName formatter:formatter]];
    }
    
    return [set copy];
}


#pragma mark - Upsert Array

- (NSSet *)upsertArrayOfDictionary:(NSArray *)dataArray
                      inEntityName:(NSString *)entityName
                         formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    return [self compareArrayOfDictionary:dataArray
                              withObjects:[self fetchAllObjectsForEntityName:entityName sortDescriptor:nil error:nil]
                             inEntityName:entityName
                                formatter:formatter];
}

- (NSSet *)compareArrayOfDictionary:(NSArray *)dataArray
                        withObjects:(id<NSFastEnumeration>)objects
                       inEntityName:(NSString *)entityName
                          formatter:(id<ACECoreDataJSONFormatter>)formatter
{
    // get the entity, and the index
    NSString *indexName = [[self indexedAttributeForEntityName:entityName] name];
    if (indexName == nil) {
        
        // the database doesn't have an index, delete all the previous objects
        for (NSManagedObject *object in objects) {
            [self deleteObject:object];
        }
        
        // then insert brand new objects
        return [self insertArrayOfDictionary:dataArray inEntityName:entityName formatter:formatter];
        
    } else {
        // return a set of objects
        NSMutableSet *set = [NSMutableSet set];
        
        // convert the data array in a dictionary
        NSMutableDictionary *dataMap =
        [NSMutableDictionary dictionaryWithObjects:dataArray
                                           forKeys:[dataArray valueForKey:indexName]];
        
        NSDictionary *dictionary;
        for (NSManagedObject *object in objects) {
            
            // make sure we are using the right context
            NSManagedObject *safeObject = [self safeObjectFromObject:object];
            
            id objectId = [object valueForKey:indexName];
            dictionary = dataMap[objectId];
            
            if (dictionary != nil) {
                // the object is also part of the data, update it
                [set addObject:[self updateManagedObject:safeObject withDictionary:dictionary formatter:formatter]];
                
                // now remove this dictionary
                [dataMap removeObjectForKey:objectId];
                
            } else {
                // delete it
                [self deleteObject:safeObject];
            }
        }
        
        // insert the rest of dictionary
        for (dictionary in dataMap.allValues) {
            [set addObject:[self insertDictionary:dictionary inEntityName:entityName formatter:formatter]];
        }
        
        // call the main upserter
        return [set copy];
    }
}

@end
