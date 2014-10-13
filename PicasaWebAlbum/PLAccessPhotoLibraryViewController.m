//
//  PLAccessPhotoLibraryViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAccessPhotoLibraryViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLAssetsManager.h"
#import "PEAssetsManager.h"

#import "PXSettingsViewController.h"
#import "PATabBarAdsController.h"

@interface PLAccessPhotoLibraryViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *accessButton;

@end

@implementation PLAccessPhotoLibraryViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Camera Roll", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PictureLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PAColors getColor:PAColorsTypeTintLocalColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PAColors getColor:PAColorsTypeTintLocalColor] colorWithAlphaComponent:0.667f];
    }
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = @"Camera Roll";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _titleLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    
    _descriptionLabel = [UILabel new];
    [self setDescriptionLabelText];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _descriptionLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _descriptionLabel.textColor = [PAColors getColor:PAColorsTypeTextLightColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.numberOfLines = 0;
    [self.view addSubview:_descriptionLabel];
    
    _accessButton = [UIButton new];
    [_accessButton addTarget:self action:@selector(accessButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _accessButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _accessButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_accessButton setTitle:NSLocalizedString(@"Access", nil) forState:UIControlStateNormal];
    [_accessButton setTitleColor:[PAColors getColor:PAColorsTypeTintLocalColor] forState:UIControlStateHighlighted];
    [_accessButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_accessButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeTintLocalColor]] forState:UIControlStateNormal];
    [_accessButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:PAColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _accessButton.clipsToBounds = YES;
    _accessButton.layer.borderColor = [PAColors getColor:PAColorsTypeTintLocalColor].CGColor;
    _accessButton.layer.borderWidth = 1.0f;
    _accessButton.layer.cornerRadius = 5.0f;
    _accessButton.exclusiveTouch = YES;
    [self.view addSubview:_accessButton];
    
    [self updateAccessButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
    
    [self setDescriptionLabelText];
    [self updateAccessButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds))) > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                CGFloat deltaX = (CGRectGetWidth([UIScreen mainScreen].bounds)-568.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight([UIScreen mainScreen].bounds)-320.0f)/2.0f;
                _iconImageView.frame = CGRectMake(deltaX+70.0f, deltaY+80.0f, 180.0f, 180.0f);
                _titleLabel.frame = CGRectMake(deltaX+250.0f, deltaY+286.0f-192.0f, 320.0f, 36.0f);
                _descriptionLabel.frame = CGRectMake(deltaX+250.0f+40.0f, deltaY+326.0f-212.0f, 240.0f, 100.0f);
                _accessButton.frame = CGRectMake(deltaX+250.0f+110.0f, deltaY+444.0f-227.0f, 100.0f, 30.0f);
            }
            else {
                CGFloat deltaX = (CGRectGetWidth([UIScreen mainScreen].bounds)-320.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight([UIScreen mainScreen].bounds)-568.0f)/2.0f;
                _iconImageView.frame = CGRectMake(deltaX+70.0f, deltaY+92.0f, 180.0f, 180.0f);
                _titleLabel.frame = CGRectMake(deltaX+0.0f, deltaY+286.0f, 320.0f, 36.0f);
                _descriptionLabel.frame = CGRectMake(deltaX+40.0f, deltaY+326.0f, 240.0f, 100.0f);
                _accessButton.frame = CGRectMake(deltaX+110.0f, deltaY+444.0f, 100.0f, 30.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 54.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 85.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(120.0f, 120.0f, 240.0f, 100.0f);
                _accessButton.frame = CGRectMake(190.0f, 220.0f, 100.0f, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 110.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 150.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 210.0f, 240.0f, 100.0f);
                _accessButton.frame = CGRectMake(110.0f, 360.0f, 100.0f, 30.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 100.0f, 300.0f, 300.0f);
            _titleLabel.frame = CGRectMake(412.0f, 410.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(272.0f, 460.0f, 480.0f, 100.0f);
            _accessButton.frame = CGRectMake(432.0f, 576.0f, 160.0f, 50.0f);
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 150.0f, 400.0f, 400.0f);
            _titleLabel.frame = CGRectMake(284.0f, 580.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(144.0f, 640.0f, 480.0f, 100.0f);
            _accessButton.frame = CGRectMake(304.0f, 800.0f, 160.0f, 50.0f);
        }
    }
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PXSettingsViewController *viewController = [[PXSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark UIButtonAction
- (void)accessButtonAction {
    __weak typeof(self) wself = self;
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [PEAssetsManager requestAuthorizationWithCompletion:^(BOOL isStatusAuthorized) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (isStatusAuthorized) {
                if (sself.completion) {
                    sself.completion();
                }
            }
            else {
                [sself setDescriptionLabelText];
                [sself updateAccessButton];
            }
        }];
    }
    else {
        [[PLAssetsManager sharedManager] testAccessPhotoLibraryWithCompletion:^(NSError *error) {
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
            }
            typeof(wself) sself = wself;
            if (!sself) return;
            if ([PEAssetsManager isStatusAuthorized]) {
                if (sself.completion) {
                    sself.completion();
                }
            }
            else {
                [sself setDescriptionLabelText];
                [sself updateAccessButton];
            }
        }];
    }
}

#pragma mark OtherMethods
- (void)setDescriptionLabelText {
    if ([PEAssetsManager isStatusAuthorized] || [PEAssetsManager isStatusNotDetermined]) {
        _descriptionLabel.text = NSLocalizedString(@"You can manage smartly your Photo Library photos, albums, and videos with Photti.", nil);
    }
    else {
        _descriptionLabel.text = NSLocalizedString(@"Go to Settings > Privacy > Photos and switch Photti to ON to access Photo Library.", nil);
    }
}

- (void)updateAccessButton {
    if ([PEAssetsManager isStatusAuthorized] || [PEAssetsManager isStatusNotDetermined]) {
        _accessButton.alpha = 1.0f;
        _accessButton.enabled = YES;
    }
    else {
        _accessButton.alpha = 0.5f;
        _accessButton.enabled = NO;
    }
}

@end
