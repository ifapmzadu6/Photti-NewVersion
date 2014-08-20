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
#import "PWTabBarController.h"

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
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PictureLargeDay"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.667f];
    }
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = NSLocalizedString(@"Auto-Create Album", nil);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    _descriptionLabel = [UILabel new];
    _descriptionLabel.text = NSLocalizedString(@"Photti automatically create albums each day. When that is created, you are pushed a notification.", nil);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _descriptionLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _descriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.numberOfLines = 0;
    [self.view addSubview:_descriptionLabel];
    
    _enableButton = [UIButton new];
    [_enableButton addTarget:self action:@selector(enableButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _enableButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _enableButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_enableButton setTitle:NSLocalizedString(@"Enable", nil) forState:UIControlStateNormal];
    [_enableButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateHighlighted];
    [_enableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_enableButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_enableButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _enableButton.clipsToBounds = YES;
    _enableButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintLocalColor].CGColor;
    _enableButton.layer.borderWidth = 1.0f;
    _enableButton.layer.cornerRadius = 5.0f;
    _enableButton.exclusiveTouch = YES;
    [self.view addSubview:_enableButton];
    
    _disableButton = [UIButton new];
    [_disableButton addTarget:self action:@selector(disableButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _disableButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _disableButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_disableButton setTitle:NSLocalizedString(@"Disable", nil) forState:UIControlStateNormal];
    [_disableButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_disableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_disableButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateHighlighted];
    _disableButton.clipsToBounds = YES;
    _disableButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintLocalColor].CGColor;
    _disableButton.layer.borderWidth = 1.0f;
    _disableButton.layer.cornerRadius = 5.0f;
    _disableButton.exclusiveTouch = YES;
    [self.view addSubview:_disableButton];
}

- (void)viewWillAppear:(BOOL)animated {
    PWTabBarController *tabBarController = (PWTabBarController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)[[UIScreen mainScreen] bounds].size.height > 480) {
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
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 54.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 85.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(120.0f, 120.0f, 240.0f, 100.0f);
                _enableButton.frame = CGRectMake(130.0f, 444.0f - 220.0f, 100.0f, 30.0f);
                _disableButton.frame = CGRectMake(250.0f, 444.0f - 220.0f, 100.0f, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 110.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 150.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 210.0f, 240.0f, 100.0f);
                _enableButton.frame = CGRectMake(50.0f, 360.0f, 100.0f, 30.0f);
                _disableButton.frame = CGRectMake(170.0f, 360.0f, 100.0f, 30.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 100.0f, 300.0f, 300.0f);
            _titleLabel.frame = CGRectMake(412.0f, 410.0f, 200.0f, 36.0f);
            _descriptionLabel.frame = CGRectMake(272.0f, 460.0f, 480.0f, 100.0f);
            _enableButton.frame = CGRectMake(282.0f, 576.0f, 160.0f, 50.0f);
            _disableButton.frame = CGRectMake(582.0f, 576.0f, 160.0f, 50.0f);
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 150.0f, 400.0f, 400.0f);
            _titleLabel.frame = CGRectMake(284.0f, 580.0f, 200.0f, 36.0f);
            _descriptionLabel.frame = CGRectMake(144.0f, 640.0f, 480.0f, 100.0f);
            _enableButton.frame = CGRectMake(154.0f, 800.0f, 160.0f, 50.0f);
            _disableButton.frame = CGRectMake(454.0f, 800.0f, 160.0f, 50.0f);
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
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
