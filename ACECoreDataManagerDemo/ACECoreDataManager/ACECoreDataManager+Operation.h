//
//  ACECoreDataManager+Operation.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataManager.h"

typedef id (^DataBlock)(NSString *key, NSAttributeType attributeType);

@interface ACECoreDataManager (Operation)

- (NSManagedObject *)insertObjectInEntity:(NSString *)entityName withDataBlock:(DataBlock)block;
- (NSManagedObject *)insertDictionary:(NSDictionary *)dictionary inEntityName:(NSString *)entityName;
- (void)insertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName;

- (void)removeAllFromEntityName:(NSString *)entityName error:(NSError **)error;

@end
