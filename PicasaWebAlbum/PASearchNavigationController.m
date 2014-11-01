//
//  PWSearchNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PASearchNavigationController.h"

@import Photos;

#import "PAColors.h"
#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "PWSearchTableViewWebAlbumCell.h"
#import "PWSearchTableViewLocalAlbumCell.h"
#import "PAViewControllerKit.h"
#import "PAPhotoKit.h"

#import "UIView+ScreenCapture.h"
#import "UIImage+ImageEffects.h"

#import "PWPhotoListViewController.h"
#import "PLPhotoListViewController.h"
#import "PEPhotoListViewController.h"


typedef NS_OPTIONS(NSUInteger, PWSearchNavigationControllerItemType) {
    PWSearchNavigationControllerItemTypeHistory = (1 << 0),
    PWSearchNavigationControllerItemTypeLocalAlbum = (1 << 1),
    PWSearchNavigationControllerItemTypeWebAlbum = (1 << 2),
    PWSearchNavigationControllerItemTypeLocalPhoto = (1 << 3),
    PWSearchNavigationControllerItemTypeWebPhoto = (1 << 4)
};

@interface PWSearchNavigationControllerItem : NSObject

@property (nonatomic) PWSearchNavigationControllerItemType type;
@property (strong, nonatomic) NSArray *item;
@property (strong, nonatomic) NSDate *updateUsingByHistorySort;

@end

@implementation PWSearchNavigationControllerItem

@end


@interface PWSearchNavigationControllerHistoryItem : NSObject <NSCoding>

@property (nonatomic) PWSearchNavigationControllerItemType type;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSDate *update;

@end

@implementation PWSearchNavigationControllerHistoryItem

static NSString * const PWSearchNavigationControllerHistoryItemTypeKey = @"PWSNCHITK1";
static NSString * const PWSearchNavigationControllerHistoryItemIdentifierKey = @"PWSNCHIIK2";
static NSString * const PWSearchNavigationControllerHistoryItemUpdateKey = @"PWSNCHIUK3";

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _type = (PWSearchNavigationControllerItemType)[aDecoder decodeIntegerForKey:PWSearchNavigationControllerHistoryItemTypeKey];
        _identifier = [aDecoder decodeObjectForKey:PWSearchNavigationControllerHistoryItemIdentifierKey];
        _update = [aDecoder decodeObjectForKey:PWSearchNavigationControllerHistoryItemUpdateKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_type forKey:PWSearchNavigationControllerHistoryItemTypeKey];
    [aCoder encodeObject:_identifier forKey:PWSearchNavigationControllerHistoryItemIdentifierKey];
    [aCoder encodeObject:_update forKey:PWSearchNavigationControllerHistoryItemUpdateKey];
}

@end


@interface PASearchNavigationController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIView *searchBarBackgroundView;
@property (strong, nonatomic) UIImageView *backbroundView;
@property (strong, nonatomic) UITableView *tableView;

@property (nonatomic) BOOL isSearchBarOpen;
@property (nonatomic) BOOL isAnimation;
@property (nonatomic) BOOL isShowHistory;
@property (nonatomic) NSUInteger searchedTextHash;
@property (copy, nonatomic) void (^cancelBlock)();
@property (strong, nonatomic) UIScrollView *beforeSctollToTopScrollView;

@property (strong, nonatomic) NSMutableArray *items;

@end

@implementation PASearchNavigationController

static NSString * const PWSearchNavigationControllerHistoryKey = @"PWNCH";
static NSString * const PWSearchNavigationControllerWebAlbumCell = @"PWSNCWAC1";
static NSString * const PWSearchNavigationControllerLocalAlbumCell = @"PWSNCLAC2";
static NSString * const PWSearchNavigationControllerWebPhotoCell = @"PWSNCWPC3";
static NSString * const PWSearchNavigationControllerLocalPhotoCell = @"PWSNCLPC4";

- (id)init {
    self = [super init];
    if (self) {
        _items = @[].mutableCopy;
        
        NSManagedObjectContext *pwContext = [PWCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:pwContext];
        
        NSManagedObjectContext *plContext = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:plContext];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _items = @[].mutableCopy;
        
        NSManagedObjectContext *pwContext = [PWCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:pwContext];
        
        NSManagedObjectContext *plContext = [PLCoreDataAPI readContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification) name:NSManagedObjectContextDidSaveNotification object:plContext];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _searchBarBackgroundView = [UIView new];
    _searchBarBackgroundView.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    _searchBarBackgroundView.alpha = 0.0f;
    _searchBarBackgroundView.exclusiveTouch = YES;
    [self.view addSubview:_searchBarBackgroundView];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = NO;
    _searchBar.placeholder = NSLocalizedString(@"Search", nil);
    _searchBar.exclusiveTouch = YES;
    [_searchBarBackgroundView addSubview:_searchBar];
    
    _cancelButton = [UIButton new];
    [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[PAColors getColor:kPAColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[[PAColors getColor:kPAColorsTypeTintUploadColor] colorWithAlphaComponent:0.2f]  forState:UIControlStateHighlighted];
    _cancelButton.exclusiveTouch = YES;
    [_searchBarBackgroundView addSubview:_cancelButton];
    
    _backbroundView = [UIImageView new];
    _backbroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    _backbroundView.alpha = 0.0;
    _backbroundView.userInteractionEnabled = YES;
    _backbroundView.exclusiveTouch = YES;
    [self.view addSubview:_backbroundView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.scrollsToTop = NO;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    [_tableView registerClass:[PWSearchTableViewWebAlbumCell class] forCellReuseIdentifier:PWSearchNavigationControllerWebAlbumCell];
    [_tableView registerClass:[PWSearchTableViewLocalAlbumCell class] forCellReuseIdentifier:PWSearchNavigationControllerLocalAlbumCell];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.exclusiveTouch = YES;
    [_backbroundView addSubview:_tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGSize navigationBarSize = self.navigationBar.bounds.size;
    CGFloat statusBarHeight = [PAViewControllerKit statusBarHeight];
    _searchBarBackgroundView.frame = CGRectMake(0.0f, 0.0f, navigationBarSize.width, navigationBarSize.height + statusBarHeight);
    CGSize cancelButtonSize = [_cancelButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _searchBar.frame = CGRectMake(0.0f, statusBarHeight, navigationBarSize.width - (cancelButtonSize.width + 10.0f), navigationBarSize.height);
    _cancelButton.frame = CGRectMake(navigationBarSize.width - (cancelButtonSize.width + 10.0f), statusBarHeight, cancelButtonSize.width, navigationBarSize.height);
    
    _backbroundView.frame = self.view.bounds;
    _tableView.frame = self.view.bounds;
    
    _tableView.contentInset = UIEdgeInsetsMake(navigationBarSize.height + statusBarHeight, 0.0f, _tableView.contentInset.bottom, 0.0f);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
}

#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText || [searchText isEqualToString:@""]) {
        _isShowHistory = YES;
        _items = @[].mutableCopy;
        [_tableView reloadData];
        
        NSArray *historyItems = [self getHistory];
        [self reloadTableViewWithHistoryItems:historyItems];
    }
    else {
        if (_isShowHistory) {
            _items = @[].mutableCopy;
            [_tableView reloadData];
            _isShowHistory = NO;
        }
        
        [self reloadTableViewWithSearchText:searchText];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark UIButtonAction
- (void)cancelButtonAction {
    [self closeSearchBarWithCompletion:nil];
}

#pragma mark OpenSearchBar
- (void)openSearchBarWithCancelBlock:(void (^)())cancelBlock {
    if (_isSearchBarOpen || _isAnimation) return;
    _isSearchBarOpen = YES;
    _isAnimation = YES;
    
    _cancelBlock = cancelBlock;
    
    _beforeSctollToTopScrollView = [self getScrollToTopScrollView:self.view.subviews];
    _beforeSctollToTopScrollView.scrollsToTop = NO;
    _tableView.scrollsToTop = YES;
    
    UIImage *backgroundImage = [self.view screenCapture];
    UIColor *tintColor = [UIColor colorWithWhite:0.5f alpha:0.3f];
    _backbroundView.image = [backgroundImage applyBlurWithRadius:25 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
    
    [self.view bringSubviewToFront:_backbroundView];
    [self.view bringSubviewToFront:_tableView];
    [self.view bringSubviewToFront:_searchBarBackgroundView];
    [_searchBar becomeFirstResponder];
    _searchBar.tintColor = self.view.tintColor;
    if (!_searchBar.text || [_searchBar.text isEqualToString:@""]) {
        _isShowHistory = YES;
        _items = @[].mutableCopy;
        [_tableView reloadData];
        
        NSArray *historyItems = [self getHistory];
        [self reloadTableViewWithHistoryItems:historyItems];
    }
    
    [_cancelButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[self.view.tintColor colorWithAlphaComponent:0.2f]  forState:UIControlStateHighlighted];
    
    [UIView animateWithDuration:0.25f animations:^{
        _backbroundView.alpha = 1.0f;
        _searchBarBackgroundView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        _isAnimation = NO;
    }];
}

- (void)closeSearchBarWithCompletion:(void (^)())completion {
    if (!_isSearchBarOpen || _isAnimation) return;
    _isSearchBarOpen = NO;
    _isAnimation = YES;
    
    if (_cancelBlock) {
        _cancelBlock();
        _cancelBlock = nil;
    }
    
    _beforeSctollToTopScrollView.scrollsToTop = YES;
    _beforeSctollToTopScrollView = nil;
    _tableView.scrollsToTop = NO;
    
    [_searchBar resignFirstResponder];
    
    [UIView animateWithDuration:0.25f animations:^{
        _backbroundView.alpha = 0.0f;
        _searchBarBackgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        _isAnimation = NO;
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_isShowHistory) {
        return 1;
    }
    return _items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isShowHistory) {
        return _items.count;
    }
    PWSearchNavigationControllerItem *sectionItem = _items[section];
    return sectionItem.item.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (_isShowHistory) {
        PWSearchNavigationControllerItem *rowItem = _items[indexPath.row];
        if (rowItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWSearchTableViewWebAlbumCell *webAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerWebAlbumCell forIndexPath:indexPath];
            webAlbumCell.isShowAlbumType = YES;
            
            [webAlbumCell setAlbum:rowItem.item.firstObject searchedText:nil];
            
            cell = webAlbumCell;
        }
        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PWSearchTableViewLocalAlbumCell *localAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerLocalAlbumCell forIndexPath:indexPath];
            localAlbumCell.isShowAlbumType = YES;
            
            if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                [localAlbumCell setAssetCollection:rowItem.item.firstObject searchedText:nil];
            }
            else {
                [localAlbumCell setAlbum:rowItem.item.firstObject searchedText:nil];
            }
            
            cell = localAlbumCell;
        }
    }
    else {
        PWSearchNavigationControllerItem *sectionItem = _items[indexPath.section];
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWSearchTableViewWebAlbumCell *webAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerWebAlbumCell forIndexPath:indexPath];
            webAlbumCell.isShowAlbumType = NO;
            
            PWAlbumObject *album = sectionItem.item[indexPath.row];
            [webAlbumCell setAlbum:album searchedText:_searchBar.text];
            
            cell = webAlbumCell;
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PWSearchTableViewLocalAlbumCell *localAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerLocalAlbumCell forIndexPath:indexPath];
            localAlbumCell.isShowAlbumType = NO;
            
            if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                PHAssetCollection *assetCollection = sectionItem.item[indexPath.row];
                [localAlbumCell setAssetCollection:assetCollection searchedText:_searchBar.text];
            }
            else {
                PLAlbumObject *album = sectionItem.item[indexPath.row];
                [localAlbumCell setAlbum:album searchedText:_searchBar.text];
            }
            
            cell = localAlbumCell;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_isShowHistory) {
        if (_items.count > 0) {
            return NSLocalizedString(@"History", nil);
        }
    }
    else {
        PWSearchNavigationControllerItem *sectionItem = _items[section];
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            return NSLocalizedString(@"Web Album", nil);
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            return NSLocalizedString(@"Camera Roll", nil);
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
            return NSLocalizedString(@"Camera Roll", nil);
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[PAColors getColor:kPAColorsTypeBackgroundColor]];
}

#pragma mark TableViewMethods
- (void)reloadDataWithItems:(NSArray *)items hash:(NSUInteger)hash {
    if (!items) return;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        sself.items = items.mutableCopy;
        [sself.tableView reloadData];
        sself.tableView.contentOffset = CGPointMake(0.0f, -sself.tableView.contentInset.top);
    });
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    __weak typeof(self) wself = self;
    if (!_isShowHistory) {
        PWSearchNavigationControllerItem *sectionItem = _items[indexPath.section];
        [self addHistory:sectionItem index:indexPath.row];
        
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWAlbumObject *album = sectionItem.item[indexPath.row];
            
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                PHAssetCollection *assetCollection = sectionItem.item[indexPath.row];
                kPHPhotoListViewControllerType type = kPHPhotoListViewControllerType_Album;
                if (assetCollection.assetCollectionType == PHAssetCollectionTypeMoment) {
                    type = kPHPhotoListViewControllerType_Moment;
                }
                [self closeSearchBarWithCompletion:^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:type];
                    [sself pushViewController:viewController animated:YES];
                }];
            }
            else {
                PLAlbumObject *album = sectionItem.item[indexPath.row];
                [self closeSearchBarWithCompletion:^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:album];
                    [sself pushViewController:viewController animated:YES];
                }];
            }
            
        }
    }
    else {
        PWSearchNavigationControllerItem *rowItem = _items[indexPath.row];
        NSArray *historyItems = [self getHistory];
        historyItems = [historyItems sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"update" ascending:NO]]];
        PWSearchNavigationControllerHistoryItem *historyItem = historyItems[indexPath.row];
        historyItem.update = [NSDate date];
        [self saveHistoryItems:historyItems];
        
        if (rowItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWAlbumObject *album = rowItem.item.firstObject;
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
                    PHAssetCollection *assetCollection = rowItem.item.firstObject;
                    PEPhotoListViewController *viewController = [[PEPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Album];
                    [sself pushViewController:viewController animated:YES];
                }
                else {
                    PLAlbumObject *album = rowItem.item.firstObject;
                    PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:album];
                    [sself pushViewController:viewController animated:YES];
                }
            }];
        }
    }
}

#pragma mark NSManagedObjectContextDidSaveNotification
- (void)contextDidSaveNotification {
    if (_isSearchBarOpen) {
        if (_isShowHistory) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *historyItems = [self getHistory];
                [self reloadTableViewWithHistoryItems:historyItems];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadTableViewWithSearchText:_searchBar.text];
            });
        }
    }
}

#pragma mark History
- (NSArray *)getHistory {
    NSData *historyItemData = [[NSUserDefaults standardUserDefaults] objectForKey:PWSearchNavigationControllerHistoryKey];
    NSArray *historyItems = nil;
    if (historyItemData) {
        historyItems = [NSKeyedUnarchiver unarchiveObjectWithData:historyItemData];
    }
    else {
        historyItems = @[];
    }
    
    return historyItems;
}

- (void)addHistory:(PWSearchNavigationControllerItem *)item index:(NSUInteger)index {
    NSMutableArray *mutableHistoryItems = [self getHistory].mutableCopy;
    
    PWSearchNavigationControllerHistoryItem *historyItem = [[PWSearchNavigationControllerHistoryItem alloc] init];
    historyItem.type = item.type;
    historyItem.update = [NSDate date];
    NSString *identifier = nil;
    if (item.type == PWSearchNavigationControllerItemTypeWebAlbum) {
        PWAlbumObject *album = item.item[index];
        identifier = album.id_str;
    }
    else if (item.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
        if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
            PHAssetCollection *assetCollection = item.item[index];
            identifier = assetCollection.localIdentifier;
        }
        else {
            PLAlbumObject *album = item.item[index];
            identifier = album.id_str;
        }
    }
    historyItem.identifier = identifier;
    
    NSArray *filteredHistoryItems = [mutableHistoryItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]];
    if (filteredHistoryItems.count > 0) {
        [mutableHistoryItems removeObject:filteredHistoryItems.firstObject];
    }
    [mutableHistoryItems insertObject:historyItem atIndex:0];
    if (mutableHistoryItems.count > 10) {
        [mutableHistoryItems removeObject:mutableHistoryItems.lastObject];
    }
    
    [self saveHistoryItems:mutableHistoryItems.copy];
}

- (void)saveHistoryItems:(NSArray *)historyItems {
    NSData *historyItemData = [NSKeyedArchiver archivedDataWithRootObject:historyItems];
    [[NSUserDefaults standardUserDefaults] setObject:historyItemData forKey:PWSearchNavigationControllerHistoryKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeHistory:(PWSearchNavigationControllerHistoryItem *)item {
    NSMutableArray *historyItems = [self getHistory].mutableCopy;
    
    if ([historyItems containsObject:item]) {
        [historyItems removeObject:item];
    }
    
    [self saveHistoryItems:historyItems];
}

#pragma mark Reload Search
- (void)reloadTableViewWithSearchText:(NSString *)searchText {
    NSUInteger hash = searchText.hash;
    _searchedTextHash = hash;
    __block NSMutableArray *items = @[].mutableCopy;
    __weak typeof(self) wself = self;
    [self webAlbumsSearchByName:searchText completion:^(NSArray *albums, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        if (albums.count > 0) {
            PWSearchNavigationControllerItem *item = [PWSearchNavigationControllerItem new];
            item.type = PWSearchNavigationControllerItemTypeWebAlbum;
            item.item = albums;
            [items addObject:item];
        }
        [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"update" ascending:YES]]];
        
        [sself reloadDataWithItems:items hash:hash];
        
        [sself localAlbumsSearchByName:searchText completion:^(NSArray *albums, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.searchedTextHash != hash) return;
            if (error) return;
            
            if (albums.count > 0) {
                PWSearchNavigationControllerItem *item = [PWSearchNavigationControllerItem new];
                item.type = PWSearchNavigationControllerItemTypeLocalAlbum;
                item.item = albums;
                [items addObject:item];
            }
            
            [sself reloadDataWithItems:items hash:hash];
        }];
    }];
}

#pragma mark Reload History
- (void)reloadTableViewWithHistoryItems:(NSArray *)historyItems {
    NSUInteger hash = historyItems.hash;
    _searchedTextHash = hash;
    
    __block NSMutableArray *items = @[].mutableCopy;
    __weak typeof(self) wself = self;
    NSArray *webAlbumHistoryItems = [historyItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(PWSearchNavigationControllerItemTypeWebAlbum)]];
    NSArray *localAlbumHistoryItems = [historyItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(PWSearchNavigationControllerItemTypeLocalAlbum)]];
    __block NSUInteger numberOfWebAlbums = webAlbumHistoryItems.count;
    __block NSUInteger numberOfLocalAlbums = localAlbumHistoryItems.count;
    
    void (^localHistorySearchBlock)(PWSearchNavigationControllerHistoryItem *) = ^(PWSearchNavigationControllerHistoryItem *historyItem) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
            PHAssetCollection *assetCollection = [PAPhotoKit getAssetCollectionWithIdentifier:historyItem.identifier];
            if (assetCollection) {
                PWSearchNavigationControllerItem *item = [PWSearchNavigationControllerItem new];
                item.type = PWSearchNavigationControllerItemTypeLocalAlbum;
                item.item = @[assetCollection];
                item.updateUsingByHistorySort = historyItem.update;
                [items addObject:item];
            }
            else {
                [sself removeHistory:historyItem];
                numberOfLocalAlbums--;
            }
        }
        else {
            PLAlbumObject *albumObject = [PLAlbumObject getAlbumObjectWithID:historyItem.identifier];
            if (albumObject) {
                PWSearchNavigationControllerItem *item = [PWSearchNavigationControllerItem new];
                item.type = PWSearchNavigationControllerItemTypeLocalAlbum;
                item.item = @[albumObject];
                item.updateUsingByHistorySort = historyItem.update;
                [items addObject:item];
            }
            else {
                [sself removeHistory:historyItem];
                numberOfLocalAlbums--;
            }
        }
        
        if (items.count == numberOfWebAlbums + numberOfLocalAlbums) {
            [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"updateUsingByHistorySort" ascending:NO]]];
            [sself reloadDataWithItems:items hash:hash];
        }
    };
    
    if (webAlbumHistoryItems.count == 0) {
        for (PWSearchNavigationControllerHistoryItem *historyItem in localAlbumHistoryItems) {
            localHistorySearchBlock(historyItem);
        }
    }
    else {
        for (PWSearchNavigationControllerHistoryItem *historyItem in webAlbumHistoryItems) {
            PWAlbumObject *albumObject = [PWAlbumObject getAlbumObjectWithID:historyItem.identifier];
            
            if (albumObject) {
                PWSearchNavigationControllerItem *item = [PWSearchNavigationControllerItem new];
                item.type = PWSearchNavigationControllerItemTypeWebAlbum;
                item.item = @[albumObject];
                item.updateUsingByHistorySort = historyItem.update;
                [items addObject:item];
            }
            else {
                [self removeHistory:historyItem];
                numberOfWebAlbums--;
            }
            
            if (items.count == numberOfWebAlbums) {
                if (numberOfLocalAlbums == 0) {
                    [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"updateUsingByHistorySort" ascending:NO]]];
                    [self reloadDataWithItems:items hash:hash];
                }
                else {
                    for (PWSearchNavigationControllerHistoryItem *historyItem in localAlbumHistoryItems) {
                        localHistorySearchBlock(historyItem);
                    }
                }
            }
        }
    }
}

#pragma mark OtherMethods
- (UIScrollView *)getScrollToTopScrollView:(NSArray *)subViews {
    UIScrollView *scrollView = nil;
    [self getScrollToTopScrollView:subViews scrollView:&scrollView];
    return scrollView;
}

- (void)getScrollToTopScrollView:(NSArray *)subViews scrollView:(UIScrollView **)scrollView {
    if (*scrollView) {
        return;
    }
    
    for (UIView *view in subViews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *tmpScrollView = (UIScrollView *)view;
            if (tmpScrollView.scrollsToTop) {
                *scrollView = tmpScrollView;
                break;
            }
        }
        [self getScrollToTopScrollView:view.subviews scrollView:scrollView];
    }
}

#pragma mark Model
- (void)localAlbumsSearchByName:(NSString *)name completion:(void (^)(NSArray *albums, NSError *error))completion {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        PHFetchOptions *options = [PHFetchOptions new];
        options.predicate = [NSPredicate predicateWithFormat:@"localizedTitle contains[c] %@", name];
        PHFetchResult *albumFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:options];
        NSMutableArray *assetCollections = @[].mutableCopy;
        for (PHAssetCollection *assetCollection in albumFetchResult) {
            [assetCollections addObject:assetCollection];
        }
        if (completion) {
            completion(assetCollections, nil);
        }
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", name];
        [[PLAssetsManager sharedManager] getAlbumWithPredicate:predicate completion:^(NSArray *albums, NSError *error) {
            if (completion) {
                completion(albums, error);
            }
        }];
    }
}

- (void)webAlbumsSearchByName:(NSString *)name completion:(void (^)(NSArray *albums, NSError *error))completion {
    [PWCoreDataAPI readWithBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest new];
        request.entity = [NSEntityDescription entityForName:kPWAlbumObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        request.predicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", name];
        NSError *error = nil;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (completion) {
            completion(albums, error);
        }
    }];
}

@end
