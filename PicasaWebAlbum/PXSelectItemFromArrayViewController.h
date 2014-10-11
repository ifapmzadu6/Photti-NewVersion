//
//  PWSelectItemFromArrayViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@interface PXSelectItemFromArrayViewController : PABaseViewController

@property (copy, nonatomic) void (^doneBlock)(NSString *selectedItem);
@property (copy, nonatomic) void (^changeValueBlock)(NSString *selectedItem);
@property (nonatomic) NSUInteger disableIndex;
@property (strong, nonatomic) NSString *footerString;

- (id)initWithItems:(NSArray *)items defaultIndex:(NSUInteger)defaultIndex;

@end
