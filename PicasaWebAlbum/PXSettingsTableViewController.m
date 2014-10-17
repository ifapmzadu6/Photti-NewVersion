//
//  PWSettingsTableViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import StoreKit;

#import "PXSettingsTableViewController.h"

#import <KKStaticTableView.h>
#import "PAColors.h"
#import "PAIcons.h"
#import "PWPicasaAPI.h"
#import "PLAssetsManager.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PAInAppPurchase.h"
#import "PATabBarAdsController.h"
#import "PXSettingHTMLViewController.h"
#import "PXEditItemsViewController.h"
#import "PXSelectItemFromArrayViewController.h"
#import "PEHomeViewController.h"

@interface PXSettingsTableViewController () <SKStoreProductViewControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) KKStaticTableView *tableView;

@property (weak, nonatomic) UIViewController *authViewTouchNavigationController;

@property (strong, nonatomic) SKProduct *product;

@end

@implementation PXSettingsTableViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Settings", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
    
    _tableView = [[KKStaticTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.cellTextFont = [UIFont systemFontOfSize:15.0f];
    _tableView.cellTextColor = [PAColors getColor:PAColorsTypeTextColor];
    _tableView.cellDetailTextFontTypeValue1 = [UIFont systemFontOfSize:15.0f];
    _tableView.cellDetailTextFontTypeSubTitle = [UIFont systemFontOfSize:13.0f];
    _tableView.cellDetailTextColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
    _tableView.exclusiveTouch = YES;
    [self.view addSubview:_tableView];
    
    // TableView
    [self setUpWebAlbumSection];
//    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        [self setUpCameraRollEditDisplayItemSection];
//    }
//    else {
//        [self setUpCameraRollAutoCreateSection];
//    }
    [self setUpTaskManagerSection];
    [self setUpInAppPurchaseSection];
    [self setUpAboutSection];
    
    [self setInAppPurchaseBlocks];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark WebAlbumSection
- (void)setUpWebAlbumSection {
    NSString *sectionTitle = NSLocalizedString(@"Web Album Account", nil);
    [_tableView addSectionWithTitle:sectionTitle];
    
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [PWOAuthManager getUserData:^(NSString *email, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (error) {
                cell.textLabel.text = NSLocalizedString(@"Not login", nil);
                cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
                cell.accessoryView = [sself roundedButtonWithTitle:NSLocalizedString(@"Login", nil) tintColor:tintColor action:@selector(loginoutButtonAction)];
            }
            else {
                cell.textLabel.text = email;
                cell.accessoryView = [sself roundedButtonWithTitle:NSLocalizedString(@"Logout", nil) tintColor:tintColor action:@selector(loginoutButtonAction)];
            }
        }];
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}

#pragma mark Auto-CreateAlbumSection
- (void)setUpCameraRollEditDisplayItemSection {
    NSString *sectionTitle = NSLocalizedString(@"Camera Roll", nil);
    [_tableView addSectionWithTitle:sectionTitle description:nil];
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.textLabel.text = NSLocalizedString(@"Category", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } cellHeight:CGFLOAT_MIN didSelect:^(KKStaticTableView *tableView, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSArray *enabledItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kPEHomeViewControllerUserDefaultsEnabledItemKey];
        NSMutableArray *localizedStringOfEnabledItems = @[].mutableCopy;
        for (NSString *rowType in enabledItems) {
            NSString *localizedString = [PEHomeViewController localizedStringFromRowType:rowType];
            [localizedStringOfEnabledItems addObject:localizedString];
        }
        NSArray *disabledItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kPEHomeViewControllerUserDefaultsDisabledItemKey];
        NSMutableArray *localizedStringOfDisabledItems = @[].mutableCopy;
        for (NSString *rowType in disabledItems) {
            NSString *localizedString = [PEHomeViewController localizedStringFromRowType:rowType];
            [localizedStringOfDisabledItems addObject:localizedString];
        }
        PXEditItemsViewController *viewController = [[PXEditItemsViewController alloc] initWithEnabledItems:localizedStringOfEnabledItems disabledItems:localizedStringOfDisabledItems];
        viewController.title = NSLocalizedString(@"Category", nil);
        viewController.enabledItemsTitle = NSLocalizedString(@"Display", nil);
        viewController.disabledItemsTitle = NSLocalizedString(@"Not Display", nil);
        viewController.completionBlock = ^(NSArray *enabledItems, NSArray *disabledItems){
            NSMutableArray *enabledRowTypes = @[].mutableCopy;
            for (NSString *localizedString in enabledItems) {
                NSString *rowType = [PEHomeViewController rowTypeFromLocalizedString:localizedString];
                [enabledRowTypes addObject:rowType];
            }
            NSMutableArray *disabledRowTypes = @[].mutableCopy;
            for (NSString *localizedString in disabledItems) {
                NSString *rowType = [PEHomeViewController rowTypeFromLocalizedString:localizedString];
                [disabledRowTypes addObject:rowType];
            }
            [[NSUserDefaults standardUserDefaults] setObject:enabledRowTypes.copy forKey:kPEHomeViewControllerUserDefaultsEnabledItemKey];
            [[NSUserDefaults standardUserDefaults] setObject:disabledRowTypes.copy forKey:kPEHomeViewControllerUserDefaultsDisabledItemKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        };
        [sself.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void)setUpCameraRollAutoCreateSection {
    NSString *sectionTitle = NSLocalizedString(@"Camera Roll", nil);
    [_tableView addSectionWithTitle:sectionTitle description:nil];
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.textLabel.text = NSLocalizedString(@"Auto-Create Album", nil);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *switchControl = [UISwitch new];
        [switchControl addTarget:sself action:@selector(switchControlAction:) forControlEvents:UIControlEventValueChanged];
        switchControl.on = ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable);
        cell.accessoryView = switchControl;
        
        if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            switchControl.enabled = NO;
            cell.textLabel.alpha = 0.3f;
        }
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}

#pragma mark TaskManagerSection
- (void)setUpTaskManagerSection {
    NSString *sectionTitle = NSLocalizedString(@"Tasks", nil);
    [_tableView addSectionWithTitle:sectionTitle description:nil];
    
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeValue1 cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        
        cell.textLabel.text = NSLocalizedString(@"Uploading Size", nil);
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
            cell.detailTextLabel.text = NSLocalizedString(@"Resize", nil);
        }
        else {
            cell.detailTextLabel.text = NSLocalizedString(@"Original", nil);
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } cellHeight:CGFLOAT_MIN didSelect:^(KKStaticTableView *tableView, NSIndexPath* indexPath){
        typeof(wself) sself = wself;
        if (!sself) return;
        
        NSUInteger defaultIndex = 0;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
            defaultIndex = 1;
        }
        NSArray *items = @[NSLocalizedString(@"Resize", nil), NSLocalizedString(@"Original", nil)];
        PXSelectItemFromArrayViewController *viewController = [[PXSelectItemFromArrayViewController alloc] initWithItems:items defaultIndex:defaultIndex];
        viewController.title = NSLocalizedString(@"Uploading Size", nil);
        viewController.view.tintColor = tintColor;
        viewController.doneBlock = ^(NSString *selectedItem){
            typeof(wself) sself = wself;
            if (!sself) return;
            if ([selectedItem isEqualToString:NSLocalizedString(@"Resize", nil)]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPDTaskManagerIsResizePhotosKey];
            }
            else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPDTaskManagerIsResizePhotosKey];
            }
            [sself.tableView reloadSectionWithTitle:sectionTitle];
        };
        viewController.footerString = NSLocalizedString(@"Photos bigger than 2048x2048 pixels and videos longer than 15minutes use your Google Storage.", nil);
        [sself.navigationController pushViewController:viewController animated:YES];
    }];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeValue1 cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Delete all tasks", nil);
        cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextDarkColor];
        cell.detailTextLabel.text = nil;
        UIButton *button = [sself roundedButtonWithTitle:NSLocalizedString(@"Delete", nil) tintColor:tintColor action:@selector(deleteAllTasksButtonAction)];
        button.layer.borderWidth = 0.0f;
        [button setTitleColor:tintColor forState:UIControlStateNormal];
        [button setBackgroundImage:[PAIcons imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        cell.accessoryView = button;
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}

#pragma mark In-AppPurchaseSection
- (void)setUpInAppPurchaseSection {
    NSString *sectionTitle = NSLocalizedString(@"In-App Purchase", nil);
    [_tableView addSectionWithTitle:sectionTitle];
    
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeSubTitle cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Remove Ads", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Loading...", nil);
        UIButton *button = [sself roundedButtonWithTitle:NSLocalizedString(@"Purchace", nil) tintColor:tintColor action:@selector(purchaseButtonAction:)];
        button.enabled = NO;
        button.alpha = 0.5f;
        cell.accessoryView = button;
        
        [PAInAppPurchase getProductsWithProductIDs:@[kPDRemoveAdsPuroductID] completion:^(NSArray *products, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (error) {
#ifdef DEBUG
                NSLog(@"%@", error);
#endif
                return;
            }
            
            NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            for (SKProduct *product in products) {
                if ([product.productIdentifier isEqualToString:kPDRemoveAdsPuroductID]) {
                    sself.product = product;
                    [numberFormatter setLocale:product.priceLocale];
                    NSString *price = [numberFormatter stringFromNumber:product.price];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.detailTextLabel.text = price;
                        if (![PAInAppPurchase isPurchasedWithProduct:product]) {
                            button.enabled = YES;
                            button.alpha = 1.0f;
                        }
                        else {
                            UILabel *label = [UILabel new];
                            label.font = [UIFont systemFontOfSize:13.0f];
                            label.text = [NSLocalizedString(@"Purchased", nil) stringByAppendingString:@"   "];
                            label.textColor = [PAColors getColor:PAColorsTypeTextDarkColor];
                            [label sizeToFit];
                            cell.accessoryView = label;
                        }
                    });
                    break;
                }
            }
        }];
        
    } cellHeight:60.0f didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeValue1 cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Restore In-App Purchase", nil);
        cell.textLabel.textColor = [PAColors getColor:PAColorsTypeTextDarkColor];
        UIButton *button = [sself roundedButtonWithTitle:NSLocalizedString(@"Restore", nil) tintColor:tintColor action:@selector(restoreButtonAction:)];
        button.layer.borderWidth = 0.0f;
        [button setTitleColor:tintColor forState:UIControlStateNormal];
        [button setBackgroundImage:[PAIcons imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        cell.accessoryView = button;
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}


#pragma mark AboutSection
- (void)setUpAboutSection {
    NSString *sectionTitle = NSLocalizedString(@"About", nil);
    NSString *description = @"Copyright © 2014 Keisuke Karijuku.\nAll Rights Reserved.";
    [_tableView addSectionWithTitle:sectionTitle description:description];
    
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeSubTitle cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        cell.imageView.image = [UIImage imageNamed:@"Icon_60"];
        cell.textLabel.text = @"Photti";
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"version %@", version];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } cellHeight:70.0f didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Review on iTunes Store", nil);
        cell.accessoryView = [sself roundedButtonWithTitle:NSLocalizedString(@"OPEN", nil) tintColor:tintColor action:@selector(openReviewOniTunesStore)];
        
    } cellHeight:CGFLOAT_MIN didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"Twitter";
        cell.accessoryView = [sself roundedButtonWithTitle:@"@Photti_dev" tintColor:tintColor action:@selector(openTwitterButtonAction)];
        
    } cellHeight:CGFLOAT_MIN didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Open Source License", nil);
    } cellHeight:CGFLOAT_MIN didSelect:^(KKStaticTableView *tableView, NSIndexPath* indexPath){
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PXSettingHTMLViewController *viewController = [[PXSettingHTMLViewController alloc]init];
        viewController.fileName = @"thirdpartycopyright";
        viewController.title = NSLocalizedString(@"Open Source License", nil);
        [sself.navigationController pushViewController:viewController animated:true];
    }];
}

#pragma mark Open iTunes Store
- (void)openItunesStoreWithAppID:(NSNumber *)appId {
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    [storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
    storeViewController.delegate = self;
    [self.navigationController presentViewController:storeViewController animated:YES completion:nil];
}

#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Twitter
+ (void)jumpToTwitterWithUserID:(NSString *)userID userName:(NSString *)userName {
    NSString *stringURL = [NSString stringWithFormat:@"twitter://user?id=%@", userID];
    NSString *stringURLSafari = [NSString stringWithFormat:@"https://twitter.com/%@", userName];
    bool success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
    if (!success) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURLSafari]];
    }
}

#pragma mark UIButtonAction
- (void)loginoutButtonAction {
    __weak typeof(self) wself = self;
    if ([PWOAuthManager isLogined]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to logout?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Logout", nil) otherButtonTitles:nil];
        actionSheet.tag = 1001;
        [actionSheet showInView:self.view];
    }
    else {
        [PWOAuthManager loginViewControllerWithCompletion:^(UINavigationController *navigationController) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:sself action:@selector(cancelBarButtonAction)];
                navigationController.visibleViewController.navigationItem.leftBarButtonItem  = cancelBarButtonItem;
                
                sself.authViewTouchNavigationController = navigationController;
                [sself presentViewController:navigationController animated:YES completion:nil];
            });
        } finish:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself.tableView reloadData];
            });
        }];
    }
}

- (void)cancelBarButtonAction {
    UIViewController *viewController = _authViewTouchNavigationController;
    if (!viewController) return;
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchControlAction:(UISwitch *)switchControl {
    if (switchControl.on) {
        [PLAssetsManager sharedManager].autoCreateAlbumType = PLAssetsManagerAutoCreateAlbumTypeEnable;
    }
    else {
        [PLAssetsManager sharedManager].autoCreateAlbumType = PLAssetsManagerAutoCreateAlbumTypeDisable;
    }
}

- (void)openTwitterButtonAction {
    [PXSettingsTableViewController jumpToTwitterWithUserID:@"1432277970" userName:@"Photti_dev"];
}

- (void)openReviewOniTunesStore {
    [self openItunesStoreWithAppID:@(APPID.integerValue)];
}

- (void)deleteAllTasksButtonAction {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete all tasks?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    actionSheet.tag = 1002;
    [actionSheet showInView:self.view];
}

- (void)purchaseButtonAction:(UIButton *)button {
    if (![SKPaymentQueue canMakePayments]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"In-App Purchase is restricted", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil) , nil] show];
    }
    else {
        if (!_product) {
            return;
        }
        BOOL isPurchased = [PAInAppPurchase isPurchasedWithProduct:_product];
        if (!isPurchased) {
            SKPayment *payment = [SKPayment paymentWithProduct:_product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            
            button.enabled = NO;
            button.alpha = 0.5f;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                button.enabled = YES;
                button.alpha = 1.0f;
            });
        }
    }
}

- (void)restoreButtonAction:(UIButton *)button {
    if (![SKPaymentQueue canMakePayments]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"In-App Purchase is restricted", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil) , nil] show];
    }
    else {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
        button.enabled = NO;
        button.alpha = 0.5f;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            button.enabled = YES;
            button.alpha = 1.0f;
        });
    }
}

#pragma mark UIButton
- (UIButton *)roundedButtonWithTitle:(NSString *)title tintColor:(UIColor *)tintColor action:(SEL)action {
    UIButton *button = [UIButton new];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:tintColor forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[PAIcons imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[PAIcons imageWithColor:tintColor] forState:UIControlStateNormal];
    button.clipsToBounds = YES;
    button.layer.cornerRadius = 5.0f;
    button.layer.borderColor = tintColor.CGColor;
    button.layer.borderWidth = 1.0f;
    CGSize buttonSize = [button sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    button.frame = CGRectMake(0.0f, 0.0f, buttonSize.width + 24.0f, 28.0f);
    return button;
}

- (void)setInAppPurchaseBlocks {
    PAInAppPurchase *inAppPurchase = [PAInAppPurchase sharedInstance];
    __weak typeof(self) wself = self;
    [inAppPurchase setPaymentQueuePurchaced:^(NSArray *transactions, bool success) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!success) {
            return;
        }
        
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        tabBarController.isRemoveAdsAddonPurchased = [PAInAppPurchase isPurchasedWithKey:kPDRemoveAdsPuroductID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself.tableView reloadData];
        });
    }];
    [inAppPurchase setPaymentQueueRestored:^(NSArray *transactions, bool success) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (!success) {
            return;
        }
        
        PATabBarAdsController *tabBarController = (PATabBarAdsController *)sself.tabBarController;
        tabBarController.isRemoveAdsAddonPurchased = [PAInAppPurchase isPurchasedWithKey:kPDRemoveAdsPuroductID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself.tableView reloadData];
        });
    }];
}

#pragma mark OtherAppAction
- (void)openVideoCastiTunesStore {
    [self openItunesStoreWithAppID:@(SMARTVIDEOCASTAPPID.longLongValue)];
}

- (void)openPixittiiTunesStore {
    [self openItunesStoreWithAppID:@(PIXITTIAPPID.longLongValue)];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == 1001) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Logout", nil)]) {
            [PWOAuthManager logout];
            [_tableView reloadData];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
    else if (actionSheet.tag == 1002) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]) {
            [PDCoreDataAPI writeWithBlock:^(NSManagedObjectContext *context) {
                NSFetchRequest *request = [NSFetchRequest new];
                request.entity = [NSEntityDescription entityForName:@"PDTaskObject" inManagedObjectContext:context];
                NSError *error = nil;
                NSArray *tasks = [context executeFetchRequest:request error:&error];
                for (PDTaskObject *task in tasks) {
                    [context deleteObject:task];
                }
            }];
        }
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        }
    }
}

@end
