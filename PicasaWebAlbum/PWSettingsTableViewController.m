//
//  PWSettingsTableViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSettingsTableViewController.h"

#import "PWColors.h"
#import "KKStaticTableView.h"

@interface PWSettingsTableViewController ()

@property (strong, nonatomic) KKStaticTableView *tableView;

@end

@implementation PWSettingsTableViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Settings", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    _tableView = [[KKStaticTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.cellTextFont = [UIFont systemFontOfSize:17.0f];
    _tableView.cellDetailTextFontTypeValue1 = [UIFont systemFontOfSize:15.0f];
    _tableView.cellDetailTextFontTypeSubTitle = [UIFont systemFontOfSize:13.0f];
    _tableView.cellDetailTextColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
    [self.view addSubview:_tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
