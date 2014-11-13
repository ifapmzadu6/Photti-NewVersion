//
//  PDNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDNavigationController.h"

#import "PAColors.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PDTaskManagerViewController.h"

@interface PDNavigationController ()

@end

@implementation PDNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", nil);
        
        PDTaskManagerViewController *taskManagerViewController = [PDTaskManagerViewController new];
        [self setViewControllers:@[taskManagerViewController] animated:NO];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundColor];
    self.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintUploadColor];
}

@end
