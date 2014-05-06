//
//  PWTabBarController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWTabBarController.h"

#import "PWLocalViewController.h"
#import "PWAlbumListViewController.h"
#import "PWAutoUploadViewController.h"

@interface PWTabBarController ()

@end

@implementation PWTabBarController

- (id)init {
    self = [super init];
    if (self) {
        PWLocalViewController *localViewController = [[PWLocalViewController alloc] init];
        UINavigationController *localNavigationController = [[UINavigationController alloc] initWithRootViewController:localViewController];
        
        PWAlbumListViewController *albumListViweController = [[PWAlbumListViewController alloc] init];
        UINavigationController *albumNavigationController = [[UINavigationController alloc] initWithRootViewController:albumListViweController];
        
        PWAutoUploadViewController *autoUploadViewController = [[PWAutoUploadViewController alloc] init];
        UINavigationController *autoUploadNavigationController = [[UINavigationController alloc] initWithRootViewController:autoUploadViewController];
        
        self.viewControllers = @[localNavigationController, albumNavigationController, autoUploadNavigationController];
        
        self.selectedIndex = 1;
        
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
