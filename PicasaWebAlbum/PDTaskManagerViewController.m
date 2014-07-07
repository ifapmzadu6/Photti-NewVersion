//
//  PWTaskViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDTaskManagerViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PDModelObject.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"

#import "PWCoreDataAPI.h"
#import "PLCoreDataAPI.h"

#import "PDTaskTableViewCell.h"
#import "PDTaskViewController.h"
#import "PWSettingsViewController.h"

@interface PDTaskManagerViewController ()

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isChangingContext;
@property (nonatomic) BOOL isEnabledPLCoreDataNotification;
@property (nonatomic) BOOL isEnabledPWCoreDataNotification;

@end

@implementation PDTaskManagerViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Task Manager", nil);
        
        __weak typeof(self) wself = self;
        NSManagedObjectContext *plContext = [PLCoreDataAPI readContext];
        [plContext performBlockAndWait:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isEnabledPLCoreDataNotification = YES;
            [[NSNotificationCenter defaultCenter] addObserver:sself selector:@selector(controllerWillChangeContent:) name:NSManagedObjectContextWillSaveNotification object:plContext];
            [[NSNotificationCenter defaultCenter] addObserver:sself selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:plContext];
        }];
        [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
            typeof(wself) sself = wself;
            if (!sself) return;
            sself.isEnabledPWCoreDataNotification = YES;
            [[NSNotificationCenter defaultCenter] addObserver:sself selector:@selector(controllerWillChangeContent:) name:NSManagedObjectContextWillSaveNotification object:context];
            [[NSNotificationCenter defaultCenter] addObserver:sself selector:@selector(controllerDidChangeContent:) name:NSManagedObjectContextDidSaveNotification object:context];
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[PDTaskTableViewCell class] forCellReuseIdentifier:@"Cell"];
    _tableView.rowHeight = 56.0f;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
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
    
    _tableView.frame = rect;
}

- (void)dealloc {
    __weak typeof(self) wself = self;
    NSManagedObjectContext *plContext = [PLCoreDataAPI readContext];
    [plContext performBlockAndWait:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:plContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:plContext];
    }];
    [PWCoreDataAPI readWithBlockAndWait:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        [[NSNotificationCenter defaultCenter] removeObserver:sself name:NSManagedObjectContextWillSaveNotification object:context];
        [[NSNotificationCenter defaultCenter] removeObserver:sself name:NSManagedObjectContextDidSaveNotification object:context];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [_tableView setEditing:editing animated:animated];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeTaskManager];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_isChangingContext) {
        return 0;
    }
    
    return _fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isChangingContext) {
        return 0;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PDTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (_isChangingContext) {
        cell.taskObject = nil;
    }
    else {
        cell.taskObject = [_fetchedResultsController objectAtIndexPath:indexPath];
    }
    cell.isNowLoading = (indexPath.row == 0);
    
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PDTaskViewController *viewController = [[PDTaskViewController alloc] initWithTask:[_fetchedResultsController objectAtIndexPath:indexPath]];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [PDTaskTableViewCell cellHeightForTaskObject:[_fetchedResultsController objectAtIndexPath:indexPath]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
}

#pragma mark NSFetchedResultsController
- (void)loadData {
    __weak typeof(self) wself = self;
    [PDCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPDBaseTaskObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        sself.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        sself.fetchedResultsController.delegate = sself;
        
        NSError *error = nil;
        [sself.fetchedResultsController performFetch:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sself.tableView.indexPathsForVisibleRows.count == 0) {
                [sself.tableView reloadData];
            }
        });
    }];
}

#pragma NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    _isChangingContext = NO;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}

@end
