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
#import "PWPicasaAPI.h"

#import "PWSettingsViewController.h"
#import "PWShareAction.h"

@interface PWGoogleLoginViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *loginButton;

@property (weak, nonatomic) UIViewController *authViewTouchNavigationController;

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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsBarButtonAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareBarButtonAction)];
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PicasaLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintWebColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintWebColor] colorWithAlphaComponent:0.667f];
    }
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = NSLocalizedString(@"Picasa Web Albums\n(Google+ Photos)", nil);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 2;
    [self.view addSubview:_titleLabel];
    
    _descriptionLabel = [UILabel new];
    _descriptionLabel.text = NSLocalizedString(@"You can manage your Picasa Web Albums (Google+ Photos), photos, albums, and videos with Photti", nil);
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
    
    _loginButton = [UIButton new];
    [_loginButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _loginButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _loginButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [_loginButton setTitleColor:[PWColors getColor:PWColorsTypeTintWebColor] forState:UIControlStateHighlighted];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintWebColor]] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _loginButton.clipsToBounds = YES;
    _loginButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintWebColor].CGColor;
    _loginButton.layer.borderWidth = 1.0f;
    _loginButton.layer.cornerRadius = 5.0f;
    _loginButton.exclusiveTouch = YES;
    [self.view addSubview:_loginButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)[[UIScreen mainScreen] bounds].size.height > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(64.0f, 80.0f, 180.0f, 180.0f);
                _titleLabel.frame = CGRectMake(250.0f + 0.0f, 286.0f - 190.0f, CGRectGetHeight(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(250.0f + 40.0f, 326.0f - 202.0f, 240.0f, 100.0f);
                _loginButton.frame = CGRectMake(250.0f + 110.0f, 444.0f - 224.0f, 100.0f, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(70.0f, 90.0f, 180.0f, 180.0f);
                _titleLabel.frame = CGRectMake(0.0f, 286.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 326.0f, 240.0f, 100.0f);
                _loginButton.frame = CGRectMake(110.0f, 444.0f, 100.0f, 30.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 54.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 85.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(120.0f, 120.0f, 240.0f, 100.0f);
                _loginButton.frame = CGRectMake(190.0f, 220.0f, 100.0f, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 110.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 150.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 210.0f, 240.0f, 100.0f);
                _loginButton.frame = CGRectMake(110.0f, 360.0f, 100.0f, 30.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 100.0f, 300.0f, 300.0f);
            _titleLabel.frame = CGRectMake(412.0f, 410.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(272.0f, 460.0f, 480.0f, 100.0f);
            _loginButton.frame = CGRectMake(432.0f, 576.0f, 160.0f, 50.0f);
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 150.0f, 400.0f, 400.0f);
            _titleLabel.frame = CGRectMake(284.0f, 580.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(144.0f, 640.0f, 480.0f, 100.0f);
            _loginButton.frame = CGRectMake(304.0f, 800.0f, 160.0f, 50.0f);
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeWeb];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

- (void)shareBarButtonAction {
    [PWShareAction showFromViewController:self.tabBarController];
}

#pragma mark UIButton
- (void)loginButtonAction {
    if ([PWOAuthManager isLogined]) {
        if (_completion) {
            _completion();
        }
    }
    else {
        __weak typeof(self) wself = self;
        [PWOAuthManager loginViewControllerWithCompletion:^(UINavigationController *navigationController) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:sself action:@selector(cancelBarButtonAction)];
                navigationController.visibleViewController.navigationItem.leftBarButtonItem  = cancelBarButtonItem;
                
                sself.authViewTouchNavigationController = navigationController;
                [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
            });
        } finish:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (sself.completion) {
                    sself.completion();
                }
            });
        }];
    }
}

- (void)cancelBarButtonAction {
    UIViewController *viewController = _authViewTouchNavigationController;
    if (!viewController) return;
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
