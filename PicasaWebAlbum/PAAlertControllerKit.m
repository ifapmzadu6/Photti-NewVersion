//
//  PAAlertControllerKit.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAAlertControllerKit.h"

#import "PAActivityIndicatorView.h"


@implementation PAAlertControllerKit

+ (void)showNotCollectedToNetwork {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showNotCollectedToNetwork];
        });
        return;
    }
    
    NSString *title = NSLocalizedString(@"Not connected to network", nil);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
    });
}

+ (void)showNotPermittedToPhotoLibrary {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showNotPermittedToPhotoLibrary];
        });
        return;
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Go to Settings > Privacy > Photos and switch Photti to ON to access Photo Library.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
}

+ (void)showYouNeedToLoginWebAlbum {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showYouNeedToLoginWebAlbum];
        });
        return;
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You need to login Web Album.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
}

+ (void)showDontRemoveThoseItemsUntilTheTaskIsFinished {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showDontRemoveThoseItemsUntilTheTaskIsFinished];
        });
        return;
    }
    
    NSString *title = NSLocalizedString(@"A new task has been added.", nil);
    NSString *message = NSLocalizedString(@"Don't remove those items until the task is finished.", nil);
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
}

+ (void)attachActivityIndicatorView:(UIAlertView *)alertView {
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        return;
    }
    
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat screenWidth = MIN(screenSize.width, screenSize.height);
    CGFloat screenHeight = MAX(screenSize.width, screenSize.height);
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    indicator.center = CGPointMake((screenWidth / 2.0f) - 20.0f, (screenHeight / 2.0f) - 130.0f);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
}


@end
