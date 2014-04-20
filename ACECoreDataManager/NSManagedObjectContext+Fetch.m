// NSManagedObjectContext+Fetch.m
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

#import "NSManagedObjectContext+Fetch.h"

@implementation NSManagedObjectContext (Fetch)

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)sortDescriptor
{
    return [self fetchAllObjectsForEntityName:entityName sortDescriptors:(sortDescriptor) ? @[sortDescriptor] : nil];
}

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors
{
    return [self fetchAllObjectsForEntityName:entityName withPredicate:nil sortDescriptors:sortDescriptors];
}

- (NSManagedObject *)fetchObjectForEntityName:(NSString *)entityName withUniqueId:(id)uniqueId
{
    // find the index name
    NSString *indexName = [[self indexedAttributeForEntityName:entityName] name];
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", indexName];
    
    // build the predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, uniqueId];
    NSArray *results = [self fetchAllObjectsForEntityName:entityName withPredicate:predicate sortDescriptors:nil];
    if (results.count == 1) {
        return [results lastObject];
    }
    return nil;
}


#pragma mark - Helper

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return [self executeFetchRequest:fetchRequest error:nil];
}

@end
