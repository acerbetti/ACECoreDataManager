//
//  ACECoreDataManager+Operation.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/11/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataManager+Operation.h"

@implementation ACECoreDataManager (Operation)

- (void)removeAllFromEntityName:(NSString *)entityName error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[self entityWithName:entityName]];
    [fetchRequest setIncludesPropertyValues:NO];
    
    // I want to delete all the objects together, disabling auto save
    BOOL oldAutoSave = self.autoSave;
    self.autoSave = NO;
    
    NSManagedObjectContext *context = self.managedObjectContext;
    NSArray *objects = [context executeFetchRequest:fetchRequest error:error];
    for (NSManagedObject *object in objects) {
        [context deleteObject:object];
    }
    
    // restore the previous mode and force a save
    self.autoSave = oldAutoSave;
    [self saveContext];
}

@end
