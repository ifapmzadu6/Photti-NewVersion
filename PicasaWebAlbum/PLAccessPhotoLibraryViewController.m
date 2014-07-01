//
//  PLAccessPhotoLibraryViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLAccessPhotoLibraryViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"

#import "PWSettingsViewController.h"
#import "PWShareAction.h"

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
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareBarButtonAction)];
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PictureLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintLocalColor] colorWithAlphaComponent:0.3f];
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
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
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
    _descriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
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
    [_accessButton setTitleColor:[PWColors getColor:PWColorsTypeTintLocalColor] forState:UIControlStateNormal];
    [_accessButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_accessButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintLocalColor]] forState:UIControlStateHighlighted];
    _accessButton.clipsToBounds = YES;
    _accessButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintLocalColor].CGColor;
    _accessButton.layer.borderWidth = 1.0f;
    _accessButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:_accessButton];
    
    [self updateAccessButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setDescriptionLabelText];
    [self updateAccessButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(70.0f, 80.0f, 180.0f, 180.0f);
            _titleLabel.frame = CGRectMake(250.0f, 286.0f - 192.0f, CGRectGetHeight(rect), 36.0f);
            _descriptionLabel.frame = CGRectMake(250.0f + 40.0f, 326.0f - 212.0f, 240.0f, 100.0f);
            _accessButton.frame = CGRectMake(250.0f + 110.0f, 444.0f - 227.0f, 100.0f, 30.0f);
        }
        else {
            _iconImageView.frame = CGRectMake(70.0f, 92.0f, 180.0f, 180.0f);
            _titleLabel.frame = CGRectMake(0.0f, 286.0f, CGRectGetWidth(rect), 36.0f);
            _descriptionLabel.frame = CGRectMake(40.0f, 326.0f, 240.0f, 100.0f);
            _accessButton.frame = CGRectMake(110.0f, 444.0f, 100.0f, 30.0f);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeLocal];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)shareBarButtonAction {
    [PWShareAction showFromViewController:self.tabBarController];
}

#pragma mark UIButtonAction
- (void)accessButtonAction {
    __weak typeof(self) wself = self;
    [[PLAssetsManager sharedManager] testAccessPhotoLibraryWithCompletion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.description);
        }
        typeof(wself) sself = wself;
        if (!sself) return;
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
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

#pragma mark OtherMethods
- (void)setDescriptionLabelText {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized || [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        _descriptionLabel.text = NSLocalizedString(@"You can manage smartly your Photo Library photos, albums, and videos with Photti.", nil);
    }
    else {
        _descriptionLabel.text = NSLocalizedString(@"Go to Settings > Privacy > Photos and switch Photti to ON to access Photo Library.", nil);
    }
}

- (void)updateAccessButton {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized || [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        _accessButton.alpha = 1.0f;
        _accessButton.enabled = YES;
    }
    else {
        _accessButton.alpha = 0.5f;
        _accessButton.enabled = NO;
    }
}

@end
