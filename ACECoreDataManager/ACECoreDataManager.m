// ACECoreDataManager.m
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

#define kSaveContextAfterInterval   1.0

@interface ACECoreDataManager ()
@property (strong, nonatomic) NSManagedObjectContext *privateWriterContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (assign, nonatomic) BOOL autoSave; // save the context when something change
@end

@implementation ACECoreDataManager

@synthesize managedObjectContext    = _managedObjectContext;
@synthesize useBackgroundWriter     = _useBackgroundWriter;

+ (instancetype)sharedManager
{
    static ACECoreDataManager *_instance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.autoSave = YES;
        self.useBackgroundWriter = YES;
        
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveContext)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveContext)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
#else
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveContext)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveContext)
                                                     name:NSApplicationWillResignActiveNotification
                                                   object:nil];
#endif
        
    }
    return self;
}

- (void)handleError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(coreDataManager:didFailOperationWithError:)]) {
        [self.delegate coreDataManager:self didFailOperationWithError:error];
        
    } else {
        NSLog(@"Core Manager Error [%ld]: %@", (long)error.code, error.localizedDescription);
    }
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(saveContext)
                                               object:nil];
    
#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
#else
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationWillTerminateNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationWillResignActiveNotification
                                                  object:nil];
#endif
}


#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            
            // create the main context on the main thread
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _managedObjectContext.name = @"Main";
            
            // add the observer for auto save
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(contextObjectsDidChange:)
                                                         name:NSManagedObjectContextObjectsDidChangeNotification
                                                       object:_managedObjectContext];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(contextDidSave:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:nil];
            
            if (self.useBackgroundWriter) {
                // http://www.cocoanetics.com/2012/07/multi-context-coredata/
                _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                _privateWriterContext.persistentStoreCoordinator = coordinator;
                _privateWriterContext.name = @"Writer";
                
                // set the writer as a worker thread
                _managedObjectContext.parentContext = self.privateWriterContext;
                
            } else {
                // use just the main thread on iOS 5
                _managedObjectContext.persistentStoreCoordinator = coordinator;
            }
        }
    }
    return _managedObjectContext;
}

- (BOOL)useBackgroundWriter
{
#if TARGET_OS_IOS
    return _useBackgroundWriter && [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0f;
#else
    return _useBackgroundWriter;
#endif
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        NSURL *modelURL = [self.delegate modelURLForManager:self];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES
                                  };
        
        
        NSError *error = nil;
        NSURL *storeURL = [self.delegate storeURLForManager:self];
        
        self.persistentStore =
        [_persistentStoreCoordinator addPersistentStoreWithType:(storeURL != nil) ? NSSQLiteStoreType : NSInMemoryStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:options
                                                          error:&error];
        if (self.persistentStore == nil) {
            NSLog(@"Error adding the persistent store: %@. DB removed", error.localizedDescription);
            [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
            
            self.persistentStore =
            [_persistentStoreCoordinator addPersistentStoreWithType:(storeURL != nil) ? NSSQLiteStoreType : NSInMemoryStoreType
                                                      configuration:nil
                                                                URL:storeURL
                                                            options:options
                                                              error:&error];
        }
    }
    return _persistentStoreCoordinator;
}


#pragma mark - Notifications

- (void)contextObjectsDidChange:(NSNotification *)notification
{
    if (notification.object == self.managedObjectContext && self.autoSave) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveContext) object:nil];
        [self performSelector:@selector(saveContext) withObject:nil afterDelay:kSaveContextAfterInterval];
    }
}

- (void)contextDidSave:(NSNotification *)notification
{
    // propagate the changes to the parent context
    NSManagedObjectContext *notificationContext = notification.object;
    NSManagedObjectContext *parentContext = notificationContext.parentContext;
    
    [parentContext performBlockAndWait:^{
        [parentContext mergeChangesFromContextDidSaveNotification:notification];
        
        NSError *error;
        if (![parentContext save:&error]) {
            // make sure the handle error is executed on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleError:error];
            });
        }
    }];
}


#pragma mark - Context

- (void)setUseBackgroundWriter:(BOOL)useBackgroundWriter
{
    if (_managedObjectContext == nil) {
        _useBackgroundWriter = useBackgroundWriter;
        
    } else {
        @throw [NSException exceptionWithName:@"Internal exception" reason:@"Context already created" userInfo:nil];
    }
}

- (void)performOperation:(void (^)(NSManagedObjectContext *temporaryContext))actionBlock completeBlock:(dispatch_block_t)completeBlock
{
    if (actionBlock != nil) {
        NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        temporaryContext.name = @"Temp";
        temporaryContext.parentContext = self.managedObjectContext;
        
        [temporaryContext performBlockAndWait:^{
            actionBlock(temporaryContext);
            
            // save the temporary context
            NSError *error;
            if ([temporaryContext hasChanges]) {
                
                if (![temporaryContext save:&error]) {
                    // make sure the handle error is executed on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self handleError:error];
                    });
                    
                } else if (completeBlock != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completeBlock();
                    });
                }
                
            } else if (completeBlock != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock();
                });
            }
        }];
    }
}

- (void)saveContext
{
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext performBlock:^{
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                [self handleError:error];
            }
        }];
    }
}

- (void)deleteContext
{
    // delete all the caches
    [NSFetchedResultsController deleteCacheWithName:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(saveContext)
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:self.managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
    
    NSError *error;
    if (![self.persistentStoreCoordinator removePersistentStore:self.persistentStore error:&error]) {
        [self handleError:error];
    }
    
    if (![self.persistentStore.type isEqualToString:NSInMemoryStoreType]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:self.persistentStore.URL.path error:&error]) {
            [self handleError:error];
        }
    }
    
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
}


#pragma mark - Atomic Updates

- (void)beginUpdates
{
    self.autoSave = NO;
}

- (void)endUpdates
{
    [self saveContext];
    self.autoSave = YES;
}

@end
