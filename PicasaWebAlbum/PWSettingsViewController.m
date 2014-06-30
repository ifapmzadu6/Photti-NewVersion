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

@property (nonatomic) PWSettingsViewControllerInitType type;

@end

@implementation PWSettingsViewController

- (id)initWithInitType:(PWSettingsViewControllerInitType)type {
    self = [super init];
    if (self) {
        _type = type;
        
        PWSettingsTableViewController *tableViewController = [PWSettingsTableViewController new];
        self.viewControllers = @[tableViewController];
        
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
    
    if (_type == PWSettingsViewControllerInitTypeWeb) {
        self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
    }
    else if (_type == PWSettingsViewControllerInitTypeLocal) {
        self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    }
    else if (_type == PWSettingsViewControllerInitTypeTaskManager) {
        self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
