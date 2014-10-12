//
//  PAMigrationViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAMigrationViewController.h"

#import "PAColors.h"
#import "PATabBarController.h"
#import "PAActivityIndicatorView.h"

@interface PAMigrationViewController ()

@property (strong, nonatomic) PAActivityIndicatorView *indicatorView;
@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UILabel *detailTextLabel;

@end

@implementation PAMigrationViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Photti", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    
    _indicatorView = [PAActivityIndicatorView new];
    [self.view addSubview:_indicatorView];
    [_indicatorView startAnimating];
    
    _textLabel = [UILabel new];
    if (self.isPhone) {
        _textLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _textLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _textLabel.textColor = [PAColors getColor:PAColorsTypeTextDarkColor];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.numberOfLines = 0;
    [self.view addSubview:_textLabel];
    _textLabel.text = NSLocalizedString(@"Updating data...", nil);
    
    _detailTextLabel = [UILabel new];
    if (self.isPhone) {
        _detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _detailTextLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _detailTextLabel.textColor = [PAColors getColor:PAColorsTypeTextDarkColor];
    _detailTextLabel.textAlignment = NSTextAlignmentCenter;
    _detailTextLabel.numberOfLines = 0;
    [self.view addSubview:_detailTextLabel];
    _detailTextLabel.text = NSLocalizedString(@"Please wait for a minute.", nil);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGPoint center = self.view.center;
    CGRect rect = self.view.bounds;
    
    _indicatorView.center = center;
    
    _textLabel.frame = CGRectMake(0.0f, 0.0f, rect.size.width, 30.0f);
    _textLabel.center = CGPointMake(center.x, center.y - 50.0f);
    
    _detailTextLabel.frame = CGRectMake(0.0f, 0.0f, rect.size.width, 30.0f);
    _detailTextLabel.center = CGPointMake(center.x, center.y + 50.0f);
}

@end
