//
//  PWBaseNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWBaseNavigationController.h"

#import "PWColors.h"

@interface PWBaseNavigationController () <UINavigationControllerDelegate>

@end

@implementation PWBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
    
    self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

//- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
//    UIViewController *presentViewController = self.viewControllers.lastObject;
//    
//    [super pushViewController:viewController animated:animated];
//    
//    UIView *blackView = [UIView new];
//    blackView.tag = 9999;
//    blackView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
//    blackView.frame = presentViewController.view.frame;
//    blackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    blackView.alpha = 0.0f;
//    [presentViewController.view addSubview:blackView];
//    
//    [UIView animateWithDuration:0.3f animations:^{
//        blackView.alpha = 0.4f;
//    }];
//}
//
//- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
//    UIViewController *viewController = self.viewControllers[self.viewControllers.count-2];
//    UIView *blackView = [viewController.view viewWithTag:9999];
//    if (!blackView) {
//        blackView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
//        blackView.frame = viewController.view.frame;
//        blackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        blackView.alpha = 0.4f;
//        [viewController.view addSubview:blackView];
//    }
//    
//    [super popViewControllerAnimated:animated];
//    
//    if (blackView) {
//        [UIView animateWithDuration:0.3f animations:^{
//            blackView.alpha = 0.0f;
//        } completion:^(BOOL finished) {
//            [blackView removeFromSuperview];
//        }];
//    }
//    
//    return viewController;
//}

@end
