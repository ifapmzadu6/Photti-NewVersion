//
//  ShareViewController.m
//  PhottiShareExtention
//
//  Created by Keisuke Karijuku on 2014/11/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "ShareViewController.h"

#import "SEImageViewController.h"


static CGFloat kPageViewControllerOptionInterPageSpacingValue = 20.0f;


@interface ShareViewController () <UIPageViewControllerDataSource>

@property (weak, nonatomic) IBOutlet UIVisualEffectView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *staticAlbumLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *pageBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *pageLabel;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) NSInteger index;

@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _contentView.layer.cornerRadius = 10.0f;
    _contentView.layer.masksToBounds = YES;
    _pageBackgroundView.layer.cornerRadius = 5.0f;
    _pageBackgroundView.layer.masksToBounds = YES;
    
    _staticAlbumLabel.text = NSLocalizedString(@"Album to save", nil);
    
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:@(kPageViewControllerOptionInterPageSpacingValue), UIPageViewControllerOptionInterPageSpacingKey, nil];
    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
    pageViewController.dataSource = self;
    [pageViewController setViewControllers:@[[self viewControlelrForIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [_contentView.contentView insertSubview:pageViewController.view atIndex:0];
    _pageViewController = pageViewController;
    
    _albumTitleLabel.text = NSLocalizedString(@"ほいほい", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = _contentView.bounds;
    
    _pageViewController.view.frame = CGRectMake(0.0f, 44.0f, CGRectGetWidth(rect), CGRectGetHeight(rect)-44.0f*2.0f);
}

#pragma mark UIBarButtonAction
- (IBAction)cancelBarButtonAction:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.extensionContext cancelRequestWithError:nil];
    }];
}

- (IBAction)saveBarButtonAction:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
}

#pragma mark UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    SEImageViewController *imageViewController = (SEImageViewController *)viewController;
    NSInteger index = imageViewController.index;
    if (index == 0) {
        return nil;
    }
    return [self viewControlelrForIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    SEImageViewController *imageViewController = (SEImageViewController *)viewController;
    NSInteger index = imageViewController.index;
    NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
    if (index == inputItem.attachments.count-1) {
        return nil;
    }
    return [self viewControlelrForIndex:index + 1];
}

- (UIViewController *)viewControlelrForIndex:(NSInteger)index {
    NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
    id item = inputItem.attachments[index];
    NSInteger numberObItems = inputItem.attachments.count;
    
    SEImageViewController *viewController = [[SEImageViewController alloc] initWithIndex:index item:item];
    __weak typeof(self) wself = self;
    viewController.viewDidAppearBlock = ^() {
        typeof(wself) sself = wself;
        if (!sself) return;
        sself.index = index;
        sself.pageLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)sself.index + 1, (long)numberObItems];
    };
    return viewController;
}

@end
