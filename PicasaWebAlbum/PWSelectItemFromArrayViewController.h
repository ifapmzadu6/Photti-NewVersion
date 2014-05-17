//
//  PWSelectItemFromArrayViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PWSelectItemFromArrayViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) void (^doneBlock)(NSString *selectedItem);
@property (strong, nonatomic) void (^changeValueBlock)(NSString *selectedItem);
@property (nonatomic) NSUInteger disableIndex;

- (id)initWithItems:(NSArray *)items defaultIndex:(NSUInteger)defaultIndex;

@end
