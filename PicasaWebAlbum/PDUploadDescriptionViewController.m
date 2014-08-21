//
//  PDUploadDescriptionViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDUploadDescriptionViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PDTaskManager.h"
#import "PWTabBarAdsController.h"

#import "PWSettingsViewController.h"

@interface PDUploadDescriptionViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *uploadSettingLabel;
@property (strong, nonatomic) UILabel *unlimitedLabel;
@property (strong, nonatomic) UILabel *unlimitedDescriptionLabel;
@property (strong, nonatomic) UIButton *unlimitedButton;
@property (strong, nonatomic) UILabel *highResolutionLabel;
@property (strong, nonatomic) UITextView *highResolutionDescriptionLabel;
@property (strong, nonatomic) UIButton *highResolutionButton;

@end

@implementation PDUploadDescriptionViewController

static NSString * const kPDGoogleDriveURL = @"https://www.google.com/settings/storage";

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", nil);
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
    _iconImageView.image = [[UIImage imageNamed:@"UploadLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.667f];
    }
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _uploadSettingLabel = [UILabel new];
    _uploadSettingLabel.text = NSLocalizedString(@"Uploading Setting", nil);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _uploadSettingLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _uploadSettingLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _uploadSettingLabel.textColor = [PWColors getColor:PWColorsTypeTextLightSubColor];
    _uploadSettingLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_uploadSettingLabel];
    
    _unlimitedLabel = [UILabel new];
    _unlimitedLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Unlimited", nil) attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _unlimitedLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _unlimitedLabel.textColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    _unlimitedLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_unlimitedLabel];
    
    _unlimitedDescriptionLabel = [UILabel new];
    _unlimitedDescriptionLabel.text = NSLocalizedString(@"Photos smaller than 2048x2048 pixels are unlimitedly FREE! Everything bigger than that is resized when uploading.", nil);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedDescriptionLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    else {
        _unlimitedDescriptionLabel.font = [UIFont systemFontOfSize:16.0f];
    }
    _unlimitedDescriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _unlimitedDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    _unlimitedDescriptionLabel.numberOfLines = 0;
    [self.view addSubview:_unlimitedDescriptionLabel];
    
    _unlimitedButton = [UIButton new];
    [_unlimitedButton addTarget:self action:@selector(unlimitedButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _unlimitedButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_unlimitedButton setTitle:NSLocalizedString(@"Resizing", nil) forState:UIControlStateNormal];
    [_unlimitedButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_unlimitedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_unlimitedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_unlimitedButton setBackgroundImage:nil forState:UIControlStateNormal];
    [_unlimitedButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateSelected];
    [_unlimitedButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateHighlighted];
    _unlimitedButton.clipsToBounds = YES;
    _unlimitedButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintUploadColor].CGColor;
    _unlimitedButton.layer.borderWidth = 1.0f;
    _unlimitedButton.layer.cornerRadius = 5.0f;
    _unlimitedButton.exclusiveTouch = YES;
    [self.view addSubview:_unlimitedButton];
    
    _highResolutionLabel = [UILabel new];
    _highResolutionLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"High Resolution", nil) attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _highResolutionLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _highResolutionLabel.textAlignment = NSTextAlignmentCenter;
    _highResolutionLabel.textColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    [self.view addSubview:_highResolutionLabel];
    
    _highResolutionDescriptionLabel = [UITextView new];
    _highResolutionDescriptionLabel.clipsToBounds = NO;
    _highResolutionDescriptionLabel.backgroundColor = [UIColor clearColor];
    _highResolutionDescriptionLabel.scrollEnabled = NO;
    _highResolutionDescriptionLabel.editable = NO;
    _highResolutionDescriptionLabel.textContainer.lineFragmentPadding = 0;
    _highResolutionDescriptionLabel.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    NSString *string = NSLocalizedString(@"Photos bigger than 2048x2048 pixels and videos longer than 15minutes use your Google Storage.", nil);
    NSRange linkRange = [string rangeOfString:@"Google Storage"];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    [attributedString addAttribute:NSLinkAttributeName value:kPDGoogleDriveURL range:linkRange];
    
    _highResolutionDescriptionLabel.attributedText = attributedString;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionDescriptionLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    else {
        _highResolutionDescriptionLabel.font = [UIFont systemFontOfSize:16.0f];
    }
    _highResolutionDescriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _highResolutionDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_highResolutionDescriptionLabel];
    
    _highResolutionButton = [UIButton new];
    [_highResolutionButton addTarget:self action:@selector(highResolutionButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _highResolutionButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_highResolutionButton setTitle:NSLocalizedString(@"Original", nil) forState:UIControlStateNormal];
    [_highResolutionButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_highResolutionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_highResolutionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_highResolutionButton setBackgroundImage:nil forState:UIControlStateNormal];
    [_highResolutionButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateSelected];
    [_highResolutionButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateHighlighted];
    _highResolutionButton.clipsToBounds = YES;
    _highResolutionButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintUploadColor].CGColor;
    _highResolutionButton.layer.borderWidth = 1.0f;
    _highResolutionButton.layer.cornerRadius = 5.0f;
    _highResolutionButton.exclusiveTouch = YES;
    [self.view addSubview:_highResolutionButton];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
        [self setUnlimited];
    }
    else {
        [self setHighResolution];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
        [self setUnlimited];
    }
    else {
        [self setHighResolution];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height > 480)) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(46.0f, 80.0f, 170.0f, 170.0f);
                _uploadSettingLabel.frame = CGRectMake(244.0f + 0.0f, 272.0f - 210.0f, CGRectGetHeight(rect), 20.0f);
                _unlimitedLabel.frame = CGRectMake(244.0f + 15.0f, 310.0f - 220.0f, 140.0f, 20.0f);
                _highResolutionLabel.frame = CGRectMake(244.0f + 165.0f, 310.0f - 220.0f, 140.0f, 20.0f);
                CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
                CGFloat buttonMinY = 450.0f - 220.0f;
                CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _unlimitedDescriptionLabel.frame = CGRectMake(244.0f + 10.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 140.0f, unlimitedDescriptionLabelSize.height);
                CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _highResolutionDescriptionLabel.frame = CGRectMake(244.0f + 165.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 140.0f, highResolutionDescriptionLabelSize.height);
                _unlimitedButton.frame = CGRectMake(244.0f + 30.0f, 458.0f - 220.0f, 110.0, 30.0f);
                _highResolutionButton.frame = CGRectMake(244.0f + 180.0f, 458.0f - 220.0f, 110.0, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(70.0f, 86.0f, 170.0f, 170.0f);
                _uploadSettingLabel.frame = CGRectMake(0.0f, 272.0f, CGRectGetWidth(rect), 20.0f);
                _unlimitedLabel.frame = CGRectMake(15.0f, 304.0f, 140.0f, 20.0f);
                _highResolutionLabel.frame = CGRectMake(165.0f, 304.0f, 140.0f, 20.0f);
                CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
                CGFloat buttonMinY = 444.0f;
                CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _unlimitedDescriptionLabel.frame = CGRectMake(15.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 140.0f, unlimitedDescriptionLabelSize.height);
                CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _highResolutionDescriptionLabel.frame = CGRectMake(165.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 140.0f, highResolutionDescriptionLabelSize.height);
                _unlimitedButton.frame = CGRectMake(30.0f, 454.0f, 110.0, 30.0f);
                _highResolutionButton.frame = CGRectMake(180.0f, 454.0f, 110.0, 30.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 48.0f, 240.0f, 240.0f);
                _uploadSettingLabel.frame = CGRectMake(0.0f, 272.0f - 210.0f, CGRectGetWidth(rect), 20.0f);
                _unlimitedLabel.frame = CGRectMake(75.0f + 15.0f, 310.0f - 220.0f, 140.0f, 20.0f);
                _highResolutionLabel.frame = CGRectMake(75.0f + 165.0f, 310.0f - 220.0f, 140.0f, 20.0f);
                CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
                CGFloat buttonMinY = 450.0f - 220.0f;
                CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _unlimitedDescriptionLabel.frame = CGRectMake(75.0f + 10.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 140.0f, unlimitedDescriptionLabelSize.height);
                CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _highResolutionDescriptionLabel.frame = CGRectMake(75.0f + 165.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 140.0f, highResolutionDescriptionLabelSize.height);
                _unlimitedButton.frame = CGRectMake(75.0f + 30.0f, 458.0f - 220.0f, 110.0, 30.0f);
                _highResolutionButton.frame = CGRectMake(75.0f + 180.0f, 458.0f - 220.0f, 110.0, 30.0f);
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 110.0f, 240.0f, 240.0f);
                _uploadSettingLabel.frame = CGRectMake(0.0f, 120.0f, CGRectGetWidth(rect), 20.0f);
                _unlimitedLabel.frame = CGRectMake(15.0f, 170.0f, 140.0f, 20.0f);
                _highResolutionLabel.frame = CGRectMake(165.0f, 170.0f, 140.0f, 20.0f);
                CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
                CGFloat buttonMinY = 340.0f;
                CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _unlimitedDescriptionLabel.frame = CGRectMake(15.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 140.0f, unlimitedDescriptionLabelSize.height);
                CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(140.0f, CGFLOAT_MAX)];
                _highResolutionDescriptionLabel.frame = CGRectMake(165.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 140.0f, highResolutionDescriptionLabelSize.height);
                _unlimitedButton.frame = CGRectMake(30.0f, 360.0f, 110.0, 30.0f);
                _highResolutionButton.frame = CGRectMake(180.0f, 360.0f, 110.0, 30.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 80.0f, 300.0f, 300.0f);
            _uploadSettingLabel.frame = CGRectMake(412.0f, 400.0f, 200.0f, 20.0f);
            _unlimitedLabel.frame = CGRectMake(242.0f, 440.0f, 240.0f, 20.0f);
            _highResolutionLabel.frame = CGRectMake(542.0f, 440.0f, 240.0f, 20.0f);
            CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
            CGFloat buttonMinY = 600.0f;
            CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(240.0f, CGFLOAT_MAX)];
            _unlimitedDescriptionLabel.frame = CGRectMake(242.0f + 10.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 240.0f, unlimitedDescriptionLabelSize.height);
            CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(240.0f, CGFLOAT_MAX)];
            _highResolutionDescriptionLabel.frame = CGRectMake(542.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 240.0f, highResolutionDescriptionLabelSize.height);
            _unlimitedButton.frame = CGRectMake(282.0f, 610.0f, 160.0f, 50.0f);
            _highResolutionButton.frame = CGRectMake(582.0f, 610.0f, 160.0f, 50.0f);
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 90.0f, 400.0f, 400.0f);
            _uploadSettingLabel.frame = CGRectMake(284.0f, 540.0f, 200.0f, 20.0f);
            _unlimitedLabel.frame = CGRectMake(114.0f, 600.0f, 240.0f, 20.0f);
            _highResolutionLabel.frame = CGRectMake(414.0f, 600.0f, 240.0f, 20.0f);
            CGFloat titleLabelMaxY = CGRectGetMaxY(_unlimitedLabel.frame);
            CGFloat buttonMinY = 780.0f;
            CGSize unlimitedDescriptionLabelSize = [_unlimitedDescriptionLabel sizeThatFits:CGSizeMake(240.0f, CGFLOAT_MAX)];
            _unlimitedDescriptionLabel.frame = CGRectMake(114.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-unlimitedDescriptionLabelSize.height)/2.0f, 240.0f, unlimitedDescriptionLabelSize.height);
            CGSize highResolutionDescriptionLabelSize = [_highResolutionDescriptionLabel sizeThatFits:CGSizeMake(240.0f, CGFLOAT_MAX)];
            _highResolutionDescriptionLabel.frame = CGRectMake(414.0f, titleLabelMaxY + ((buttonMinY-titleLabelMaxY)-(highResolutionDescriptionLabelSize.height))/2.0f, 240.0f, highResolutionDescriptionLabelSize.height);
            _unlimitedButton.frame = CGRectMake(154.0f, 816.0f, 160.0f, 50.0f);
            _highResolutionButton.frame = CGRectMake(454.0f, 816.0f, 160.0f, 50.0f);
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonAction
- (void)settingsBarButtonAction {
    PWSettingsViewController *viewController = [[PWSettingsViewController alloc] initWithInitType:PWSettingsViewControllerInitTypeTaskManager];
    [self.tabBarController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark UIButtonAction
- (void)unlimitedButtonAction {
    if (_unlimitedButton.selected) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPDTaskManagerIsResizePhotosKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setUnlimited];
}

- (void)highResolutionButtonAction {
    if (_highResolutionButton.selected) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPDTaskManagerIsResizePhotosKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setHighResolution];
}

- (void)setUnlimited {
    _unlimitedButton.selected = YES;
    _highResolutionButton.selected = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    else {
        _unlimitedLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _highResolutionLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedDescriptionLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    }
    else {
        _unlimitedDescriptionLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionDescriptionLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    else {
        _highResolutionDescriptionLabel.font = [UIFont systemFontOfSize:16.0f];
    }
}

- (void)setHighResolution {
    _highResolutionButton.selected = YES;
    _unlimitedButton.selected = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _unlimitedLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    }
    else {
        _highResolutionLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _unlimitedDescriptionLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    else {
        _unlimitedDescriptionLabel.font = [UIFont systemFontOfSize:16.0f];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _highResolutionDescriptionLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    }
    else {
        _highResolutionDescriptionLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    }
}

- (void)openGoogleDriveButtonAction {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kPDGoogleDriveURL]];
}

@end
