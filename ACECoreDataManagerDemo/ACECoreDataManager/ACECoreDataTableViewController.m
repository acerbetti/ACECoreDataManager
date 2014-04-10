// ACECoreDataTableViewController.m
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

#import "ACECoreDataTableViewController.h"
#import "ACECoreDataManager.h"

@interface ACECoreDataTableViewController ()<NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation ACECoreDataTableViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshViewMode];
}

#pragma mark - Private

- (BOOL)shouldShowEmptyView
{
    return self.fetchedResultsController.fetchedObjects.count == 0;
}

- (void)refreshViewMode
{
    if ([self shouldShowEmptyView]) {
        self.emptyView.hidden = NO;
        self.tableView.hidden = YES;
        
    } else {
        self.tableView.hidden = NO;
        self.emptyView.hidden = YES;
    }
}


#pragma mark - Properties

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

- (UIView *)emptyView
{
    if (_emptyView == nil) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        [emptyLabel setText:NSLocalizedString(@"Empty table", nil)];
        [emptyLabel sizeToFit];
        [emptyLabel setCenter:self.view.center];
        [self.view addSubview:emptyLabel];
        
        _emptyView = emptyLabel;
    }
    return _emptyView;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController == nil) {
        
        NSManagedObjectContext *context = [[ACECoreDataManager sharedManager] managedObjectContext];
        _fetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest:context]
                                            managedObjectContext:context
                                              sectionNameKeyPath:self.fetchSectionNameKeyPath
                                                       cacheName:self.fetchCacheName];
        
        _fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error]) {
            
        }
    }
    return _fetchedResultsController;
}

- (NSFetchRequest *)fetchRequest:(NSManagedObjectContext *)context;
{
    return nil;
}

- (void)fetchRequestFailedWithError:(NSError *)error
{
    
}

- (NSString *)fetchSectionNameKeyPath
{
    return nil;
}

- (NSString *)fetchCacheName
{
    return nil;
}


#pragma mark - Fetched Results delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationBottom];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationBottom];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationTop];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self refreshViewMode];
    [self.tableView endUpdates];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return [self tableView:tableView cellForRowAtIndexPath:indexPath withObject:object];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.tableView) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
