//
//  ACECoreDataManager.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/9/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACECoreDataManager;

@protocol ACECoreDataDelegate <NSObject>

@required
- (NSURL *)modelURLForManager:(ACECoreDataManager *)manager;
- (NSURL *)storeURLForManager:(ACECoreDataManager *)manager;

@end

#pragma mark -

@interface ACECoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) id<ACECoreDataDelegate> delegate;

// save
- (void)saveContext:(void (^)(NSError *error))errorBlock;
- (void)saveContext;

// delete
- (void)deleteContext:(void (^)(NSError *error))errorBlock;
- (void)deleteContext;

// singleton
+ (instancetype)sharedManager;

@end
