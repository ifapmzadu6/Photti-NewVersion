//
//  PWGoogleLoginViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import AssetsLibrary;

#import "PWGoogleLoginViewController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import "PLAssetsManager.h"
#import "PATabBarAdsController.h"

@interface PWGoogleLoginViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *loginButton;
@property (strong, nonatomic) UIButton *skipButton;

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
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PicasaLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PAColors getColor:kPAColorsTypeTintWebColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PAColors getColor:kPAColorsTypeTintWebColor] colorWithAlphaComponent:0.667f];
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
    _titleLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
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
    _descriptionLabel.textColor = [PAColors getColor:kPAColorsTypeTextLightColor];
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
    [_loginButton setTitleColor:[PAColors getColor:kPAColorsTypeTintWebColor] forState:UIControlStateHighlighted];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:kPAColorsTypeTintWebColor]] forState:UIControlStateNormal];
    [_loginButton setBackgroundImage:[PAIcons imageWithColor:[PAColors getColor:kPAColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _loginButton.clipsToBounds = YES;
    _loginButton.layer.borderColor = [PAColors getColor:kPAColorsTypeTintWebColor].CGColor;
    _loginButton.layer.borderWidth = 1.0f;
    _loginButton.layer.cornerRadius = 5.0f;
    _loginButton.exclusiveTouch = YES;
    [self.view addSubview:_loginButton];
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        _skipButton = [UIButton new];
        [_skipButton addTarget:self action:@selector(skipButtonAction) forControlEvents:UIControlEventTouchUpInside];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _skipButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        }
        else {
            _skipButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        }
        [_skipButton setTitle:NSLocalizedString(@"Skip", nil) forState:UIControlStateNormal];
        [_skipButton setTitleColor:[PAColors getColor:kPAColorsTypeTintWebColor] forState:UIControlStateNormal];
        [_skipButton setTitleColor:[[PAColors getColor:kPAColorsTypeTintWebColor] colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
        _skipButton.exclusiveTouch = YES;
        [self.view addSubview:_skipButton];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
    
//    [PWPicasaAPI getListOfAlbumsWithIndex:0 completion:^(NSUInteger nextIndex, NSError *error) {
//        if (!error) {
//            <#statements#>
//        }
//    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds))) > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                CGFloat deltaX = (CGRectGetWidth(rect)-568.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight(rect)-320.0f)/2.0f;
                _iconImageView.frame = CGRectMake(deltaX+64.0f, deltaY+80.0f, 180.0f, 180.0f);
                if (!_skipButton) {
                    _titleLabel.frame = CGRectMake(deltaX+250.0f, deltaY+286.0f-190.0f, 320.0f, 36.0f);
                    _descriptionLabel.frame = CGRectMake(deltaX+250.0f+40.0f, deltaY+326.0f-202.0f, 240.0f, 100.0f);
                    _loginButton.frame = CGRectMake(deltaX+250.0f+110.0f, deltaY+444.0f-224.0f, 100.0f, 30.0f);
                }
                else {
                    _titleLabel.frame = CGRectMake(deltaX+250.0f, deltaY+286.0f-200.0f, 320.0f, 36.0f);
                    _descriptionLabel.frame = CGRectMake(deltaX+250.0f+40.0f, deltaY+326.0f-212.0f, 240.0f, 100.0f);
                    _loginButton.frame = CGRectMake(deltaX+250.0f+110.0f, deltaY+444.0f-238.0f, 100.0f, 30.0f);
                    _skipButton.frame = CGRectMake(deltaX+250.0f+110.0f, deltaY+468.0f-224.0f, 100.0f, 30.0f);
                }
            }
            else {
                CGFloat deltaX = (CGRectGetWidth(rect)-320.0f)/2.0f;
                CGFloat deltaY = (CGRectGetHeight(rect)-568.0f)/2.0f;
                _iconImageView.frame = CGRectMake(deltaX+70.0f, deltaY+90.0f, 180.0f, 180.0f);
                _titleLabel.frame = CGRectMake(deltaX, deltaY+286.0f, 320.0f, 36.0f);
                _descriptionLabel.frame = CGRectMake(deltaX+40.0f, deltaY+316.0f, 240.0f, 100.0f);
                if (!_skipButton) {
                    _descriptionLabel.frame = CGRectMake(deltaX+40.0f, deltaY+326.0f, 240.0f, 100.0f);
                    _loginButton.frame = CGRectMake(deltaX+110.0f, deltaY+444.0f, 100.0f, 30.0f);
                }
                else {
                    _loginButton.frame = CGRectMake(deltaX+110.0f, deltaY+420.0f, 100.0f, 30.0f);
                    _skipButton.frame = CGRectMake(deltaX+110.0f, deltaY+468.0f, 100.0f, 30.0f);
                }
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 54.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 85.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(120.0f, 120.0f, 240.0f, 100.0f);
                if (!_skipButton) {
                    _descriptionLabel.frame = CGRectMake(120.0f, 120.0f, 240.0f, 100.0f);
                    _loginButton.frame = CGRectMake(190.0f, 220.0f, 100.0f, 30.0f);
                }
                else {
                    _descriptionLabel.frame = CGRectMake(120.0f, 110.0f, 240.0f, 100.0f);
                    _loginButton.frame = CGRectMake(190.0f, 204.0f, 100.0f, 30.0f);
                    _skipButton.frame = CGRectMake(190.0f, 242.0f, 100.0f, 30.0f);
                }
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 110.0f, 240.0f, 240.0f);
                _titleLabel.frame = CGRectMake(0.0f, 150.0f, CGRectGetWidth(rect), 36.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 210.0f, 240.0f, 100.0f);
                if (!_skipButton) {
                    _loginButton.frame = CGRectMake(110.0f, 360.0f, 100.0f, 30.0f);
                }
                else {
                    _loginButton.frame = CGRectMake(110.0f, 330.0f, 100.0f, 30.0f);
                    _skipButton.frame = CGRectMake(110.0f, 376.0f, 100.0f, 30.0f);
                }
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 100.0f, 300.0f, 300.0f);
            _titleLabel.frame = CGRectMake(412.0f, 410.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(272.0f, 460.0f, 480.0f, 100.0f);
            if (!_skipButton) {
                _loginButton.frame = CGRectMake(432.0f, 576.0f, 160.0f, 50.0f);
            }
            else {
                _loginButton.frame = CGRectMake(432.0f, 566.0f, 160.0f, 50.0f);
                _skipButton.frame = CGRectMake(432.0f, 630.0f, 160.0f, 50.0f);
            }
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 150.0f, 400.0f, 400.0f);
            _titleLabel.frame = CGRectMake(284.0f, 580.0f, 200.0f, 50.0f);
            _descriptionLabel.frame = CGRectMake(144.0f, 640.0f, 480.0f, 100.0f);
            if (!_skipButton) {
                _loginButton.frame = CGRectMake(304.0f, 800.0f, 160.0f, 50.0f);
            }
            else {
                _loginButton.frame = CGRectMake(304.0f, 770.0f, 160.0f, 50.0f);
                _skipButton.frame = CGRectMake(304.0f, 850.0f, 160.0f, 50.0f);
            }
        }
    }
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

- (void)skipButtonAction {
    if (_skipAction) {
        _skipAction();
    }
}

#pragma mark UIBarButtonItem
- (void)cancelBarButtonAction {
    UIViewController *viewController = _authViewTouchNavigationController;
    if (!viewController) return;
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
