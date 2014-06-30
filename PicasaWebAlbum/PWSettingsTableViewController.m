//
//  PWSettingsTableViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSettingsTableViewController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PWPicasaAPI.h"
#import "PLAssetsManager.h"
#import "PDTaskManager.h"
#import "PDInAppPurchase.h"
#import "BlocksKit+UIKit.h"
#import "KKStaticTableView.h"
#import "PWSettingHTMLViewController.h"
#import "PWSelectItemFromArrayViewController.h"

@interface PWSettingsTableViewController ()

@property (strong, nonatomic) KKStaticTableView *tableView;

@property (weak, nonatomic) UIViewController *authViewTouchNavigationController;

@end

@implementation PWSettingsTableViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Settings", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    _tableView = [[KKStaticTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.cellTextFont = [UIFont systemFontOfSize:15.0f];
    _tableView.cellDetailTextFontTypeValue1 = [UIFont systemFontOfSize:15.0f];
    _tableView.cellDetailTextFontTypeSubTitle = [UIFont systemFontOfSize:13.0f];
    _tableView.cellDetailTextColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
    [self.view addSubview:_tableView];
    
    [self setUpWebAlbumSection];
    [self setUpCameraRollSection];
    [self setUpTaskManagerSection];
    [self setUpAboutSection];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect rect = self.view.bounds;
    
    _tableView.frame = rect;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UIBarButtonItem
- (void)doneBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark WebAlbumSection
- (void)setUpWebAlbumSection {
    NSString *sectionTitle = NSLocalizedString(@"Web Album Account", nil);
    [_tableView addSectionWithTitle:sectionTitle];
    
    UIColor *tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [PWOAuthManager getUserData:^(NSString *email, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            UIButton *button = [UIButton new];
            [button addTarget:sself action:@selector(loginoutButtonAction) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [UIFont systemFontOfSize:13.0f];
            if (error) {
                [button setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
            }
            else {
                [button setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
            }
            [button setTitleColor:tintColor forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [button setBackgroundImage:nil forState:UIControlStateNormal];
            [button setBackgroundImage:[PWIcons imageWithColor:tintColor] forState:UIControlStateHighlighted];
            button.clipsToBounds = YES;
            button.layer.cornerRadius = 5.0f;
            button.layer.borderColor = tintColor.CGColor;
            button.layer.borderWidth = 1.0f;
            [button sizeToFit];
            button.frame = CGRectInset(button.frame, -12.0f, 0.0f);
            cell.accessoryView = button;
            
            if (error) {
                cell.textLabel.text = NSLocalizedString(@"Not login", nil);
                cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
            }
            else {
                cell.textLabel.text = email;
            }
        }];
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}

#pragma mark Auto-CreateAlbumSection
- (void)setUpCameraRollSection {
    NSString *sectionTitle = NSLocalizedString(@"Camera Roll", nil);
    NSString *description = NSLocalizedString(@"Photti automatically create albums each day. When that is created, you are pushed a notification.", nil);
    [_tableView addSectionWithTitle:sectionTitle description:description];
    
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
        
    } cellHeight:CGFLOAT_MIN didSelect:nil];
}

#pragma mark TaskManagerSection
- (void)setUpTaskManagerSection {
    NSString *sectionTitle = NSLocalizedString(@"Task Manager", nil);
    NSString *description = NSLocalizedString(@"Photos bigger than 2048x2048 pixels and videos longer than 15minutes use your Google Storage.", nil);
    [_tableView addSectionWithTitle:sectionTitle description:description];
    
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    
    __weak typeof(self) wself = self;
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeValue1 cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        
        if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
            cell.textLabel.alpha = 0.3f;
            cell.detailTextLabel.alpha = 0.3f;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = NSLocalizedString(@"Uploading Size", nil);
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
            cell.detailTextLabel.text = NSLocalizedString(@"Resize", nil);
        }
        else {
            cell.detailTextLabel.text = NSLocalizedString(@"Original", nil);
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } cellHeight:CGFLOAT_MIN didSelect:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) return;
        
        NSUInteger defaultIndex = 0;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kPDTaskManagerIsResizePhotosKey]) {
            defaultIndex = 1;
        }
        NSArray *items = @[NSLocalizedString(@"Resize", nil), NSLocalizedString(@"Original", nil)];
        PWSelectItemFromArrayViewController *viewController = [[PWSelectItemFromArrayViewController alloc] initWithItems:items defaultIndex:defaultIndex];
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
        NSString *version =[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"version %@", version];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } cellHeight:70.0f didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Review on iTunes Store", nil);
        
        UIButton *button = [UIButton new];
        [button addTarget:sself action:@selector(openReviewOniTunesStore) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:13.0f];
        [button setTitle:NSLocalizedString(@"OPEN", nil) forState:UIControlStateNormal];
        [button setTitleColor:tintColor forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setBackgroundImage:[PWIcons imageWithColor:tintColor] forState:UIControlStateHighlighted];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 5.0f;
        button.layer.borderColor = tintColor.CGColor;
        button.layer.borderWidth = 1.0f;
        [button sizeToFit];
        button.frame = CGRectInset(button.frame, -12.0f, 0.0f);
        cell.accessoryView = button;
        
    } cellHeight:CGFLOAT_MIN didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        typeof(wself) sself = wself;
        if (!sself) return;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"Twitter";
        
        UIButton *button = [UIButton new];
        [button addTarget:sself action:@selector(openTwitterButtonAction) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:13.0f];
        [button setTitle:@"@Photti_dev" forState:UIControlStateNormal];
        [button setTitleColor:tintColor forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setBackgroundImage:[PWIcons imageWithColor:tintColor] forState:UIControlStateHighlighted];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 5.0f;
        button.layer.borderColor = tintColor.CGColor;
        button.layer.borderWidth = 1.0f;
        [button sizeToFit];
        button.frame = CGRectInset(button.frame, -12.0f, 0.0f);
        cell.accessoryView = button;
        
    } cellHeight:CGFLOAT_MIN didSelect:nil];
    
    [_tableView addCellAtSection:sectionTitle staticCellType:KKStaticTableViewCellTypeDefault cell:^(UITableViewCell *cell, NSIndexPath *indexPath) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Open Source Licenses", nil);
    } cellHeight:CGFLOAT_MIN didSelect:^{
        typeof(wself) sself = wself;
        if (!sself) return;
        
        PWSettingHTMLViewController *viewController = [[PWSettingHTMLViewController alloc]init];
        viewController.fileName = @"thirdpartycopyright";
        viewController.title = NSLocalizedString(@"Open Source Licences", nil);
        [sself.navigationController pushViewController:viewController animated:true];
    }];
}

#pragma mark Review on iTunes Store
+ (void)jumpToAppReviewPage {
    NSURL *reviewLink = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&mt=8&type=Purple+Software", @"892657316"]];
    [[UIApplication sharedApplication] openURL:reviewLink];
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"Are you sure you want to logout?", nil)];
        [actionSheet bk_setDestructiveButtonWithTitle:NSLocalizedString(@"Logout", nil) handler:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [PWOAuthManager logout];
            [sself.tableView reloadData];
        }];
        [actionSheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:^{}];
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
    [PWSettingsTableViewController jumpToTwitterWithUserID:@"1432277970" userName:@"Photti_dev"];
}

- (void)openReviewOniTunesStore {
    [PWSettingsTableViewController jumpToAppReviewPage];
}

@end
