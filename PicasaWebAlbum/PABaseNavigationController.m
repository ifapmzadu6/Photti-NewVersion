//
//  PWBaseNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseNavigationController.h"

#import "PAColors.h"
#import "PADepressingTransition.h"

@interface PABaseNavigationController () <UINavigationControllerDelegate>

@property (strong, nonatomic) PADepressingTransition *transition;

@end

@implementation PABaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:PAColorsTypeTextColor]};
    
    self.delegate = self;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.transition = [PADepressingTransition new];
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.transition;
}

@end
