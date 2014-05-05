//
//  ACECoreDataNetworkTableViewController.m
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 5/5/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import "ACECoreDataNetworkTableViewController.h"

#import "SVPullToRefresh.h"

@interface ACECoreDataNetworkTableViewController ()

@end

@implementation ACECoreDataNetworkTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    double delayInSeconds = 0.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        
        __weak __typeof(self)weakSelf = self;
        
        [self.tableView addPullToRefreshWithActionHandler:^{
            [weakSelf reloadDataFromNetwork];
        }];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView triggerPullToRefresh];
}



#pragma mark - Reload

- (void)reloadDataFromNetwork
{
    [self.tableView.pullToRefreshView stopAnimating];
}

@end
