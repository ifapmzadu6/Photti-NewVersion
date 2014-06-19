//
//  PWSearchNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSearchNavigationController.h"

#import "PWColors.h"

#import "PWModelObject.h"
#import "PWCoreDataAPI.h"
#import "PWPicasaAPI.h"
#import "PLModelObject.h"
#import "PLCoreDataAPI.h"
#import "PLAssetsManager.h"
#import "PWSearchTableViewWebAlbumCell.h"
#import "PWSearchTableViewLocalAlbumCell.h"

#import "UIView+ScreenCapture.h"
#import "UIImage+ImageEffects.h"

#import "PWPhotoListViewController.h"
#import "PLPhotoListViewController.h"



typedef enum _PWSearchNavigationControllerItemType {
    PWSearchNavigationControllerItemTypeHistory = (1 << 0),
    PWSearchNavigationControllerItemTypeLocalAlbum = (1 << 1),
    PWSearchNavigationControllerItemTypeWebAlbum = (1 << 2),
    PWSearchNavigationControllerItemTypeLocalPhoto = (1 << 3),
    PWSearchNavigationControllerItemTypeWebPhoto = (1 << 4)
} PWSearchNavigationControllerItemType;

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


@interface PWSearchNavigationController ()

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

@property (strong, nonatomic) NSArray *items;

@end

@implementation PWSearchNavigationController

static NSString * const PWSearchNavigationControllerHistoryKey = @"PWNCH";
static NSString * const PWSearchNavigationControllerWebAlbumCell = @"PWSNCWAC1";
static NSString * const PWSearchNavigationControllerLocalAlbumCell = @"PWSNCLAC2";
static NSString * const PWSearchNavigationControllerWebPhotoCell = @"PWSNCWPC3";
static NSString * const PWSearchNavigationControllerLocalPhotoCell = @"PWSNCLPC4";

- (id)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _items = @[].mutableCopy;
    
    _searchBarBackgroundView = [[UIView alloc] init];
    _searchBarBackgroundView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _searchBarBackgroundView.alpha = 0.0f;
    [self.view addSubview:_searchBarBackgroundView];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = NO;
    _searchBar.placeholder = NSLocalizedString(@"Search", nil);
    _searchBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    [_searchBarBackgroundView addSubview:_searchBar];
    
    _cancelButton = [[UIButton alloc] init];
    [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[PWColors getColor:PWColorsTypeTintUploadColor] forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[[PWColors getColor:PWColorsTypeTintUploadColor] colorWithAlphaComponent:0.2f]  forState:UIControlStateHighlighted];
    [_searchBarBackgroundView addSubview:_cancelButton];
    
    _backbroundView = [[UIImageView alloc] init];
    _backbroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    _backbroundView.alpha = 0.0;
    _backbroundView.userInteractionEnabled = YES;
    [self.view addSubview:_backbroundView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.scrollsToTop = NO;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    [_tableView registerClass:[PWSearchTableViewWebAlbumCell class] forCellReuseIdentifier:PWSearchNavigationControllerWebAlbumCell];
    [_tableView registerClass:[PWSearchTableViewLocalAlbumCell class] forCellReuseIdentifier:PWSearchNavigationControllerLocalAlbumCell];
    [_backbroundView addSubview:_tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGSize navigationBarSize = self.navigationBar.bounds.size;
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        statusBarSize = CGSizeMake(statusBarSize.height, statusBarSize.width);
    }
    _searchBarBackgroundView.frame = CGRectMake(0.0f, 20.0f - statusBarSize.height, navigationBarSize.width, navigationBarSize.height + statusBarSize.height);
    CGSize cancelButtonSize = [_cancelButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    _searchBar.frame = CGRectMake(0.0f, statusBarSize.height, navigationBarSize.width - (cancelButtonSize.width + 10.0f), navigationBarSize.height);
    _cancelButton.frame = CGRectMake(navigationBarSize.width - (cancelButtonSize.width + 10.0f), statusBarSize.height, cancelButtonSize.width, navigationBarSize.height);
    
    _backbroundView.frame = self.view.bounds;
    _tableView.frame = self.view.bounds;
    
    _tableView.contentInset = UIEdgeInsetsMake(navigationBarSize.height + statusBarSize.height, 0.0f, _tableView.contentInset.bottom, 0.0f);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText) {
        NSLog(@"nil");
    }
    NSLog(@"%@", searchText);
    if (!searchText || [searchText isEqualToString:@""]) {
        _isShowHistory = YES;
        _items = @[];
        [_tableView reloadData];
        
        [self getHistory];
    }
    else {
        if (_isShowHistory) {
            _items = @[];
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
    
    UIImage *backgroundImage = [self.view screenCapture];
    UIColor *tintColor = [UIColor colorWithWhite:0.5 alpha:0.3];
    _backbroundView.image = [backgroundImage applyBlurWithRadius:25 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
    
    [self.view bringSubviewToFront:_backbroundView];
    [self.view bringSubviewToFront:_tableView];
    [self.view bringSubviewToFront:_searchBarBackgroundView];
    [_searchBar becomeFirstResponder];
    if (!_searchBar.text || [_searchBar.text isEqualToString:@""]) {
        _isShowHistory = YES;
        _items = @[];
        [_tableView reloadData];
        
        [self getHistory];
    }
    
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
            
            [webAlbumCell setAlbum:rowItem.item.firstObject isNowLoading:NO];
            
            cell = webAlbumCell;
        }
        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PWSearchTableViewLocalAlbumCell *localAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerLocalAlbumCell forIndexPath:indexPath];
            
            localAlbumCell.album = rowItem.item.firstObject;
            
            cell = localAlbumCell;
        }
        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
            
        }
    }
    else {
        PWSearchNavigationControllerItem *sectionItem = _items[indexPath.section];
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWSearchTableViewWebAlbumCell *webAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerWebAlbumCell forIndexPath:indexPath];
            
            PWAlbumObject *album = sectionItem.item[indexPath.row];
            [webAlbumCell setAlbum:album isNowLoading:NO];
            
            cell = webAlbumCell;
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PWSearchTableViewLocalAlbumCell *localAlbumCell = [tableView dequeueReusableCellWithIdentifier:PWSearchNavigationControllerLocalAlbumCell forIndexPath:indexPath];
            
            PLAlbumObject *album = sectionItem.item[indexPath.row];
            localAlbumCell.album = album;
            
            cell = localAlbumCell;
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
            //        PLPhotoObject *photo = sectionItem.item[indexPath.row];
        }
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_isShowHistory) {
        if (_items.count) {
            return NSLocalizedString(@"履歴", nil);
        }
    }
    else {
        PWSearchNavigationControllerItem *sectionItem = _items[section];
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            return NSLocalizedString(@"ウェブ上のアルバム", nil);
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            return NSLocalizedString(@"カメラロールのアルバム", nil);
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
            return NSLocalizedString(@"カメラロールの写真", nil);
        }
    }
    return nil;
}

- (void)reloadDataWithItems:(NSArray *)items hash:(NSUInteger)hash {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        sself.items = items;
        [sself.tableView reloadData];
        sself.tableView.contentOffset = CGPointMake(0.0f, -sself.tableView.contentInset.top);
    });
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!_isShowHistory) {
        PWSearchNavigationControllerItem *sectionItem = _items[indexPath.section];
        [self addHistory:sectionItem index:indexPath.row];
        
        if (sectionItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWAlbumObject *album = sectionItem.item[indexPath.row];
            
            __weak typeof(self) wself = self;
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PLAlbumObject *album = sectionItem.item[indexPath.row];
            
            __weak typeof(self) wself = self;
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
//        else if (sectionItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
//            
//        }
    }
    else {
        PWSearchNavigationControllerItem *rowItem = _items[indexPath.row];
        
        if (rowItem.type == PWSearchNavigationControllerItemTypeWebAlbum) {
            PWAlbumObject *album = rowItem.item.firstObject;
            
            __weak typeof(self) wself = self;
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PWPhotoListViewController *viewController = [[PWPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
            PLAlbumObject *album = rowItem.item.firstObject;
            
            __weak typeof(self) wself = self;
            [self closeSearchBarWithCompletion:^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PLPhotoListViewController *viewController = [[PLPhotoListViewController alloc] initWithAlbum:album];
                [sself pushViewController:viewController animated:YES];
            }];
        }
//        else if (rowItem.type == PWSearchNavigationControllerItemTypeLocalPhoto) {
//            
//        }
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_searchBar resignFirstResponder];
}

#pragma mark History
- (void)getHistory {
    NSData *historyItemData = [[NSUserDefaults standardUserDefaults] objectForKey:PWSearchNavigationControllerHistoryKey];
    NSMutableArray *historyItems = nil;
    if (historyItemData) {
        historyItems = [NSKeyedUnarchiver unarchiveObjectWithData:historyItemData];
    }
    else {
        historyItems = [NSMutableArray array];
    }
    
    [self reloadTableViewWithHistoryItems:historyItems];
}

- (void)addHistory:(PWSearchNavigationControllerItem *)item index:(NSUInteger)index {
    NSMutableArray *mutableHistoryItems = nil;
    NSData *tmpHistoryItemData = [[NSUserDefaults standardUserDefaults] objectForKey:PWSearchNavigationControllerHistoryKey];
    if (tmpHistoryItemData) {
        NSMutableArray *historyItems = [NSKeyedUnarchiver unarchiveObjectWithData:tmpHistoryItemData];
        mutableHistoryItems = historyItems.mutableCopy;
    }
    if (!mutableHistoryItems) {
        mutableHistoryItems = [NSMutableArray array];
    }
    
    PWSearchNavigationControllerHistoryItem *historyItem = [[PWSearchNavigationControllerHistoryItem alloc] init];
    historyItem.type = item.type;
    historyItem.update = [NSDate date];
    NSString *identifier = nil;
    if (item.type == PWSearchNavigationControllerItemTypeWebAlbum) {
        PWAlbumObject *album = item.item[index];
        identifier = album.id_str;
    }
    else if (item.type == PWSearchNavigationControllerItemTypeLocalAlbum) {
        PLAlbumObject *album = item.item[index];
        identifier = album.id_str;
    }
    historyItem.identifier = identifier;
    
    NSArray *filteredHistoryItems = [mutableHistoryItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]];
    if (filteredHistoryItems.count) {
        [mutableHistoryItems removeObject:filteredHistoryItems.firstObject];
    }
    [mutableHistoryItems insertObject:historyItem atIndex:0];
    if (mutableHistoryItems.count > 10) {
        [mutableHistoryItems removeObject:mutableHistoryItems.lastObject];
    }
    
    NSData *historyItemData = [NSKeyedArchiver archivedDataWithRootObject:mutableHistoryItems.copy];
    [[NSUserDefaults standardUserDefaults] setObject:historyItemData forKey:PWSearchNavigationControllerHistoryKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Model
- (void)localAlbumsSearchByName:(NSString *)name completion:(void (^)(NSArray *albums, NSError *error))completion {
    [PLAssetsManager getAllAlbumsWithCompletion:^(NSArray *allAlbums, NSError *error) {
        NSArray *albums = [allAlbums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[c] %@", name]];
        if (completion) {
            completion(albums, error);
        }
    }];
}

- (void)localAlbumsSearchByID:(NSString *)id_str completion:(void (^)(NSArray *albums, NSError *error))completion {
    [PLAssetsManager getAllAlbumsWithCompletion:^(NSArray *allAlbums, NSError *error) {
        NSArray *albums = [allAlbums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id_str = %@", id_str]];
        if (completion) {
            completion(albums, error);
        }
    }];
}

- (void)localPhotosSearchByName:(NSString *)name completion:(void (^)(NSArray *photos, NSError *error))completion {
    [PLAssetsManager getAllPhotosWithCompletion:^(NSArray *allPhotos, NSError *error) {
        NSArray *photos = [allPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"caption contains[c] %@", name]];
        if (completion) {
            completion(photos, error);
        }
    }];
}

- (void)webAlbumsSearchByName:(NSString *)name completion:(void (^)(NSArray *albums, NSError *error))completion {
    [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        request.predicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", name];
        NSError *error;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (completion) {
            completion(albums, error);
        }
    }];
}

- (void)webAlbumsSearchByID:(NSString *)id_str completion:(void (^)(NSArray *albums, NSError *error))completion {
    [PWCoreDataAPI asyncBlock:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = [NSEntityDescription entityForName:kPWAlbumManagedObjectName inManagedObjectContext:context];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
        request.predicate = [NSPredicate predicateWithFormat:@"id_str = %@", id_str];
        NSError *error;
        NSArray *albums = [context executeFetchRequest:request error:&error];
        if (completion) {
            completion(albums, error);
        }
    }];
}

- (void)reloadTableViewWithSearchText:(NSString *)searchText {
    NSUInteger hash = searchText.hash;
    _searchedTextHash = hash;
    __block NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) wself = self;
    [self webAlbumsSearchByName:searchText completion:^(NSArray *albums, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        if (albums.count) {
            PWSearchNavigationControllerItem *item = [[PWSearchNavigationControllerItem alloc] init];
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
            
            if (albums.count) {
                PWSearchNavigationControllerItem *item = [[PWSearchNavigationControllerItem alloc] init];
                item.type = PWSearchNavigationControllerItemTypeLocalAlbum;
                item.item = albums;
                [items addObject:item];
            }
            
            [sself reloadDataWithItems:items hash:hash];
            
//            [sself localPhotosSearchByName:searchText completion:^(NSArray *photos, NSError *error) {
//                typeof(wself) sself = wself;
//                if (!sself) return;
//                if (sself.searchedTextHash != hash) return;
//                
//                if (photos.count) {
//                    PWSearchNavigationControllerItem *item = [[PWSearchNavigationControllerItem alloc] init];
//                    item.type = PWSearchNavigationControllerItemTypeLocalPhoto;
//                    item.item = photos;
//                    [items addObject:item];
//                }
//                
//                [sself reloadDataWithItems:items hash:hash];
//            }];
        }];
    }];
}

- (void)reloadTableViewWithHistoryItems:(NSArray *)historyItems {
    NSUInteger hash = historyItems.hash;
    _searchedTextHash = hash;
    
    __block NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) wself = self;
    NSArray *webAlbumHistoryItems = [historyItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(PWSearchNavigationControllerItemTypeWebAlbum)]];
    NSArray *localAlbumHistoryItems = [historyItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(PWSearchNavigationControllerItemTypeLocalAlbum)]];
//    NSArray *localPhotoHistoryItems = [historyItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %@", @(PWSearchNavigationControllerItemTypeLocalPhoto)]];
    
    void (^localHistorySearchBlock)(PWSearchNavigationControllerHistoryItem *) = ^(PWSearchNavigationControllerHistoryItem *historyItem) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (sself.searchedTextHash != hash) return;
        
        [sself localAlbumsSearchByID:historyItem.identifier completion:^(NSArray *albums, NSError *error) {
            typeof(wself) sself = wself;
            if (!sself) return;
            if (sself.searchedTextHash != hash) return;
            
            PWSearchNavigationControllerItem *item = [[PWSearchNavigationControllerItem alloc] init];
            item.type = PWSearchNavigationControllerItemTypeLocalAlbum;
            item.item = @[albums.firstObject];
            item.updateUsingByHistorySort = historyItem.update;
            [items addObject:item];
            
            if (items.count == webAlbumHistoryItems.count + localAlbumHistoryItems.count) {
                [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"updateUsingByHistorySort" ascending:NO]]];
                [sself reloadDataWithItems:items hash:hash];
            }
        }];
    };
    
    if (webAlbumHistoryItems.count == 0) {
        for (PWSearchNavigationControllerHistoryItem *historyItem in localAlbumHistoryItems) {
            localHistorySearchBlock(historyItem);
        }
    }
    else {
        for (PWSearchNavigationControllerHistoryItem *historyItem in webAlbumHistoryItems) {
            [self webAlbumsSearchByID:historyItem.identifier completion:^(NSArray *albums, NSError *error) {
                typeof(wself) sself = wself;
                if (!sself) return;
                if (sself.searchedTextHash != hash) return;
                
                PWSearchNavigationControllerItem *item = [[PWSearchNavigationControllerItem alloc] init];
                item.type = PWSearchNavigationControllerItemTypeWebAlbum;
                item.item = @[albums.firstObject];
                item.updateUsingByHistorySort = historyItem.update;
                [items addObject:item];
                
                if (items.count == webAlbumHistoryItems.count) {
                    if (localAlbumHistoryItems.count == 0) {
                        [items sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"updateUsingByHistorySort" ascending:NO]]];
                        [sself reloadDataWithItems:items hash:hash];
                    }
                    else {
                        for (PWSearchNavigationControllerHistoryItem *historyItem in localAlbumHistoryItems) {
                            localHistorySearchBlock(historyItem);
                        }
                    }
                }
            }];
        }
    }
}

@end
