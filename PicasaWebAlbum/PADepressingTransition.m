//
//  PADepressingTransition.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/04.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PADepressingTransition.h"

#import "UIView+ScreenCapture.h"

static CGFloat kPADepressingTransitionDuration = 0.5f;
static CGFloat kPADepressingTransitionDepressedFrameRate = 0.9f;

@interface PADepressingTransition ()

@property (strong, nonatomic) UIImageView *depressingImageView;

@end

@implementation PADepressingTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return kPADepressingTransitionDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.presenting) {
        [self dismissTransitionWithTransitionContext:transitionContext];
    }
    else {
        [self presentTransitionWithTransitionContext:transitionContext];
    }
}

- (void)presentTransitionWithTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = fromViewController.view;
    
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = toViewController.view;
    
    UIView *containerView = transitionContext.containerView;
    containerView.backgroundColor = [UIColor blackColor];
    
    UIImageView *fromImageView = [[UIImageView alloc] initWithFrame:fromView.frame];
    fromImageView.image = fromView.screenCapture;
    
    self.depressingImageView = fromImageView;
    
    [fromView removeFromSuperview];
    
    [containerView addSubview:toView];
    toView.frame = CGRectMake(CGRectGetMinX(toView.frame), CGRectGetHeight(toView.frame), CGRectGetWidth(toView.frame), CGRectGetHeight(toView.frame));
    
    [containerView insertSubview:fromImageView belowSubview:toView];
    
    UIView *filteringView = [[UIView alloc] initWithFrame:fromImageView.frame];
    filteringView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    filteringView.alpha = 0.f;
    [containerView insertSubview:filteringView aboveSubview:fromImageView];
    
    CGRect animatedFrame = [self depressedFrameWithContainerView:containerView];
    [UIView animateKeyframesWithDuration:kPADepressingTransitionDuration delay:0.0 options:(7 << 16) animations:^{
        fromImageView.frame = animatedFrame;
        filteringView.frame = animatedFrame;
        filteringView.alpha = 1.f;
        toView.frame = CGRectMake(CGRectGetMinX(toView.frame), 0.0f, CGRectGetWidth(toView.frame), CGRectGetHeight(toView.frame));
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        _presenting = YES;
    }];
}

- (void)dismissTransitionWithTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = fromVC.view;
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = toVC.view;
    
    UIView *containerView = transitionContext.containerView;
    containerView.backgroundColor = [UIColor blackColor];
    
    [toView removeFromSuperview];
    
    [containerView addSubview:fromView];
    
    UIImageView *toImageView = self.depressingImageView;
    toImageView.frame = [self depressedFrameWithContainerView:containerView];
    [containerView insertSubview:toImageView belowSubview:fromView];
    
    UIView *filteringView = [[UIView alloc] initWithFrame:toImageView.frame];
    filteringView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    filteringView.alpha = 1.f;
    [containerView insertSubview:filteringView aboveSubview:toImageView];
    
    [UIView animateKeyframesWithDuration:kPADepressingTransitionDuration delay:0.0 options:(7 << 16) animations:^{
        toImageView.frame = containerView.bounds;
        filteringView.frame = containerView.bounds;
        filteringView.alpha = 0.f;
        fromView.frame = CGRectMake(CGRectGetMinX(toView.frame), CGRectGetHeight(toView.frame), CGRectGetWidth(toView.frame), CGRectGetHeight(toView.frame));
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        _presenting = NO;
    }];
}

- (CGRect)depressedFrameWithContainerView:(UIView *)containerView {
    CGFloat width = CGRectGetWidth(containerView.frame) * kPADepressingTransitionDepressedFrameRate;
    CGFloat height = CGRectGetHeight(containerView.frame) * kPADepressingTransitionDepressedFrameRate;
    CGFloat x = (CGRectGetWidth(containerView.frame) - width) / 2.f;
    CGFloat y = (CGRectGetHeight(containerView.frame) - height) / 2.f;
    return CGRectMake(x, y, width, height);
}

@end
