//
//  PXEditItemsViewController.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PXEditItemsViewController : UIViewController

@property (copy, nonatomic) void (^completionBlock)(NSArray *enabledItems, NSArray *disabledItems);

- (instancetype)initWithEnabledItems:(NSArray *)enabledItems disabledItems:(NSArray *)disabledItems;

@property (strong, nonatomic) NSString *enabledItemsTitle;
@property (strong, nonatomic) NSString *disabledItemsTitle;

@end
