//
//  ShareViewController.m
//  PhottiShareExtention
//
//  Created by Keisuke Karijuku on 2014/11/03.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *staticAlbumLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumTitleLabel;

@end

@implementation ShareViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _contentView.layer.cornerRadius = 10.0f;
    _contentView.layer.masksToBounds = YES;
    
    _staticAlbumLabel.text = NSLocalizedString(@"Album", nil);
    
    _albumTitleLabel.text = NSLocalizedString(@"ほいほい", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark UIBarButtonAction
- (IBAction)cancelBarButtonAction:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
}

- (IBAction)saveBarButtonAction:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
}



@end
