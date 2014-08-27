//
//  PABaseViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/27.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseViewController.h"

@interface PABaseViewController ()

@end

@implementation PABaseViewController

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.screenName = NSStringFromClass([self class]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
