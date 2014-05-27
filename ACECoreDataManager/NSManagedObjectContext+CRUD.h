// NSManagedObjectContext+CRUD.h
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

#import "ACECoreDataManager.h"

typedef id (^AttributesBlock)(NSString *key, NSAttributeType attributeType);

typedef void (^RelationshipsBlock)(NSString *key, NSManagedObject *parentObject,
                                   NSEntityDescription *destinationEntity, BOOL isToMany);



@interface NSManagedObjectContext (CRUD)



///-----------------------------------------------------------
/// @name Insert Helpers
///-----------------------------------------------------------

- (id)insertObjectInEntity:(NSString *)entityName
       withAttributesBlock:(AttributesBlock)attributesBlock
     andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock;




///-----------------------------------------------------------
/// @name Update Helpers
///-----------------------------------------------------------

- (id)updateManagedObject:(NSManagedObject *)managedObject
      withAttributesBlock:(AttributesBlock)attributesBlock
    andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock;




///-----------------------------------------------------------
/// @name Upsert Helpers
///-----------------------------------------------------------

- (id)upsertObjectInEntity:(NSString *)entityName
       withAttributesBlock:(AttributesBlock)attributesBlock
     andRelationshipsBlock:(RelationshipsBlock)relationshipsBlock;



///-----------------------------------------------------------
/// @name Delete Helpers
///-----------------------------------------------------------

- (void)deleteObjectWithId:(id)objectId inEntityName:(NSString *)entityName;
- (void)deleteAllObjectsInEntityName:(NSString *)entityName;

@end
