//
//  ACECoreDataManager+Sync.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/10/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataManager.h"

@interface ACECoreDataManager (Sync)

- (void)insertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName;
- (void)upsertArrayOfDictionary:(NSArray *)dataArray inEntityName:(NSString *)entityName;

@end
