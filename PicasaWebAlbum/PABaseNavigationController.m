//
//  PWBaseNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PABaseNavigationController.h"

#import "PAColors.h"

@interface PABaseNavigationController () <UINavigationControllerDelegate>

@end

@implementation PABaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PAColors getColor:PWColorsTypeTintWebColor];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PAColors getColor:PWColorsTypeTextColor]};
    
    self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end
