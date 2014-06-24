//
//  PWGoogleLoginViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWGoogleLoginViewController.h"

#import "PWColors.h"
#import "PWIcons.h"

@interface PWGoogleLoginViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *loginButton;

@end

@implementation PWGoogleLoginViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PicasaLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintWebColor] colorWithAlphaComponent:0.3f];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = NSLocalizedString(@"Google+ Photo", nil);
    _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    _loginButton = [UIButton new];
    [_loginButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _loginButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [_loginButton setTitleColor:[PWColors getColor:PWColorsTypeTintWebColor] forState:UIControlStateNormal];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_loginButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintWebColor]] forState:UIControlStateHighlighted];
    _loginButton.clipsToBounds = YES;
    _loginButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintWebColor].CGColor;
    _loginButton.layer.borderWidth = 1.0f;
    _loginButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:_loginButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _iconImageView.frame = CGRectMake(70.0f, 100.0f, 180.0f, 180.0f);
    
    _titleLabel.frame = CGRectMake(0.0f, 310.0f, CGRectGetWidth(rect), 20.0f);
    
    _loginButton.frame = CGRectMake(100.0f, 450.0f, 120.0f, 30.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIButton
- (void)loginButtonAction {
    
}

@end
