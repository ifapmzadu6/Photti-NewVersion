//
//  PXEditItemsViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PXEditItemsViewController.h"

typedef NS_ENUM(NSUInteger, kPXEditItemsViewControllerSection) {
    kPXEditItemsViewControllerSection_EnableItems,
    kPXEditItemsViewControllerSection_DisableItems
};

@interface PXEditItemsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *enabledItems;
@property (strong, nonatomic) NSMutableArray *disabledItems;

@end

@implementation PXEditItemsViewController

- (instancetype)initWithEnabledItems:(NSArray *)enabledItems disabledItems:(NSArray *)disabledItems {
    self = [super init];
    if (self) {
        _enabledItems = enabledItems.mutableCopy;
        _disabledItems = disabledItems.mutableCopy;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_completionBlock) {
        _completionBlock(_enabledItems.copy, _disabledItems.copy);
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [_tableView setEditing:editing animated:animated];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kPXEditItemsViewControllerSection_EnableItems) {
        return _enabledItems.count;
    }
    else if (section == kPXEditItemsViewControllerSection_DisableItems) {
        return _disabledItems.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.showsReorderControl = YES;
        cell.shouldIndentWhileEditing = NO;
        cell.indentationWidth = 0.0f;
    }
    
    UISwitch *accessorySwitch = [UISwitch new];
    if (indexPath.section == kPXEditItemsViewControllerSection_EnableItems) {
        cell.textLabel.text = _enabledItems[indexPath.row];
        accessorySwitch.on = YES;
        [accessorySwitch addTarget:self action:@selector(enabledAccessorySwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    else if (indexPath.section == kPXEditItemsViewControllerSection_DisableItems) {
        cell.textLabel.text = _disabledItems[indexPath.row];
        accessorySwitch.on = NO;
        [accessorySwitch addTarget:self action:@selector(disabledAccessorySwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    accessorySwitch.tag = indexPath.row;
    cell.accessoryView = accessorySwitch;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kPXEditItemsViewControllerSection_EnableItems) {
        return _enabledItemsTitle;
    }
    else if (section == kPXEditItemsViewControllerSection_DisableItems) {
        return _disabledItemsTitle;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kPXEditItemsViewControllerSection_EnableItems) {
        return YES;
    }
    else if (indexPath.section == kPXEditItemsViewControllerSection_DisableItems) {
        return NO;
    }
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kPXEditItemsViewControllerSection_EnableItems) {
        return YES;
    }
    else if (indexPath.section == kPXEditItemsViewControllerSection_DisableItems) {
        return NO;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSString *item = _enabledItems[sourceIndexPath.row];
    [_enabledItems removeObject:item];
    [_enabledItems insertObject:item atIndex:destinationIndexPath.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

#pragma mark Switch
- (void)enabledAccessorySwitchValueChanged:(id)sender {
    UISwitch *accessorySwitch = (UISwitch *)sender;
    UITableViewCell *cell = (UITableViewCell *)accessorySwitch.superview;
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    NSString *item = _enabledItems[indexPath.row];
    
    [_enabledItems removeObject:item];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:kPXEditItemsViewControllerSection_EnableItems];
    [_tableView deleteRowsAtIndexPaths:@[deleteIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [_disabledItems addObject:item];
    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:(_disabledItems.count-1) inSection:kPXEditItemsViewControllerSection_DisableItems];
    [_tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)disabledAccessorySwitchValueChanged:(id)sender {
    UISwitch *accessorySwitch = (UISwitch *)sender;
    UITableViewCell *cell = (UITableViewCell *)accessorySwitch.superview;
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    NSString *item = _disabledItems[indexPath.row];
    
    [_disabledItems removeObject:item];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:kPXEditItemsViewControllerSection_DisableItems];
    [_tableView deleteRowsAtIndexPaths:@[deleteIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [_enabledItems addObject:item];
    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:(_enabledItems.count-1) inSection:kPXEditItemsViewControllerSection_EnableItems];
    [_tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
