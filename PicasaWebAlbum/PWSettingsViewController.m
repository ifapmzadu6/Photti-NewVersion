//
//  PWSettingsViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSettingsViewController.h"

#import "PWColors.h"

#import "PWSettingsTableViewController.h"

@interface PWSettingsViewController ()

@end

@implementation PWSettingsViewController

- (id)init {
    self = [super init];
    if (self) {
        PWSettingsTableViewController *tableViewController = [[PWSettingsTableViewController alloc] init];
        
        self.viewControllers = @[tableViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
