//
//  ACEAppDelegate.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/9/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
