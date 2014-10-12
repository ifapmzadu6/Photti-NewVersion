//
//  PWNewAlbumEditViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWNewAlbumEditViewController.h"

#import "PAColors.h"
#import "PWDatePickerView.h"
#import "PADateTimestamp.h"
#import "PWPicasaAPI.h"
#import "PAActivityIndicatorView.h"
#import <Reachability.h>

#import "PXSelectItemFromArrayViewController.h"

@interface PWNewAlbumEditViewController () <UITextFieldDelegate>

@end

@implementation PWNewAlbumEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"New Album", nil);
    
    self.timestamp = [PADateTimestamp timestampForDate:[NSDate date]];
    
    UIBarButtonItem *createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(createBarButtonAction)];
    [createBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

#pragma mark UITableViewCellOption
- (UITextField *)makeTextField:(CGSize)textSize {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width - textSize.width - 60.0f, 20.0f)];
    textField.delegate = self;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.font = [UIFont systemFontOfSize:15.0f];
    textField.placeholder = NSLocalizedString(@"New Album", nil);
    textField.returnKeyType = UIReturnKeyDone;
    
    self.textField = textField;
    
    return textField;
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark UIBarButtonItem
- (void)createBarButtonAction {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not connected to network", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        });
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Saving...", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    PAActivityIndicatorView *indicator = [PAActivityIndicatorView new];
    indicator.center = CGPointMake((self.view.bounds.size.width / 2) - 20, (self.view.bounds.size.height / 2) - 130);
    [indicator startAnimating];
    [alertView setValue:indicator forKey:@"accessoryView"];
    [alertView show];
    
    NSString *albumTitle = nil;
    UITextField *textField = self.textField;
    if (textField) {
        if (![textField.text isEqualToString:@""]) {
            albumTitle = textField.text;
        }
    }
    if (!albumTitle) {
        albumTitle = NSLocalizedString(@"New Album", nil);
    }
    
    __weak typeof(self) wself = self;
    [PWPicasaAPI postCreatingNewAlbumRequestWithTitle:albumTitle
                                              summary:nil
                                             location:nil
                                               access:kPWPicasaAPIGphotoAccessProtected
                                            timestamp:self.timestamp
                                             keywords:nil
                                           completion:^(PWAlbumObject *album, NSError *error) {
                                               if (error) {
#ifdef DEBUG
                                                   NSLog(@"%@", error);
#endif
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                                   });
                                                   return;
                                               }
                                               
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [alertView dismissWithClickedButtonIndex:0 animated:YES];
                                                   
                                                   typeof(wself) sself = wself;
                                                   if (!sself) return;
                                                   [sself dismissViewControllerAnimated:YES completion:nil];
                                                   if (sself.successBlock) {
                                                       sself.successBlock();
                                                   }
                                               });
                                           }];
}

@end
