// NSManagedObjectContext+Common.m
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

#import "NSManagedObjectContext+Common.h"

@implementation NSManagedObjectContext (Common)

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

- (id)safeObjectFromObject:(NSManagedObject *)object
{
    if (object != nil && object.managedObjectContext != self) {
        
        // first, make sure is not temporary
        if ([object.managedObjectContext obtainPermanentIDsForObjects:@[object] error:nil]) {
            
            // second, load the object in the current context
            return [self existingObjectWithID:object.objectID error:nil];
        }
    }
    return object;
}


- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName
                           sortDescriptor:(NSSortDescriptor *)sortDescriptor
                                    error:(NSError **)error
{
    return [self fetchAllObjectsForEntityName:entityName
                              sortDescriptors:(sortDescriptor) ? @[sortDescriptor] : nil
                                        error:(NSError **)error];
}

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName
                          sortDescriptors:(NSArray *)sortDescriptors
                                    error:(NSError **)error
{
    return [self fetchAllObjectsForEntityName:entityName
                                withPredicate:nil
                              sortDescriptors:sortDescriptors
                                        error:error];
}

- (id)fetchObjectForEntityName:(NSString *)entityName
                  withUniqueId:(id)uniqueId
                         error:(NSError **)error
{
    // find the index name
    NSString *indexName = [[self indexedAttributeForEntityName:entityName] name];
    
    // build the predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", indexName, uniqueId];
    NSArray *results = [self fetchAllObjectsForEntityName:entityName
                                            withPredicate:predicate
                                          sortDescriptors:nil
                                                    error:error];
    if (results.count == 1) {
        return [results lastObject];
    }
    return nil;
}


#pragma mark - Helper

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName
                            withPredicate:(NSPredicate *)predicate
                          sortDescriptors:(NSArray *)sortDescriptors
                                    error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return [self executeFetchRequest:fetchRequest error:error];
}

@end
