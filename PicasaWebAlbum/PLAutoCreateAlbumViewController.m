//
//  PLAutoCreateAlbumViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAutoCreateAlbumViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"

#import "PWSettingsViewController.h"
#import "PWShareAction.h"

@interface PLAutoCreateAlbumViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *enableButton;
@property (strong, nonatomic) UIButton *disableButton;

@end

@implementation PLAutoCreateAlbumViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Camera Roll", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareBarButtonAction)];
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PictureLargeDay"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.3f];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = @"Auto-Create Album";
    _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    _descriptionLabel = [UILabel new];
    //    _descriptionLabel.text = NSLocalizedString(@"Go to Settings > Privacy > Photos and switch Photti 2 to ON to access Photo Library.", nil);
    _descriptionLabel.text = NSLocalizedString(@"Photti 2 automatically create albums each day. When that is created, you are pushed a notification.", nil);
    _descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    _descriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.numberOfLines = 0;
    [self.view addSubview:_descriptionLabel];
    
    _enableButton = [UIButton new];
    [_enableButton addTarget:self action:@selector(enableButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _enableButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_enableButton setTitle:NSLocalizedString(@"Enable", nil) forState:UIControlStateNormal];
    [_enableButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_enableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_enableButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateHighlighted];
    _enableButton.clipsToBounds = YES;
    _enableButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintLocalColor].CGColor;
    _enableButton.layer.borderWidth = 1.0f;
    _enableButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:_enableButton];
    
    _disableButton = [UIButton new];
    [_disableButton addTarget:self action:@selector(disableButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _disableButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [_disableButton setTitle:NSLocalizedString(@"Disable", nil) forState:UIControlStateNormal];
    [_disableButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_disableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_disableButton setBackgroundImage:[PWIcons imageWithColor:[[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.5f]] forState:UIControlStateHighlighted];
    _disableButton.clipsToBounds = YES;
//    _disableButton.layer.borderColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.3f].CGColor;
//    _disableButton.layer.borderWidth = 1.0f;
    _disableButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:_disableButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _iconImageView.frame = CGRectMake(70.0f, 60.0f, 190.0f, 190.0f);
        _titleLabel.frame = CGRectMake(250.0f + 0.0f, 280.0f - 212.0f, CGRectGetHeight(rect), 36.0f);
        _descriptionLabel.frame = CGRectMake(250.0f + 40.0f, 320.0f - 212.0f, 240.0f, 100.0f);
        _enableButton.frame = CGRectMake(250.0f + 50.0f, 444.0f - 212.0f, 100.0f, 30.0f);
        _disableButton.frame = CGRectMake(250.0f + 170.0f, 444.0f - 212.0f, 100.0f, 30.0f);
    }
    else {
        _iconImageView.frame = CGRectMake(70.0f, 80.0f, 190.0f, 190.0f);
        _titleLabel.frame = CGRectMake(0.0f, 280.0f, CGRectGetWidth(rect), 36.0f);
        _descriptionLabel.frame = CGRectMake(40.0f, 320.0f, 240.0f, 100.0f);
        _enableButton.frame = CGRectMake(50.0f, 444.0f, 100.0f, 30.0f);
        _disableButton.frame = CGRectMake(170.0f, 444.0f, 100.0f, 30.0f);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] init];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)shareBarButtonAction {
    [PWShareAction showFromViewController:self.tabBarController];
}

#pragma mark UIButtonAction
- (void)enableButtonAction {
    [PLAssetsManager sharedManager].autoCreateAlbumType = PLAssetsManagerAutoCreateAlbumTypeEnable;
    
    if (_completion) {
        _completion();
    }
}

- (void)disableButtonAction {
    [PLAssetsManager sharedManager].autoCreateAlbumType = PLAssetsManagerAutoCreateAlbumTypeDisable;
    
    if (_completion) {
        _completion();
    }
}

@end
