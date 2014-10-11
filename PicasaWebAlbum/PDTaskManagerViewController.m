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
#import "PATabBarController.h"
#import "PDTaskViewController.h"
#import "PXSettingsViewController.h"

@interface PDTaskManagerViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PDTaskManagerViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", nil);
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        NSManagedObjectContext *plcontext = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:plcontext];
        NSManagedObjectContext *pwcontext = [PWCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:pwcontext];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarButtonAction)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[PDTaskTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [_tableView registerClass:[PDTaskManagerViewControllerHeaderView class] forHeaderFooterViewReuseIdentifier:@"Header"];
    _tableView.rowHeight = 60.0f;
    _tableView.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    PATabBarController *tabBarViewController = (PATabBarController *)self.tabBarController;
    UIEdgeInsets viewInsets = [tabBarViewController viewInsets];
    _tableView.contentInset = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom + 50.0f, 0.0f);
    _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(viewInsets.top, 0.0f, viewInsets.bottom, 0.0f);
    _tableView.frame = rect;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    
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
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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

- (void)settingsBarButtonAction {
    PXSettingsViewController *viewController = [[PXSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeTaskManager];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
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
    PDTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
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
    PDTaskManagerViewControllerHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header"];
    
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
    view.textLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0f;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark NSFetchedResultsController
- (void)loadData {
    __weak typeof(self) wself = self;
    [PDCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:NSStringFromClass([PDTaskObject class]) inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sort_index" ascending:YES]];
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        sself.fetchedResultsController.delegate = sself;
        
        NSError *error = nil;
        if (![sself.fetchedResultsController performFetch:&error]) {
            abort();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sself.tableView.indexPathsForVisibleRows.count == 0) {
                [sself.tableView reloadData];
            }
        });
    }];
}

#pragma NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}

@end
