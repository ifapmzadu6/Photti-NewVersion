//
//  PWSettingsViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWSettingsViewController.h"

#import "PAColors.h"

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
        
        BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : NO;
        if (isPhone) {
            self.transitioningDelegate = (id)self;
        }
        else {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_type == PWSettingsViewControllerInitTypeWeb) {
        self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintWebColor];
    }
    else if (_type == PWSettingsViewControllerInitTypeLocal) {
        self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
    }
    else if (_type == PWSettingsViewControllerInitTypeTaskManager) {
        self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintUploadColor];
    }
}

@end
