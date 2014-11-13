//
//  PWTaskViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskManagerViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PDModelObject.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PWCoreDataAPI.h"
#import "PLCoreDataAPI.h"

#import "PDTaskTableViewCell.h"
#import "PDTaskManagerViewControllerHeaderView.h"
#import "PXSettingsViewController.h"
#import "PAActivityIndicatorView.h"

@interface PDTaskManagerViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PDTaskManagerViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", nil);
        
        NSManagedObjectContext *plcontext = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:plcontext];
        NSManagedObjectContext *pwcontext = [PWCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:pwcontext];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarButtonAction)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction:)];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[PDTaskTableViewCell class] forCellReuseIdentifier:NSStringFromClass([PDTaskTableViewCell class])];
    [_tableView registerClass:[PDTaskManagerViewControllerHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([PDTaskManagerViewControllerHeaderView class])];
    _tableView.rowHeight = 60.0f;
    _tableView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    _tableView.exclusiveTouch = YES;
    [self.view addSubview:_tableView];
    
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSIndexPath *indexPath in _tableView.indexPathsForSelectedRows) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)dealloc {
    NSManagedObjectContext *plcontext = [PLCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:plcontext];
    NSManagedObjectContext *pwcontext = [PWCoreDataAPI readContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:pwcontext];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [_tableView setEditing:editing animated:animated];
}

#pragma mark UIBarButtonAction
- (void)refreshBarButtonAction {
    PAActivityIndicatorView *indicatorView = [PAActivityIndicatorView new];
    UIBarButtonItem *indicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    [indicatorView startAnimating];
    [self.navigationItem setRightBarButtonItem:indicatorBarButtonItem animated:YES];
    
    [[PDTaskManager sharedManager] cancel];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[PDTaskManager sharedManager] start];
        
        UIBarButtonItem *refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarButtonAction)];
        [self.navigationItem setRightBarButtonItem:refreshBarButtonItem animated:YES];
    });
}

- (void)doneBarButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_fetchedResultsController.fetchedObjects.count >= 2) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return (_fetchedResultsController.fetchedObjects.count > 0);
    }
    return _fetchedResultsController.fetchedObjects.count - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PDTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PDTaskTableViewCell class]) forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        cell.taskObject = _fetchedResultsController.fetchedObjects.firstObject;
    }
    else {
        cell.taskObject = _fetchedResultsController.fetchedObjects[indexPath.row+1];
    }
    cell.isNowLoading = (indexPath.section == 0);
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    PDTaskManagerViewControllerHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([PDTaskManagerViewControllerHeaderView class])];
    
    if (section == 0) {
        [headerView setText:NSLocalizedString(@"In Process...", nil)];
        [headerView indicatorIsEnable:YES];
    }
    else {
        [headerView setText:NSLocalizedString(@"In Standby", nil)];
        [headerView indicatorIsEnable:NO];
    }
    
    return headerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"Don't remove those items until the task is finished.", nil);
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    view.textLabel.font = [UIFont systemFontOfSize:13.0f];
    view.textLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0f;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%ld Tasks", nil), 1];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Remove", nil) otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark NSFetchedResultsController
- (void)loadData {
    NSManagedObjectContext *context = [PDCoreDataAPI readContext];
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:kPDTaskObjectName inManagedObjectContext:context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sort_index" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        abort();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_tableView.indexPathsForVisibleRows.count == 0) {
            [_tableView reloadData];
        }
    });
}

#pragma NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}

@end
