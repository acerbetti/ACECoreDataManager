// NSManagedObjectContext+Array.h
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

@protocol ACECoreDataJSONFormatter <NSObject>

- (id)valueForObject:(id)object withType:(NSAttributeType)attributeType;

@end

#pragma mark -

@interface NSManagedObjectContext (JSON)

// single object
- (NSManagedObject *)insertDictionary:(NSDictionary *)dictionary
                         inEntityName:(NSString *)entityName
                            formatter:(id<ACECoreDataJSONFormatter>)formatter;

- (NSManagedObject *)updateObject:(NSManagedObject *)managedObject
                   withDictionary:(NSDictionary *)dictionary
                        formatter:(id<ACECoreDataJSONFormatter>)formatter;

- (NSManagedObject *)upsertEntityName:(NSString *)entityName
                       withDictionary:(NSDictionary *)dictionary
                            formatter:(id<ACECoreDataJSONFormatter>)formatter;



// array of objects
- (NSSet *)insertArrayOfDictionary:(NSArray *)dataArray
                      inEntityName:(NSString *)entityName
                         formatter:(id<ACECoreDataJSONFormatter>)formatter;

- (NSSet *)upsertArrayOfDictionary:(NSArray *)dataArray
                      inEntityName:(NSString *)entityName
                         formatter:(id<ACECoreDataJSONFormatter>)formatter;

- (NSSet *)compareArrayOfDictionary:(NSArray *)dataArray
                        withObjects:(id<NSFastEnumeration>)objects
                       inEntityName:(NSString *)entityName
                          formatter:(id<ACECoreDataJSONFormatter>)formatter;

@end
