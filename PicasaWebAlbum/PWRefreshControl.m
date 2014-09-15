//
//  PWRefreshControl.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/10.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWRefreshControl.h"

@interface PWRefreshControl ()

@property (nonatomic) CGFloat topContentInset;
@property (nonatomic) CGFloat leftContentInset;
@property (nonatomic) BOOL contentInsetSaved;

@end

@implementation PWRefreshControl

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // getting containing scrollView
    UIScrollView *scrollView = (UIScrollView *)self.superview;
    
    // saving present top contentInset, because it can be changed by refresh control
    if (!_contentInsetSaved) {
        _topContentInset = scrollView.contentInset.top;
        _leftContentInset = scrollView.contentInset.left;
        _contentInsetSaved = YES;
    }
    
    // saving own frame, that will be modified
    CGRect newFrame = self.bounds;
    
    // if refresh control is fully or partially behind UINavigationBar
    if (scrollView.contentOffset.y + _topContentInset > -newFrame.size.height) {
        // moving it with the rest of the content
        newFrame.origin.y = -newFrame.size.height - _myContentInsetTop;
        
        // if refresh control fully appeared
    } else {
        // keeping it at the same place
        newFrame.origin.y = scrollView.contentOffset.y + _topContentInset - _myContentInsetTop/2.0f;
    }
    
    // applying new frame to the refresh control
    self.frame = newFrame;
    
    self.center = CGPointMake(scrollView.center.x - _leftContentInset, self.center.y);
}

- (void)beginRefreshing {
    // Only do this specific "hack" if super view is a collection view
    if ([[self superview] isKindOfClass:[UICollectionView class]]) {
        UICollectionView *superCollectionView = (UICollectionView *)[self superview];
        
        // If the user did change the content offset we do not want to animate a new one
        if (CGPointEqualToPoint([superCollectionView contentOffset], CGPointZero)) {
            
            // Set the new content offset based on UIRefreshControl height
            [superCollectionView setContentOffset:CGPointMake(0, -CGRectGetHeight([self frame])) animated:YES];
            
            // Call super after the animation is finished, all apple animations is .3 sec
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (0.3 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [super beginRefreshing];
            });
        } else {
            [super beginRefreshing];
        }
    } else {
        [super beginRefreshing];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
#ifdef DEBUG
    NSLog(@"Warning: setting background color on a UIRefreshControl is causing unexpected behavior");
#endif
}

@end
