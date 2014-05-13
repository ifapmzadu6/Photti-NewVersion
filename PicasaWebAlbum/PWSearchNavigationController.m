//
//  PWSearchNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSearchNavigationController.h"

#import "PWColors.h"

#import "UIView+ScreenCapture.h"
#import "UIImage+ImageEffects.h"

@interface PWSearchNavigationController ()

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *searchBarBackgroundView;
@property (strong, nonatomic) UIImageView *backbroundView;
@property (strong, nonatomic) UITableView *tableView;

@property (nonatomic) BOOL isSearchBarOpen;
@property (nonatomic) BOOL isAnimation;
@property (strong, nonatomic) NSArray *predicates;
@property (strong, nonatomic) NSArray *(^predicate)(NSString *);
@property (strong, nonatomic) UIViewController *(^completion)(NSString *);

@end

@implementation PWSearchNavigationController

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    _searchBarBackgroundView = [[UIView alloc] init];
    _searchBarBackgroundView.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    _searchBarBackgroundView.alpha = 0.0f;
    [self.view addSubview:_searchBarBackgroundView];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = YES;
    _searchBar.placeholder = NSLocalizedString(@"Search", nil);
    [_searchBarBackgroundView addSubview:_searchBar];
    
    _backbroundView = [[UIImageView alloc] init];
    _backbroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
    _backbroundView.alpha = 0.0;
    _backbroundView.userInteractionEnabled = YES;
    [self.view addSubview:_backbroundView];
    
    _tableView = [[UITableView alloc] init];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.scrollsToTop = NO;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    _tableView.backgroundColor = [UIColor clearColor];
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
    _searchBar.frame = CGRectMake(0.0f, statusBarSize.height, navigationBarSize.width, navigationBarSize.height);
    
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark Notification
- (void)keyboardWillShow:(NSNotification *)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        keyboardRect = CGRectMake(0.0f, 0.0f, keyboardRect.size.height, keyboardRect.size.width);
    }
    _tableView.contentInset = UIEdgeInsetsMake(_tableView.contentInset.top, 0.0f, keyboardRect.size.height, 0.0f);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
}

- (void)keyBoardWillChange:(NSNotification *)notification {
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        keyboardRect = CGRectMake(0.0f, 0.0f, keyboardRect.size.height, keyboardRect.size.width);
    }
    _tableView.contentInset = UIEdgeInsetsMake(_tableView.contentInset.top, 0.0f, keyboardRect.size.height, 0.0f);
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
}

#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    _predicates = _predicate(searchText);
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (_completion) {
        NSString *searchText = searchBar.text;
        UIViewController *viewController = _completion(searchText);
        
        __weak typeof(self) wself = self;
        [self closeSearchBarWithCompletion:^{
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself pushViewController:viewController animated:YES];
        }];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self closeSearchBarWithCompletion:nil];
}

#pragma mark OpenSearchBar
- (void)openSearchBarWithPredicate:(NSArray *(^)(NSString *))predicate completion:(UIViewController *(^)(NSString *))completion {
    if (_isSearchBarOpen || _isAnimation) return;
    _isSearchBarOpen = YES;
    _isAnimation = YES;
    
    _predicate = predicate;
    _completion = completion;
    
    UIImage *backgroundImage = [self.view screenCapture];
    _backbroundView.image = [backgroundImage applyLightEffect];
    
    [self.view bringSubviewToFront:_backbroundView];
    [self.view bringSubviewToFront:_tableView];
    [self.view bringSubviewToFront:_searchBarBackgroundView];
    [_searchBar becomeFirstResponder];
    
    [UIView animateWithDuration:0.3f delay:0.0f options:(7 << 16) animations:^{
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
    
    [_searchBar resignFirstResponder];
    
    [UIView animateWithDuration:0.3f delay:0.0f options:(7 << 16) animations:^{
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _predicates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = _predicates[indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

@end
