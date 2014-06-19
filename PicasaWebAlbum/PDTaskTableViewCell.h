//
//  PDTaskTableViewCell.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PDBaseTaskObject;

@interface PDTaskTableViewCell : UITableViewCell

@property (strong, nonatomic) PDBaseTaskObject *taskObject;
@property (nonatomic) BOOL isNowLoading;

+ (CGFloat)cellHeightForTaskObject:(PDBaseTaskObject *)taskObject;

@end
