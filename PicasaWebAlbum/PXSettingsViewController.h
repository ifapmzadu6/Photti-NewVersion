//
//  PWSettingsViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseNavigationController.h"

typedef enum _PWSettingsViewControllerInitType {
    PWSettingsViewControllerInitTypeDefault,
    PWSettingsViewControllerInitTypeLocal,
    PWSettingsViewControllerInitTypeWeb,
    PWSettingsViewControllerInitTypeTaskManager
} PWSettingsViewControllerInitType;

@interface PXSettingsViewController : PABaseNavigationController

- (id)initWithInitType:(PWSettingsViewControllerInitType)type;

@end
