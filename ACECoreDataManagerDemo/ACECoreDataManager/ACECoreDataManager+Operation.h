//
//  ACECoreDataManager+Operation.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataManager.h"

@interface ACECoreDataManager (Operation)

- (void)removeAllFromEntityName:(NSString *)entityName error:(NSError **)error;

@end
