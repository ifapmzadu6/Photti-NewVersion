//
//  PWSelectItemFromArrayViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSelectItemFromArrayViewController.h"

#import "PWColors.h"

@interface PWSelectItemFromArrayViewController ()

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSArray *items;
@property (nonatomic) NSUInteger selectedIndex;

@end

@implementation PWSelectItemFromArrayViewController

- (id)initWithItems:(NSArray *)items defaultIndex:(NSUInteger)defaultIndex {
    self = [super init];
    if (self) {
        _items = items;
        _selectedIndex = defaultIndex;
        _disableIndex = NSUIntegerMax;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_doneBlock) {
        _doneBlock(_items[_selectedIndex]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    
    cell.textLabel.text = _items[indexPath.row];
    if (indexPath.row == _selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (indexPath.row == _disableIndex) {
        cell.textLabel.textColor = [UIColor colorWithWhite:0.7f alpha:1.0f];
    }
    else {
        cell.textLabel.textColor = [PWColors getColor:PWColorsTypeTextColor];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _disableIndex) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedIndex = indexPath.row;
    
    if (_changeValueBlock) {
        _changeValueBlock(_items[_selectedIndex]);
    }
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic
     ];
}

@end
