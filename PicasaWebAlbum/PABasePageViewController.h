//
//  PABasePageViewController.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PABasePageViewController : UIPageViewController

@property (strong, nonatomic) NSObject<UINavigationControllerDelegate> *navigationControllerTransition;

@end
