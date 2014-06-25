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
    
    _iconImageView = [UIImageView new];
    _iconImageView.image = [[UIImage imageNamed:@"PicasaLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintWebColor] colorWithAlphaComponent:0.3f];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _titleLabel = [UILabel new];
    _titleLabel.text = NSLocalizedString(@"Picasa Web Albums\n(Google+ Photos)", nil);
    _titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _titleLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 2;
    [self.view addSubview:_titleLabel];
    
    _descriptionLabel = [UILabel new];
    _descriptionLabel.text = NSLocalizedString(@"You can manage your Picasa Web Albums (Google+ Photos), photos, albums, and videos with Photti 2", nil);
    _descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    _descriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.numberOfLines = 0;
    [self.view addSubview:_descriptionLabel];
    
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
    
    _iconImageView.frame = CGRectMake(70.0f, 90.0f, 180.0f, 180.0f);
    
    _titleLabel.frame = CGRectMake(0.0f, 286.0f, CGRectGetWidth(rect), 36.0f);
    
    _descriptionLabel.frame = CGRectMake(40.0f, 326.0f, 240.0f, 100.0f);
    
    _loginButton.frame = CGRectMake(110.0f, 444.0f, 100.0f, 30.0f);
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

#pragma mark UIButton
- (void)loginButtonAction {
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

- (void)cancelBarButtonAction {
    UIViewController *viewController = _authViewTouchNavigationController;
    if (!viewController) {
        return;
    }
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
