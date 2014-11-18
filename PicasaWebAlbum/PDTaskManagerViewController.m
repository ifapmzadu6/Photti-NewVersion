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
@property (strong, nonatomic) UIImageView *noTaskImageView;
@property (strong, nonatomic) UILabel *noTaskLabel;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PDTaskManagerViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", nil);
        
        NSManagedObjectContext *plcontext = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeContext:) name:NSManagedObjectContextDidSaveNotification object:plcontext];
        NSManagedObjectContext *pwcontext = [PWCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeContext:) name:NSManagedObjectContextDidSaveNotification object:pwcontext];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction:)];
    settingsBarButtonItem.landscapeImagePhone = [PAIcons imageWithImage:[UIImage imageNamed:@"Settings"] insets:UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f)];
    self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
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
    
    _noTaskImageView = [UIImageView new];
    _noTaskImageView.image = [UIImage imageNamed:@"icon_240"];
    _noTaskImageView.frame = CGRectMake(0.0f, 0.0f, 240.0f, 240.0f);
    [self.view addSubview:_noTaskImageView];
    
    _noTaskLabel = [UILabel new];
    _noTaskLabel.text = NSLocalizedString(@"No Tasks", nil);
    _noTaskLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
    _noTaskLabel.textAlignment = NSTextAlignmentCenter;
    _noTaskLabel.font = [UIFont systemFontOfSize:15.0f];
    [_noTaskLabel sizeToFit];
    [self.view addSubview:_noTaskLabel];
    
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
    CGPoint center = self.view.center;
    
    _tableView.frame = rect;
    
    _noTaskImageView.center = CGPointMake(center.x, center.y - 20.0f);
    
    _noTaskLabel.center = CGPointMake(center.x, center.y + 100.0f);
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
- (void)doneBarButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)settingsBarButtonAction:(id)sender {
    PXSettingsViewController *viewController = [[PXSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.navigationController presentViewController:viewController animated:YES completion:nil];
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
        BOOL hasTasks = (_fetchedResultsController.fetchedObjects.count > 0) ? YES : NO;
        _tableView.hidden = !hasTasks;
        _noTaskImageView.hidden = hasTasks;
        _noTaskLabel.hidden = hasTasks;
        if (_tableView.indexPathsForVisibleRows.count == 0) {
            [_tableView reloadData];
        }
    });
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL hasTasks = (controller.fetchedObjects.count > 0) ? YES : NO;
        _tableView.hidden = !hasTasks;
        [_tableView reloadData];
        _noTaskImageView.hidden = hasTasks;
        _noTaskLabel.hidden = hasTasks;
    });
}

#pragma mark CoreData
- (void)didChangeContext:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}

@end
