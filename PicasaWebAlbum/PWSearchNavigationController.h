//
//  PWSearchNavigationController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PWNavigationController.h"

@interface PWSearchNavigationController : PWNavigationController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

- (void)openSearchBarWithPredicate:(NSArray * (^)(NSString *word))predicate completion:(UIViewController * (^)(NSString *searchText))completion;
- (void)closeSearchBarWithCompletion:(void (^)())completion;

@end
