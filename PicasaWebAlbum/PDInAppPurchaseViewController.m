//
//  PDInAppPurchaseViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDInAppPurchaseViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PDInAppPurchase.h"
#import "PWShareAction.h"

#import "PWSettingsViewController.h"

@interface PDInAppPurchaseViewController ()

@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UILabel *priceLabel;
@property (strong, nonatomic) UILabel *inAppPurchaseLabel;
@property (strong, nonatomic) UIButton *purchaseButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIButton *restoreButton;

@property (strong, nonatomic) SKProduct *product;

@end

@implementation PDInAppPurchaseViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Task Manager", nil);
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
    _iconImageView.image = [[UIImage imageNamed:@"UploadLarge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && ((int)[[UIScreen mainScreen] bounds].size.height == 480)) {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.1f];
    }
    else {
        _iconImageView.tintColor = [[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.667f];
    }
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_iconImageView];
    
    _descriptionLabel = [UILabel new];
    //_descriptionLabel.text = @"アップロード/ダウンロード機能を有効にすると写真をウェブに無制限にアップロードまたはダウンロードできます。";
    _descriptionLabel.text = NSLocalizedString(@"Purchasing Upload-Download Addon, you can download or upload unlimitedly to Web Album by Photti.", nil);
    _descriptionLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _descriptionLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _descriptionLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _descriptionLabel.numberOfLines = 0;
    [self.view addSubview:_descriptionLabel];
    
    _priceLabel = [UILabel new];
    _priceLabel.textColor = [PWColors getColor:PWColorsTypeTextLightColor];
    _priceLabel.textAlignment = NSTextAlignmentCenter;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _priceLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _priceLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    _priceLabel.hidden = YES;
    [self.view addSubview:_priceLabel];
    
    _inAppPurchaseLabel = [UILabel new];
    _inAppPurchaseLabel.text = @"In-App Purchase";
    _inAppPurchaseLabel.textColor = [PWColors getColor:PWColorsTypeTextLightSubColor];
    _inAppPurchaseLabel.textAlignment = NSTextAlignmentCenter;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _inAppPurchaseLabel.font = [UIFont systemFontOfSize:7.0f];
    }
    else {
        _inAppPurchaseLabel.font = [UIFont systemFontOfSize:9.0f];
    }
    _inAppPurchaseLabel.hidden = YES;
    [self.view addSubview:_inAppPurchaseLabel];
    
    _purchaseButton = [UIButton new];
    [_purchaseButton addTarget:self action:@selector(purchaseButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _purchaseButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    else {
        _purchaseButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    [_purchaseButton setTitle:NSLocalizedString(@"Purchase", nil) forState:UIControlStateNormal];
    _purchaseButton.layer.borderColor = [PWColors getColor:PWColorsTypeTintUploadColor].CGColor;
    _purchaseButton.layer.borderWidth = 1.0f;
    _purchaseButton.layer.cornerRadius = 5.0f;
    _purchaseButton.clipsToBounds = YES;
    [_purchaseButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateHighlighted];
    [_purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_purchaseButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeTintUploadColor]] forState:UIControlStateNormal];
    [_purchaseButton setBackgroundImage:[PWIcons imageWithColor:[PWColors getColor:PWColorsTypeBackgroundLightColor]] forState:UIControlStateHighlighted];
    _purchaseButton.enabled = NO;
    _purchaseButton.alpha = 0.5f;
    _purchaseButton.exclusiveTouch = YES;
    [self.view addSubview:_purchaseButton];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_activityIndicatorView startAnimating];
    [self.view addSubview:_activityIndicatorView];
    
    _restoreButton = [UIButton new];
    [_restoreButton addTarget:self action:@selector(restoreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _restoreButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    }
    else {
        _restoreButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    [_restoreButton setTitle:NSLocalizedString(@"Restore purchase", NSLocalizedString) forState:UIControlStateNormal];
    [_restoreButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_restoreButton setTitleColor:[[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.2f] forState:UIControlStateHighlighted];
    _restoreButton.exclusiveTouch = YES;
    [self.view addSubview:_restoreButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _priceLabel.hidden = YES;
    _inAppPurchaseLabel.hidden = YES;
    _purchaseButton.enabled = NO;
    _purchaseButton.alpha = 0.5f;
    [_activityIndicatorView startAnimating];
    
    if (![SKPaymentQueue canMakePayments]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"In-App Purchase is restricted", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil) , nil] show];
    }
    else {
        __weak typeof(self) wself = self;
        [PDInAppPurchase getProductsWithProductIDs:@[kPDRemoveAdsPuroductID] completion:^(NSArray *products, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
                NSLog(@"%@", error.description);
                return;
            }
            
            for (SKProduct *product in products) {
                if ([product.productIdentifier isEqualToString:kPDRemoveAdsPuroductID]) {
                    sself.product = products.firstObject;
                    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:product.priceLocale];
                    NSString *price = [numberFormatter stringFromNumber:product.price];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        sself.priceLabel.text = price;
                        sself.priceLabel.hidden = NO;
                        sself.inAppPurchaseLabel.hidden = NO;
                        sself.purchaseButton.enabled = YES;
                        sself.purchaseButton.alpha = 1.0f;
                        [sself.activityIndicatorView stopAnimating];
                    });
                    break;
                }
            }
        }];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)[[UIScreen mainScreen] bounds].size.height > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(60.0f, 70.0f, 180.0f, 180.0f);
                _descriptionLabel.frame = CGRectMake(250.0f + 40.0f, 282.0f - 220.0f, 240.0f, 100.0f);
                _priceLabel.frame = CGRectMake(250.0f + 110.0f, 390.0f - 220.0f, 100.0f, 15.0f);
                _inAppPurchaseLabel.frame = CGRectMake(250.0f + 0.0f, CGRectGetMinY(_priceLabel.frame) - 9.0f, CGRectGetHeight(rect), 7.0f);
                _activityIndicatorView.center = _priceLabel.center;
                _purchaseButton.frame = CGRectMake(250.0f + 110.0f, 428.0f - 220.0f, 100.0f, 30.0f);
                CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
                _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 10.0f, 258.0f, restoreButtonSize.width, restoreButtonSize.height);
            }
            else {
                _iconImageView.frame = CGRectMake(70.0f, 90.0f, 180.0f, 180.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 282.0f, 240.0f, 100.0f);
                _priceLabel.frame = CGRectMake(110.0f, 390.0f, 100.0f, 15.0f);
                _inAppPurchaseLabel.frame = CGRectMake(0.0f, CGRectGetMinY(_priceLabel.frame) - 9.0f, CGRectGetWidth(rect), 7.0f);
                _activityIndicatorView.center = _priceLabel.center;
                _purchaseButton.frame = CGRectMake(110.0f, 428.0f, 100.0f, 30.0f);
                CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
                _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 10.0f, 494.0f, restoreButtonSize.width, restoreButtonSize.height);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                _iconImageView.frame = CGRectMake(120.0f, 47.0f, 240.0f, 240.0f);
                _descriptionLabel.frame = CGRectMake(120.0f, 282.0f - 220.0f, 240.0f, 100.0f);
                _priceLabel.frame = CGRectMake(190.0f, 390.0f - 220.0f, 100.0f, 15.0f);
                _inAppPurchaseLabel.frame = CGRectMake(210.0f, CGRectGetMinY(_priceLabel.frame) - 9.0f, CGRectGetHeight(rect), 7.0f);
                _activityIndicatorView.center = _priceLabel.center;
                _purchaseButton.frame = CGRectMake(190.0f, 428.0f - 220.0f, 100.0f, 30.0f);
                CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
                _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 10.0f, 258.0f, restoreButtonSize.width, restoreButtonSize.height);
            }
            else {
                _iconImageView.frame = CGRectMake(40.0f, 100.0f, 240.0f, 240.0f);
                _descriptionLabel.frame = CGRectMake(40.0f, 190.0f, 240.0f, 100.0f);
                _priceLabel.frame = CGRectMake(110.0f, 310.0f, 100.0f, 15.0f);
                _inAppPurchaseLabel.frame = CGRectMake(0.0f, CGRectGetMinY(_priceLabel.frame) - 9.0f, CGRectGetWidth(rect), 7.0f);
                _activityIndicatorView.center = _priceLabel.center;
                _purchaseButton.frame = CGRectMake(110.0f, 360.0f, 100.0f, 30.0f);
                CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
                _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 10.0f, 408.0f, restoreButtonSize.width, restoreButtonSize.height);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _iconImageView.frame = CGRectMake(362.0f, 100.0f, 300.0f, 300.0f);
            _descriptionLabel.frame = CGRectMake(272.0f, 410.0f, 480.0f, 100.0f);
            _priceLabel.frame = CGRectMake(462.0f, 526.0f, 100.0f, 15.0f);
            _inAppPurchaseLabel.frame = CGRectMake(462.0f, CGRectGetMinY(_priceLabel.frame) - 13.0f, 100.0f, 9.0f);
            _activityIndicatorView.center = _priceLabel.center;
            _purchaseButton.frame = CGRectMake(432.0f, 576.0f, 160.0f, 50.0f);
            CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 30.0f, 658.0f, restoreButtonSize.width, restoreButtonSize.height);
        }
        else {
            _iconImageView.frame = CGRectMake(184.0f, 150.0f, 400.0f, 400.0f);
            _descriptionLabel.frame = CGRectMake(144.0f, 600.0f, 480.0f, 100.0f);
            _priceLabel.frame = CGRectMake(334.0f, 730.0f, 100.0f, 15.0f);
            _inAppPurchaseLabel.frame = CGRectMake(334.0f, CGRectGetMinY(_priceLabel.frame) - 13.0f, 100.0f, 9.0f);
            _activityIndicatorView.center = _priceLabel.center;
            _purchaseButton.frame = CGRectMake(304.0f, 800.0f, 160.0f, 50.0f);
            CGSize restoreButtonSize = [_restoreButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            _restoreButton.frame = CGRectMake(CGRectGetMaxX(rect) - restoreButtonSize.width - 30.0f, 910.0f, restoreButtonSize.width, restoreButtonSize.height);
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

- (void)shareBarButtonAction {
    [PWShareAction showFromViewController:self.tabBarController];
}

#pragma mark UIButton
- (void)purchaseButtonAction {
    if (!_product) {
        return;
    }
    BOOL isPurchased = [PDInAppPurchase isPurchasedWithProduct:_product];
    if (!isPurchased) {
        SKPayment *payment = [SKPayment paymentWithProduct:_product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    
    _purchaseButton.enabled = NO;
    _purchaseButton.alpha = 0.5f;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _purchaseButton.enabled = YES;
        _purchaseButton.alpha = 1.0f;
    });
}

- (void)restoreButtonAction {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    _restoreButton.enabled = NO;
    _restoreButton.alpha = 0.5f;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _restoreButton.enabled = YES;
        _restoreButton.alpha = 1.0f;
    });
}

@end
