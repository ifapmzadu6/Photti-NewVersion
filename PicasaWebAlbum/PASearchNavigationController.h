//
//  PWSearchNavigationController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseNavigationController.h"

@interface PASearchNavigationController : PABaseNavigationController 

- (void)openSearchBarWithCancelBlock:(void (^)())cancelBlock;
- (void)closeSearchBarWithCompletion:(void (^)())completion;

@end
