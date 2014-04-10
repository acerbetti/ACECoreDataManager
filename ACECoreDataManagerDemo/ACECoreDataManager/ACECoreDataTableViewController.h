//
//  ACECoreDataTableViewController.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/9/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACECoreDataTableViewController;

@protocol ACECoreDataTableViewDataSource <UITableViewDataSource>

- (NSString *)fetchCacheNameFor:(ACECoreDataTableViewController *)controller;
- (NSFetchRequest *)fetchRequestFor:(ACECoreDataTableViewController *)controller;

// helper for creating the cells
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object;

@end

#pragma mark -

@interface ACECoreDataTableViewController : UIViewController<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *emptyView;

// views
- (BOOL)shouldShowEmptyView;

@end
