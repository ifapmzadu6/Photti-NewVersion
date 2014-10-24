//
//  PWSettingsViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseNavigationController.h"

typedef NS_ENUM(NSUInteger, PWSettingsViewControllerInitType) {
    PWSettingsViewControllerInitTypeDefault,
    PWSettingsViewControllerInitTypeLocal,
    PWSettingsViewControllerInitTypeWeb,
    PWSettingsViewControllerInitTypeTaskManager
};

@interface PXSettingsViewController : PABaseNavigationController

- (id)initWithInitType:(PWSettingsViewControllerInitType)type;

@end
