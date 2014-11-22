//
//  PABasePageViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABasePageViewController.h"

@implementation PABasePageViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.delegate = _navigationControllerTransition;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.delegate = nil;
}

@end
